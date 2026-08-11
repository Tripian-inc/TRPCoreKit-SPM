//
//  TRPTimelineItineraryViewModel+PlannedActivities.swift
//  TRPCoreKit
//
//  Copyright © 2026 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - Single inventory of activities already placed in the trip
//

import Foundation

/// Where a planned activity came from. Bookings are trip-level commitments; recommendations are
/// engine output tied to one day.
internal enum TRPPlannedActivitySource {
    case booking
    case recommendation
}

/// One occurrence of a bookable activity already placed in the trip.
internal struct TRPPlannedActivity {
    /// Bare product id (`cleanedAsActivityId()`) — the form every consumer compares on.
    let productId: String
    let providerId: Int
    let cityId: Int?
    /// "yyyy-MM-dd", or nil when the source carries no usable date.
    let day: String?
    let source: TRPPlannedActivitySource
}

extension TRPTimelineItineraryViewModel {

    /// Every bookable activity already in the trip, from one walk over all sources: booked/reserved
    /// segments (both `timeline.segments` and `tripProfile.segments` — they differ in order and
    /// content) and itinerary activity steps. Consumers slice by `day` / `source` instead of
    /// re-walking the timeline.
    ///
    /// Booking ids carry no reliable provider, so they report `15` (Civitatis) — what the exclude
    /// payload has always sent. Recommendation ids use the step's own `providerId`.
    internal func plannedActivities() -> [TRPPlannedActivity] {
        guard let timeline = timeline else { return [] }

        var activities: [TRPPlannedActivity] = []

        let bookingSegments = (timeline.segments ?? []) + (timeline.tripProfile?.segments ?? [])
        for segment in bookingSegments {
            guard segment.segmentType == .bookedActivity || segment.segmentType == .reservedActivity,
                  let activityId = segment.additionalData?.activityId,
                  !activityId.isEmpty else { continue }

            activities.append(TRPPlannedActivity(
                productId: activityId.cleanedAsActivityId(),
                providerId: 15,
                cityId: segment.city?.id,
                day: dayPart(of: segment.additionalData?.startDatetime ?? segment.startDate),
                source: .booking
            ))
        }

        for plan in timeline.plans ?? [] {
            for step in plan.steps {
                guard step.stepType == "activity",
                      let productId = step.poi?.additionalData?.productId,
                      !productId.isEmpty else { continue }

                activities.append(TRPPlannedActivity(
                    productId: productId.cleanedAsActivityId(),
                    providerId: step.poi?.additionalData?.providerId ?? 15,
                    cityId: plan.city?.id,
                    day: dayPart(of: step.startDateTimes),
                    source: .recommendation
                ))
            }
        }

        return activities
    }

    /// "yyyy-MM-dd" → the activity ids that day already holds, in API form. Threaded into the AddPlan
    /// flow: it both blocks a day that already has the activity and tells the server what the day
    /// holds when a new segment is created for it.
    public func plannedActivityIdsByDay() -> [String: [String]] {
        var idsByDay: [String: [String]] = [:]

        for activity in plannedActivities() {
            guard let day = activity.day else { continue }
            let id = TRPActivityIdFormat.make(activity.productId,
                                              providerId: activity.providerId,
                                              cityId: activity.cityId)
            guard !(idsByDay[day]?.contains(id) ?? false) else { continue }
            idsByDay[day, default: []].append(id)
        }

        return idsByDay
    }

    private func dayPart(of value: String?) -> String? {
        guard let value = value, value.count >= 10 else { return nil }
        return String(value.prefix(10))
    }
}
