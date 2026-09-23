//
//  TRPTimelineItineraryViewModel+FlatTimeline.swift
//  TRPCoreKit
//

import Foundation
import TRPFoundationKit

// MARK: - Flat Timeline

extension TRPTimelineItineraryViewModel {

    /// Lays the selected day's city groups out as flat rows: flexible activities first, then the
    /// starting point, then every timed row by start time (ties: booked → reserved → POI; rows
    /// without a time last) numbered sequentially across cities, with the cached route legs
    /// interleaved as separators. Groups that yield no rows are dropped.
    internal func buildFlatSections() {
        var currentOrder = 1
        var sections: [TimelineFlatSection] = []

        for group in displayItems {
            var rows: [TimelineFlatRow] = []
            rows.append(contentsOf: group.items.filter { $0.isFlexibleActivity }.map { .flexibleActivity($0) })

            if let planItem = group.items.first(where: { planHasFlatRows($0) }),
               let startingPoint = startingPointRow(for: planItem, city: group.city) {
                rows.append(startingPoint)
            }

            for entry in timedEntries(for: group.items).sorted(by: flatEntryPrecedes) {
                rows.append(entry.row(order: currentOrder))
                currentOrder += 1
            }

            guard !rows.isEmpty else { continue }
            let chains = TimelineFlatRouteChain.chains(cityId: group.city?.id, rows: rows)
            sections.append(TimelineFlatSection(city: group.city, items: group.items, rows: interleaveRouteSeparators(rows, chains: chains)))
        }

        flatSections = sections
    }

    internal func flatRow(at indexPath: IndexPath) -> TimelineFlatRow? {
        guard indexPath.section < flatSections.count else { return nil }
        let rows = flatSections[indexPath.section].rows
        guard indexPath.row < rows.count else { return nil }
        return rows[indexPath.row]
    }

    /// Ordered map items in flat row order, so marker numbers match the list.
    internal func flatOrderedItemsForMap() -> [(order: Int, section: Int, cityIndex: Int, item: MapDisplayItem)] {
        var result: [(order: Int, section: Int, cityIndex: Int, item: MapDisplayItem)] = []

        for (sectionIndex, section) in flatSections.enumerated() {
            for row in section.rows {
                switch row {
                case .flexibleActivity(let item):
                    result.append((order: 0, section: sectionIndex, cityIndex: sectionIndex, item: .activity(item.segment)))

                case .bookedActivity(let item, let order):
                    result.append((order: order, section: sectionIndex, cityIndex: sectionIndex, item: .activity(item.segment)))

                case .manualPoi(let item, let order):
                    if let poi = item.manualPoi {
                        result.append((order: order, section: sectionIndex, cityIndex: sectionIndex, item: .poi(poi, item.segment, nil)))
                    }

                case .planStep(let item, _, let order):
                    if let step = row.step, let poi = step.poi {
                        result.append((order: order, section: sectionIndex, cityIndex: sectionIndex, item: .poi(poi, item.segment, step)))
                    }

                case .startingPoint, .routeSeparator:
                    break
                }
            }
        }

        return result
    }

    // MARK: Routes

    internal func flatRouteChains() -> [TimelineFlatRouteChain] {
        return flatSections.flatMap { TimelineFlatRouteChain.chains(cityId: $0.city?.id, rows: $0.rows) }
    }

    /// Requests legs for every chain of the day with no cached result and no request in flight.
    /// Each arrival is cached under the chain key, the rows are rebuilt and `onUpdate` fires on
    /// the main thread. A chain whose rows only changed time keeps its key, so nothing is repeated.
    internal func requestMissingFlatRoutes(onUpdate: @escaping () -> Void) {
        for chain in flatRouteChains() {
            let key = chain.key
            guard flatRouteCache[key] == nil, !flatRouteRequestsInFlight.contains(key) else { continue }
            flatRouteRequestsInFlight.insert(key)

            calculateStepRoutes(for: chain.locations) { [weak self] legs in
                guard let self = self else { return }
                self.flatRouteRequestsInFlight.remove(key)
                guard let legs = legs else { return }
                self.flatRouteCache[key] = legs
                self.buildFlatSections()
                onUpdate()
            }
        }
    }

    /// Cached legs of the day's chains for the map, one entry per chain. The starting point has no
    /// marker, so its leg stays in the list only.
    internal func flatMapRouteLegs() -> [(segmentId: String, legs: [TRPMapRouteLeg])] {
        return flatRouteChains().enumerated().compactMap { index, chain in
            guard var legs = flatRouteCache[chain.key] else { return nil }
            if chain.startsAtStartingPoint, !legs.isEmpty {
                legs.removeFirst()
            }
            guard !legs.isEmpty else { return nil }
            let mapLegs = legs.map { TRPMapRouteLeg(coordinates: $0.shape, isWalking: $0.isWalking) }
            return (segmentId: "timeline_flat_route_\(index)", legs: mapLegs)
        }
    }

    private func interleaveRouteSeparators(_ rows: [TimelineFlatRow], chains: [TimelineFlatRouteChain]) -> [TimelineFlatRow] {
        var legByDestination: [String: TRPStepRouteInfo] = [:]
        for chain in chains {
            guard let legs = flatRouteCache[chain.key] else { continue }
            for (index, leg) in legs.enumerated() {
                if let destinationKey = chain.destinationKey(ofLeg: index) {
                    legByDestination[destinationKey] = leg
                }
            }
        }
        guard !legByDestination.isEmpty else { return rows }

        var result: [TimelineFlatRow] = []
        for row in rows {
            if let waypoint = row.routeWaypoint, let leg = legByDestination[waypoint.key] {
                result.append(.routeSeparator(leg, destinationKey: waypoint.key))
            }
            result.append(row)
        }
        return result
    }

    // MARK: Generation outcome

    /// Alerts once per plan when generation finished without finding any place for the
    /// selected day; the list simply has no rows for that plan.
    internal func reportPlansGeneratedWithoutPois() {
        let emptyPlans = displayItems
            .flatMap { $0.items }
            .compactMap { item -> TRPTimelinePlan? in
                guard item.isItinerary, let plan = item.plan else { return nil }
                return plan.generatedStatus == -1 && plan.steps.isEmpty ? plan : nil
            }
            .filter { !reportedEmptyPlanIds.contains($0.id) }

        guard let plan = emptyPlans.first else { return }
        reportedEmptyPlanIds.insert(plan.id)

        let message = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.noRecommendations)
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.viewModel(showMessage: message, type: .error)
        }
    }

    // MARK: Row building helpers

    private struct FlatTimedEntry {
        let item: TRPMergedTimelineItem
        let stepIndex: Int?
        let startDate: Date?
        let typeRank: Int
        let sourceIndex: Int

        func row(order: Int) -> TimelineFlatRow {
            if let stepIndex = stepIndex {
                return .planStep(item, stepIndex: stepIndex, order: order)
            }
            return item.isManualPoi ? .manualPoi(item, order: order) : .bookedActivity(item, order: order)
        }
    }

    private func flatEntryPrecedes(_ lhs: FlatTimedEntry, _ rhs: FlatTimedEntry) -> Bool {
        let lhsDate = lhs.startDate ?? Date.distantFuture
        let rhsDate = rhs.startDate ?? Date.distantFuture
        if lhsDate != rhsDate { return lhsDate < rhsDate }
        if lhs.typeRank != rhs.typeRank { return lhs.typeRank < rhs.typeRank }
        return lhs.sourceIndex < rhs.sourceIndex
    }

    private func planHasFlatRows(_ item: TRPMergedTimelineItem) -> Bool {
        guard item.isItinerary, let plan = item.plan else { return false }
        return plan.generatedStatus != 0 && !plan.steps.isEmpty
    }

    private func timedEntries(for items: [TRPMergedTimelineItem]) -> [FlatTimedEntry] {
        var entries: [FlatTimedEntry] = []

        for item in items {
            switch item.segmentType {
            case .bookedActivity:
                entries.append(FlatTimedEntry(item: item, stepIndex: nil, startDate: item.startDate, typeRank: 0, sourceIndex: entries.count))

            case .reservedActivity:
                guard !item.isFlexibleActivity else { continue }
                entries.append(FlatTimedEntry(item: item, stepIndex: nil, startDate: item.startDate, typeRank: 1, sourceIndex: entries.count))

            case .manualPoi:
                entries.append(FlatTimedEntry(item: item, stepIndex: nil, startDate: item.startDate, typeRank: 2, sourceIndex: entries.count))

            case .itinerary:
                guard planHasFlatRows(item), let plan = item.plan else { continue }
                for (stepIndex, step) in plan.steps.enumerated() {
                    let startDate = step.startDateTimes.flatMap { TRPDateHelper.parseDateTime($0) }
                    let typeRank = step.stepType == "activity" ? 1 : 2
                    entries.append(FlatTimedEntry(item: item, stepIndex: stepIndex, startDate: startDate, typeRank: typeRank, sourceIndex: entries.count))
                }
            }
        }

        return entries
    }

    /// Starting point of the plan: the accommodation when it is located, else the city centre.
    private func startingPointRow(for item: TRPMergedTimelineItem, city: TRPCity?) -> TimelineFlatRow? {
        if let accommodation = item.segment.accommodation, !accommodation.coordinate.isMissingOrZero {
            let name = accommodation.name ?? accommodation.address ?? "Starting Point"
            return .startingPoint(name: name, coordinate: accommodation.coordinate, item: item)
        }

        guard let city = city ?? item.city else { return nil }
        let cityCenter = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.cityCenter)
        let coordinate: TRPLocation?
        if let cached = TRPCityCache.shared.getCity(byId: city.id), !cached.coordinate.isMissingOrZero {
            coordinate = cached.coordinate
        } else if !city.coordinate.isMissingOrZero {
            coordinate = city.coordinate
        } else {
            coordinate = nil
        }
        return .startingPoint(name: "\(city.name) | \(cityCenter)", coordinate: coordinate, item: item)
    }
}
