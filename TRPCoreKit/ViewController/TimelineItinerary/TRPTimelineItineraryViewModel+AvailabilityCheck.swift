//
//  TRPTimelineItineraryViewModel+AvailabilityCheck.swift
//  TRPCoreKit
//
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit
import TRPRestKit

extension TRPTimelineItineraryViewModel {

    // MARK: - Public Entry

    /// Runs the one-shot post-load availability sweep. Selected day's batch goes
    /// out first, remaining non-past days follow sequentially in trip-day order.
    /// Past days are skipped entirely. Subsequent calls are no-ops (gated by
    /// `hasRunInitialAvailabilityCheck`).
    internal func runInitialAvailabilityCheck() {
        guard !hasRunInitialAvailabilityCheck else { return }
        hasRunInitialAvailabilityCheck = true

        availabilityCheckGeneration &+= 1
        let token = availabilityCheckGeneration

        let allDays = getDayDates()
        guard !allDays.isEmpty else { return }

        // Drop past days; preserve trip-day order in the remainder.
        let nonPast = allDays.enumerated().compactMap { (idx, date) -> (Int, Date)? in
            return date.isPastDay() ? nil : (idx, date)
        }
        guard !nonPast.isEmpty else { return }

        // Selected day first if it's a non-past day; otherwise just trip order.
        var ordered: [Date] = []
        if selectedDayIndex >= 0, selectedDayIndex < allDays.count,
           !allDays[selectedDayIndex].isPastDay() {
            ordered.append(allDays[selectedDayIndex])
        }
        for (idx, date) in nonPast where idx != selectedDayIndex {
            ordered.append(date)
        }

        Log.i("AvailabilityCheck: scheduled \(ordered.count) day(s); token=\(token)")
        pumpDays(remaining: ordered, token: token)
    }

    // MARK: - Sequential pump

    private func pumpDays(remaining: [Date], token: Int) {
        guard token == availabilityCheckGeneration else {
            Log.i("AvailabilityCheck: token \(token) stale; halting sweep")
            return
        }
        guard let next = remaining.first else {
            Log.i("AvailabilityCheck: sweep complete; token=\(token)")
            return
        }
        let rest = Array(remaining.dropFirst())
        processDay(date: next, token: token) { [weak self] in
            self?.pumpDays(remaining: rest, token: token)
        }
    }

    private func processDay(date: Date, token: Int, completion: @escaping () -> Void) {
        let targets = targetsForDay(date)
        guard !targets.isEmpty else {
            completion()
            return
        }

        let items = targets.map { $0.activityId }
        let dateString = AvailabilityCheckDateFormat.shared.string(from: date)

        Log.i("AvailabilityCheck: requesting \(items.count) item(s) for \(dateString)")

        TRPTourUseCases().executeGetTourScheduleAvailability(
            items: items,
            date: dateString,
            currency: TRPClient.getCurrency(),
            lang: nil
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else {
                    completion()
                    return
                }
                guard token == self.availabilityCheckGeneration else {
                    Log.i("AvailabilityCheck: discarding response for \(dateString); token stale")
                    completion()
                    return
                }
                switch result {
                case .success(let response):
                    self.applyResults(response, targets: targets)
                    // displayItems / cellData capture `isAvailabilityExpired` at build
                    // time (segments hold class refs but reads still snapshot, and plans
                    // are structs so the merged item also snapshots them). Rebuild via
                    // the standard mutation pattern (see `reconcileSegmentsWithItinerary`
                    // and TimelineDate updates in +TimelineOperations) so the next
                    // `reload()` sees the new flags. The sweep itself is gated by
                    // `hasRunInitialAvailabilityCheck`, so re-entering processTimelineData
                    // here is a no-op for the availability path.
                    self.processTimelineData()
                    self.delegate?.timelineItineraryViewModel(didUpdateTimeline: true)
                case .failure(let error):
                    Log.e("AvailabilityCheck: \(dateString) failed - \(error.localizedDescription)")
                }
                completion()
            }
        }
    }

    // MARK: - Target collection

    private func targetsForDay(_ date: Date) -> [AvailabilityTarget] {
        guard let timeline = self.timeline else { return [] }
        let dateString = AvailabilityCheckDateFormat.shared.string(from: date)
        var targets: [AvailabilityTarget] = []

        // Reserved-activity segments on this date. `tripProfile.segments` is the
        // single source of truth (see `mergeTimelineData` / `populateCitiesInSegments`);
        // `timeline.segments` has a different order and isn't what the UI reads from.
        if let segments = timeline.tripProfile?.segments {
            for (segIndex, segment) in segments.enumerated() {
                guard segment.segmentType == .reservedActivity else { continue }
                guard let additional = segment.additionalData else { continue }
                guard datePart(of: additional.startDatetime ?? segment.startDate) == dateString else { continue }
                guard let activityId = buildReservedActivityId(segment: segment, additional: additional) else { continue }

                let isFlexible = additional.isFlexible == true
                let expectedHHmm = isFlexible ? nil : timePart(of: additional.startDatetime)

                targets.append(AvailabilityTarget(
                    location: .reservedSegment(index: segIndex),
                    activityId: activityId,
                    expectedHHmm: expectedHHmm,
                    isFlexible: isFlexible
                ))
            }
        }

        // Itinerary activity steps on this date.
        if let plans = timeline.plans {
            for (planIndex, plan) in plans.enumerated() {
                for (stepIndex, step) in plan.steps.enumerated() {
                    guard step.stepType == "activity" else { continue }
                    guard datePart(of: step.startDateTimes) == dateString else { continue }
                    guard let activityId = buildItineraryStepActivityId(step: step, plan: plan) else { continue }
                    guard let hhmm = step.getStartTime() else { continue }

                    targets.append(AvailabilityTarget(
                        location: .itineraryStep(planIndex: planIndex, stepIndex: stepIndex),
                        activityId: activityId,
                        expectedHHmm: hhmm,
                        isFlexible: false
                    ))
                }
            }
        }

        return targets
    }

    // MARK: - Activity-id construction

    private func buildReservedActivityId(segment: TRPTimelineSegment,
                                         additional: TRPSegmentActivityItem) -> String? {
        guard let raw = additional.activityId, !raw.isEmpty else { return nil }
        if raw.hasPrefix("C_") {
            return raw
        }
        var id = "C_\(raw)_15"
        if let cityId = segment.city?.id {
            id += "_\(cityId)"
        }
        return id
    }

    private func buildItineraryStepActivityId(step: TRPTimelineStep,
                                              plan: TRPTimelinePlan) -> String? {
        guard let productId = step.poi?.additionalData?.productId, !productId.isEmpty,
              let providerId = step.poi?.additionalData?.providerId else {
            return nil
        }
        var id = "C_\(productId)_\(providerId)"
        if let cityId = plan.city?.id {
            id += "_\(cityId)"
        }
        return id
    }

    // MARK: - Apply

    private func applyResults(_ response: [TRPTourScheduleAvailability],
                              targets: [AvailabilityTarget]) {
        // Index response by activityId for O(1) lookups.
        var byId: [String: TRPTourScheduleAvailability] = [:]
        for entry in response { byId[entry.activityId] = entry }

        // Collect per-location decisions; apply mutations in batch at the end so
        // we touch `self.timeline?.plans` only once.
        var planUpdates: [Int: [Int: Bool]] = [:]   // planIndex -> stepIndex -> expired
        var segmentExpires: [Int: Bool] = [:]       // segIndex -> expired

        for target in targets {
            let expired = isExpired(entry: byId[target.activityId], target: target)
            guard expired else { continue }

            switch target.location {
            case .reservedSegment(let index):
                segmentExpires[index] = true
            case .itineraryStep(let planIndex, let stepIndex):
                planUpdates[planIndex, default: [:]][stepIndex] = true
            }
        }

        // Mutate reserved segments via the same `tripProfile.segments` array we
        // collected targets from. `TRPTimelineSegment` is a class so additionalData
        // is mutated via the two-step copy-and-write pattern (struct value semantics).
        if !segmentExpires.isEmpty, let segments = timeline?.tripProfile?.segments {
            for (index, _) in segmentExpires where index < segments.count {
                if var data = segments[index].additionalData {
                    data.isAvailabilityExpired = true
                    segments[index].additionalData = data
                }
            }
        }

        // Mutate itinerary steps. Plans/steps are structs; take a local copy of the
        // plans array, write through the indexed paths, then assign back.
        if !planUpdates.isEmpty, var plans = timeline?.plans {
            for (planIndex, stepMap) in planUpdates where planIndex < plans.count {
                for (stepIndex, _) in stepMap where stepIndex < plans[planIndex].steps.count {
                    plans[planIndex].steps[stepIndex].isAvailabilityExpired = true
                }
            }
            timeline?.plans = plans
        }

        Log.i("AvailabilityCheck: flagged \(segmentExpires.count) segment(s) and "
              + "\(planUpdates.values.reduce(0) { $0 + $1.count }) step(s) expired")
    }

    // MARK: - Expiry rule

    /// `nil` entry / `nil` schedule / empty slots → expired (for any target).
    /// Flexible target → available iff at least one slot exists.
    /// Timed target → available iff any `slot.time == expectedHHmm` OR any
    /// `slot.time == nil` (flexible slot covers any time on the date).
    private func isExpired(entry: TRPTourScheduleAvailability?,
                           target: AvailabilityTarget) -> Bool {
        guard let entry = entry, let schedule = entry.schedule else { return true }
        let slots = schedule.allSlots
        if slots.isEmpty { return true }
        if target.isFlexible { return false }
        guard let expected = target.expectedHHmm else { return false }
        for slot in slots {
            if slot.time == nil { return false }              // flexible slot covers any time
            if slot.time == expected { return false }
        }
        return true
    }

    // MARK: - Date / time helpers

    /// Extracts the leading "yyyy-MM-dd" out of a "yyyy-MM-dd HH:mm[:ss]" string.
    /// Returns `nil` for malformed / empty input.
    private func datePart(of value: String?) -> String? {
        guard let value = value, value.count >= 10 else { return nil }
        return String(value.prefix(10))
    }

    /// Extracts "HH:mm" out of a "yyyy-MM-dd HH:mm" / "yyyy-MM-dd HH:mm:ss" string.
    /// Returns `nil` when the value doesn't contain a time portion.
    private func timePart(of value: String?) -> String? {
        guard let value = value, value.count >= 16 else { return nil }
        let start = value.index(value.startIndex, offsetBy: 11)
        let end = value.index(value.startIndex, offsetBy: 16)
        return String(value[start..<end])
    }
}

// MARK: - File-local types

/// Compact descriptor for an item we need to verify against the schedule. Carries
/// the pointer into the live timeline so `applyResults` can flip its flag without
/// re-traversing the model graph.
private struct AvailabilityTarget {
    enum Location {
        case reservedSegment(index: Int)
        case itineraryStep(planIndex: Int, stepIndex: Int)
    }
    let location: Location
    let activityId: String
    let expectedHHmm: String?
    let isFlexible: Bool
}

/// Cached formatter for the `yyyy-MM-dd` strings the API takes (and we match against).
/// Date formatters are expensive to recreate; share one instance for the sweep.
private final class AvailabilityCheckDateFormat {
    static let shared = AvailabilityCheckDateFormat()
    private let formatter: DateFormatter

    private init() {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        self.formatter = f
    }

    func string(from date: Date) -> String {
        return formatter.string(from: date)
    }
}
