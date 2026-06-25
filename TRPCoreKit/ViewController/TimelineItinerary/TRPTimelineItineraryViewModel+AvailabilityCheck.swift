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

    /// One-shot post-load availability sweep: selected day first, then remaining non-past days in trip order. No-op on repeat calls.
    internal func runInitialAvailabilityCheck() {
        guard !hasRunInitialAvailabilityCheck else { return }
        hasRunInitialAvailabilityCheck = true

        availabilityCheckGeneration &+= 1
        let token = availabilityCheckGeneration

        let allDays = getDayDates()
        guard !allDays.isEmpty else { return }

        let nonPast = allDays.enumerated().compactMap { (idx, date) -> (Int, Date)? in
            return date.isPastDay() ? nil : (idx, date)
        }
        guard !nonPast.isEmpty else { return }

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
                    self.applyResults(response, targets: targets, dateString: dateString)
                    // cellData snapshots `isAvailabilityExpired` at build time, so rebuild it before the next reload().
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

        // `tripProfile.segments` is the single source of truth; `timeline.segments` has a different order.
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
        let provider = TRPCoreKit.shared.provider
        let prefix = provider.activityIdPrefix
        if !prefix.isEmpty, raw.hasPrefix(prefix) {
            return raw
        }
        var id = "\(prefix)\(raw)_\(provider.id)"
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
        var id = "\(TRPCoreKit.shared.provider.activityIdPrefix)\(productId)_\(providerId)"
        if let cityId = plan.city?.id {
            id += "_\(cityId)"
        }
        return id
    }

    // MARK: - Apply

    private func applyResults(_ response: [TRPTourScheduleAvailability],
                              targets: [AvailabilityTarget],
                              dateString: String) {
        var byId: [String: TRPTourScheduleAvailability] = [:]
        for entry in response { byId[entry.activityId] = entry }

        // Batch decisions, then apply once at the end.
        var planUpdates: [Int: [Int: Bool]] = [:]   // planIndex -> stepIndex -> expired
        var segmentExpires: [Int: Bool] = [:]       // segIndex -> expired

        for target in targets {
            let expired = isExpired(entry: byId[target.activityId], target: target)
            guard expired else { continue }

            // Cache by stable key so the decision survives a network re-fetch.
            expiredAvailabilityKeys.insert(availabilityCacheKey(
                activityId: target.activityId,
                dateString: dateString,
                expectedHHmm: target.expectedHHmm,
                isFlexible: target.isFlexible))

            switch target.location {
            case .reservedSegment(let index):
                segmentExpires[index] = true
            case .itineraryStep(let planIndex, let stepIndex):
                planUpdates[planIndex, default: [:]][stepIndex] = true
            }
        }

        // additionalData is a struct, so mutate via copy-and-write back onto the segment.
        if !segmentExpires.isEmpty, let segments = timeline?.tripProfile?.segments {
            for (index, _) in segmentExpires where index < segments.count {
                if var data = segments[index].additionalData {
                    data.isAvailabilityExpired = true
                    segments[index].additionalData = data
                }
            }
        }

        // Plans/steps are structs: copy, write through indexed paths, assign back.
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

    // MARK: - Cache re-apply (no network)

    /// Stable key `activityId|date|time` (time = `HH:mm`, or `flex`). Changing time yields a new key, so a stale decision stops applying.
    private func availabilityCacheKey(activityId: String, dateString: String,
                                      expectedHHmm: String?, isFlexible: Bool) -> String {
        let timeComponent = isFlexible ? "flex" : (expectedHHmm ?? "any")
        return "\(activityId)|\(dateString)|\(timeComponent)"
    }

    /// Drops the cached "expired" decision for a segment when its slot is re-validated (time change / removal). No-op for non-reserved segments.
    internal func clearCachedAvailability(for segment: TRPTimelineSegment) {
        guard segment.segmentType == .reservedActivity,
              let additional = segment.additionalData,
              let activityId = buildReservedActivityId(segment: segment, additional: additional),
              let dateString = datePart(of: additional.startDatetime ?? segment.startDate) else { return }

        let isFlexible = additional.isFlexible == true
        let expectedHHmm = isFlexible ? nil : timePart(of: additional.startDatetime)
        let key = availabilityCacheKey(activityId: activityId, dateString: dateString,
                                       expectedHHmm: expectedHHmm, isFlexible: isFlexible)
        expiredAvailabilityKeys.remove(key)
    }

    /// Re-applies cached "not available" decisions onto the current timeline (no network), restoring the transient flag wiped by a re-fetch.
    internal func reapplyCachedAvailabilityFlags() {
        guard !expiredAvailabilityKeys.isEmpty, timeline != nil else { return }

        var planUpdates: [Int: Set<Int>] = [:]   // planIndex -> stepIndexes

        for date in getDayDates() {
            let dateString = AvailabilityCheckDateFormat.shared.string(from: date)
            for target in targetsForDay(date) {
                let key = availabilityCacheKey(activityId: target.activityId,
                                               dateString: dateString,
                                               expectedHHmm: target.expectedHHmm,
                                               isFlexible: target.isFlexible)
                guard expiredAvailabilityKeys.contains(key) else { continue }

                switch target.location {
                case .reservedSegment(let index):
                    if let segments = timeline?.tripProfile?.segments, index < segments.count,
                       var data = segments[index].additionalData {
                        data.isAvailabilityExpired = true
                        segments[index].additionalData = data
                    }
                case .itineraryStep(let planIndex, let stepIndex):
                    planUpdates[planIndex, default: []].insert(stepIndex)
                }
            }
        }

        if !planUpdates.isEmpty, var plans = timeline?.plans {
            for (planIndex, steps) in planUpdates where planIndex < plans.count {
                for stepIndex in steps where stepIndex < plans[planIndex].steps.count {
                    plans[planIndex].steps[stepIndex].isAvailabilityExpired = true
                }
            }
            timeline?.plans = plans
        }
    }

    // MARK: - Expiry rule

    /// Expired when no entry/schedule/slots. Flexible target needs any slot; timed target needs a matching or flexible (`nil`-time) slot.
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

    private func datePart(of value: String?) -> String? {
        guard let value = value, value.count >= 10 else { return nil }
        return String(value.prefix(10))
    }

    private func timePart(of value: String?) -> String? {
        guard let value = value, value.count >= 16 else { return nil }
        let start = value.index(value.startIndex, offsetBy: 11)
        let end = value.index(value.startIndex, offsetBy: 16)
        return String(value[start..<end])
    }
}

// MARK: - File-local types

/// Descriptor for an item to verify, carrying its location in the live timeline so `applyResults` can flip its flag.
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

/// Shared `yyyy-MM-dd` formatter (recreating DateFormatters is expensive).
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
