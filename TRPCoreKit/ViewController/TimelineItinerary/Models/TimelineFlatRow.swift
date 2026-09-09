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

/// The routable rows of one flat section in list order. `key` identifies the chain by its
/// waypoints and coordinates, so rows that only changed time reuse the legs already calculated.
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

    init(cityId: Int?, rows: [TimelineFlatRow]) {
        self.cityId = cityId
        let waypoints = rows.compactMap { $0.routeWaypoint }
        self.waypointKeys = waypoints.map { $0.key }
        self.locations = waypoints.map { $0.coordinate }
    }
}
