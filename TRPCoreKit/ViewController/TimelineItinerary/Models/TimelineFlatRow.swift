//
//  TimelineFlatRow.swift
//  TRPCoreKit
//

import Foundation
import TRPFoundationKit

/// One row of the flat timeline: a city section lists its flexible activities, the
/// starting point, then every timed row in start-time order with route separators
/// between consecutive located rows.
enum TimelineFlatRow {
    case flexibleActivity(TRPMergedTimelineItem)
    case startingPoint(name: String, coordinate: TRPLocation?, item: TRPMergedTimelineItem)
    case routeSeparator(TRPStepRouteInfo, destinationKey: String)
    case bookedActivity(TRPMergedTimelineItem, order: Int)
    case manualPoi(TRPMergedTimelineItem, order: Int)
    case planStep(TRPMergedTimelineItem, stepIndex: Int, order: Int)

    var item: TRPMergedTimelineItem? {
        switch self {
        case .flexibleActivity(let item): return item
        case .startingPoint(_, _, let item): return item
        case .routeSeparator: return nil
        case .bookedActivity(let item, _): return item
        case .manualPoi(let item, _): return item
        case .planStep(let item, _, _): return item
        }
    }

    var step: TRPTimelineStep? {
        guard case .planStep(let item, let stepIndex, _) = self,
              let plan = item.plan, stepIndex < plan.steps.count else { return nil }
        return plan.steps[stepIndex]
    }

    /// Waypoint this row contributes to its section's route chain, or nil when it is not routed.
    /// Keys: "start" for the starting point, "s{stepId}" for steps, "g{segmentIndex}" for activity segments.
    var routeWaypoint: (key: String, coordinate: TRPLocation)? {
        switch self {
        case .flexibleActivity, .routeSeparator:
            return nil

        case .startingPoint(_, let coordinate, _):
            guard let coordinate = coordinate, !coordinate.isMissingOrZero else { return nil }
            return ("start", coordinate)

        case .bookedActivity(let item, _):
            guard !item.isNoLocation, let coordinate = item.coordinate, !coordinate.isMissingOrZero else { return nil }
            return ("g\(item.originalSegmentIndex)", coordinate)

        case .manualPoi(let item, _):
            guard !item.isNoLocation, let coordinate = item.manualPoi?.coordinate, !coordinate.isMissingOrZero else { return nil }
            return ("s\(item.plan?.steps.first?.id ?? item.originalSegmentIndex)", coordinate)

        case .planStep:
            guard let step = step, let coordinate = step.poi?.coordinate, !coordinate.isMissingOrZero else { return nil }
            return ("s\(step.id)", coordinate)
        }
    }
}

/// A city section of the flat timeline.
struct TimelineFlatSection {
    let city: TRPCity?
    let items: [TRPMergedTimelineItem]
    var rows: [TimelineFlatRow]
}

/// One run of routable rows of a flat section, in list order. A timed row without a location
/// ends the run: the rows before it and the rows after it are routed as separate chains, so no
/// leg is drawn across a place that cannot be placed. The starting point belongs to the first
/// run that has a located row. `key` identifies the chain by its waypoints and coordinates, so
/// rows that only changed time reuse the legs already calculated.
struct TimelineFlatRouteChain {
    let cityId: Int?
    let waypointKeys: [String]
    let locations: [TRPLocation]

    var key: String {
        let parts = zip(waypointKeys, locations).map { key, location in
            String(format: "%@@%.5f,%.5f", key, location.lat, location.lon)
        }
        return "\(cityId ?? 0)|" + parts.joined(separator: ">")
    }

    var isRoutable: Bool { locations.count > 1 }

    var startsAtStartingPoint: Bool { waypointKeys.first == "start" }

    /// Key of the row leg `index` arrives at (`locations[index]` → `locations[index + 1]`).
    func destinationKey(ofLeg index: Int) -> String? {
        let destination = index + 1
        return destination < waypointKeys.count ? waypointKeys[destination] : nil
    }

    private init(cityId: Int?, waypoints: [(key: String, coordinate: TRPLocation)]) {
        self.cityId = cityId
        self.waypointKeys = waypoints.map { $0.key }
        self.locations = waypoints.map { $0.coordinate }
    }

    /// The chains of one section: rows are split into runs at each timed row without a
    /// location; runs with fewer than two waypoints are dropped.
    static func chains(cityId: Int?, rows: [TimelineFlatRow]) -> [TimelineFlatRouteChain] {
        var chains: [TimelineFlatRouteChain] = []
        var run: [(key: String, coordinate: TRPLocation)] = []

        func closeRun() {
            if run.count > 1 { chains.append(TimelineFlatRouteChain(cityId: cityId, waypoints: run)) }
            run = []
        }

        for row in rows {
            if let waypoint = row.routeWaypoint {
                run.append(waypoint)
            } else if row.breaksRouteChain, run.contains(where: { $0.key != "start" }) {
                closeRun()
            }
        }
        closeRun()
        return chains
    }
}

extension TimelineFlatRow {

    /// A timed row that has no coordinate to route through, so legs must not cross it.
    var breaksRouteChain: Bool {
        switch self {
        case .bookedActivity, .manualPoi, .planStep: return true
        case .flexibleActivity, .startingPoint, .routeSeparator: return false
        }
    }
}
