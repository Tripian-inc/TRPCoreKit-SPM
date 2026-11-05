//
//  NexusResumePolicy.swift
//  TRPCoreKit
//
//  Decides whether a Nexus open resumes the stored timeline or creates a new one. Pure, no I/O.
//

import Foundation

enum NexusResumePolicy {

    enum Decision: Equatable {
        /// Open the stored timeline.
        case resume
        /// Stored timeline's dates do not overlap the itinerary: forget the stored hash and create.
        case recreate
        /// Stored timeline unreachable: create without touching the stored hash.
        case create
    }

    struct DayRange: Equatable {
        let start: Date
        let end: Date
    }

    static func decide(fetchResult: Result<TRPTimeline, Error>, itinerary: TRPItineraryWithActivities) -> Decision {
        guard case .success(let timeline) = fetchResult else { return .create }
        return timelineDatesOverlapItinerary(timeline, itinerary) ? .resume : .recreate
    }

    /// True when the timeline's day range overlaps the itinerary's day range (inclusive).
    /// Falls back to true when either range cannot be parsed.
    static func timelineDatesOverlapItinerary(_ timeline: TRPTimeline, _ itinerary: TRPItineraryWithActivities) -> Bool {
        guard let existing = timelineDayRange(timeline),
              let incoming = dayRange(start: itinerary.startDatetime, end: itinerary.endDatetime) else {
            return true
        }
        return datesOverlap(existing, incoming)
    }

    static func datesOverlap(_ lhs: DayRange, _ rhs: DayRange) -> Bool {
        return lhs.start <= rhs.end && rhs.start <= lhs.end
    }

    /// The TimelineDate sentinel's range when present, otherwise the min start / max end of all segments.
    static func timelineDayRange(_ timeline: TRPTimeline) -> DayRange? {
        let profileSegments = timeline.tripProfile?.segments ?? []
        if let sentinel = profileSegments.first(where: { $0.title == "TimelineDate" && $0.available == false }),
           let range = dayRange(start: sentinel.startDate, end: sentinel.endDate) {
            return range
        }
        let segments = profileSegments + (timeline.segments ?? [])
        let starts = segments.compactMap { day(from: $0.startDate) }
        let ends = segments.compactMap { day(from: $0.endDate) }
        guard let start = starts.min(), let end = ends.max() else { return nil }
        return DayRange(start: start, end: end)
    }

    static func dayRange(start: String?, end: String?) -> DayRange? {
        guard let startDay = day(from: start), let endDay = day(from: end) else { return nil }
        return DayRange(start: startDay, end: endDay)
    }

    /// Parses the leading "yyyy-MM-dd" of a "yyyy-MM-dd", "yyyy-MM-dd HH:mm" or ISO "yyyy-MM-ddTHH:mm:ss" string.
    static func day(from value: String?) -> Date? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), value.count >= 10 else { return nil }
        return dayFormatter.date(from: String(value.prefix(10)))
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
