//
//  TRPBackgroundGenerationRegistry.swift
//  TRPDataLayer
//
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import Foundation

/// Day-level identity of an itinerary segment: title, start day (yyyy-MM-dd) and city.
struct TRPRecommendationSegmentKey: Hashable {
    let title: String?
    let day: String?
    let cityId: Int?

    init(title: String?, startDate: String?, cityId: Int?) {
        self.title = title
        self.day = startDate.map { String($0.prefix(10)) }
        self.cityId = cityId
    }

    init(segment: TRPTimelineSegment) {
        self.init(title: segment.title, startDate: segment.startDate, cityId: segment.cityId ?? segment.city?.id)
    }
}

/// Smart recommendations whose generation continues in the background after the screen was released, per trip.
/// Generic generation pollers do not wait for the plans of these segments. A key drops out on its own once a poll of its
/// trip shows its segment without a pending plan or without the segment. Thread-safe.
final class TRPBackgroundGenerationRegistry {

    private struct Entry: Hashable {
        let tripHash: String
        let key: TRPRecommendationSegmentKey
    }

    static let shared = TRPBackgroundGenerationRegistry()

    private let lock = NSLock()
    private var entries = Set<Entry>()

    func register(_ key: TRPRecommendationSegmentKey, tripHash: String) {
        lock.lock()
        defer { lock.unlock() }
        entries.insert(Entry(tripHash: tripHash, key: key))
    }

    func unregister(_ key: TRPRecommendationSegmentKey, tripHash: String) {
        lock.lock()
        defer { lock.unlock() }
        entries.remove(Entry(tripHash: tripHash, key: key))
    }

    func isTracked(_ key: TRPRecommendationSegmentKey, tripHash: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return entries.contains(Entry(tripHash: tripHash, key: key))
    }

    /// True when `segment` is an itinerary segment whose key is registered for `tripHash`.
    func isTracked(_ segment: TRPTimelineSegment, tripHash: String) -> Bool {
        guard segment.segmentType == .itinerary else { return false }
        return isTracked(TRPRecommendationSegmentKey(segment: segment), tripHash: tripHash)
    }

    /// Day ids of the tracked segments of `timeline` that still have a pending plan. Keys of the same trip whose segment
    /// is missing from `timeline` or has no pending plan left are unregistered.
    func ignoredPlanIds(in timeline: TRPTimeline) -> Set<Int> {
        let pendingDayIds = Set((timeline.plans ?? []).filter { $0.generatedStatus == 0 }.flatMap { $0.dayIdComponents })
        let itinerarySegments = (timeline.tripProfile?.segments ?? []).filter { $0.segmentType == .itinerary }
        let dayIdsByKey = Dictionary(grouping: itinerarySegments, by: TRPRecommendationSegmentKey.init(segment:))
            .mapValues { segments in Set(segments.flatMap { $0.dayIds ?? [] }) }

        lock.lock()
        defer { lock.unlock() }
        var ignored = Set<Int>()
        for entry in entries where entry.tripHash == timeline.tripHash {
            let dayIds = dayIdsByKey[entry.key] ?? []
            if dayIds.isDisjoint(with: pendingDayIds) {
                entries.remove(entry)
            } else {
                ignored.formUnion(dayIds)
            }
        }
        return ignored
    }

    var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return entries.isEmpty
    }

    func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        entries.removeAll()
    }
}

extension TRPTimelinePlan {

    /// Numeric day ids the plan id is made of; a merged plan id such as "2188-2189" yields both.
    var dayIdComponents: [Int] {
        id.split(separator: "-").compactMap { Int($0) }
    }
}
