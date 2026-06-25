//
//  NexusTripDisplay.swift
//  TRPCoreKit
//
//  Display + filtering helpers for the Nexus "My Plans" list, built from the
//  user's existing TRPTimelines. Mirrors Android's TripDisplay: a timeline has
//  no trip-level name, so the card title is the plan cities joined and the
//  subtitle is the country. Dates come from the timeline's plans (falling back
//  to profile segments) so the row populates whenever any dated piece exists.
//

import Foundation
import TRPFoundationKit

enum NexusTripDisplay {

    private static let planDateFormat = "yyyy-MM-dd HH:mm"

    private static func segmentDates(_ t: TRPTimeline, start: Bool) -> [Date] {
        (t.tripProfile?.segments ?? []).compactMap { seg in
            let raw = start ? seg.startDate : seg.endDate
            guard let raw = raw else { return nil }
            return Date.fromString(raw, format: planDateFormat)
        }
    }

    static func earliestStart(_ t: TRPTimeline) -> Date? {
        let fromPlans = (t.plans ?? []).compactMap { $0.getStartDate() }
        if let m = fromPlans.min() { return m }
        return segmentDates(t, start: true).min()
    }

    static func latestEnd(_ t: TRPTimeline) -> Date? {
        let fromPlans = (t.plans ?? []).compactMap { $0.getEndDate() }
        if let m = fromPlans.max() { return m }
        return segmentDates(t, start: false).max()
    }

    /// Title = distinct plan-city names joined; falls back to the timeline city.
    static func cityTitle(_ t: TRPTimeline) -> String {
        let names = dedup((t.plans ?? []).compactMap { $0.city?.name }.filter { !$0.isEmpty })
        return names.isEmpty ? t.city.name : names.joined(separator: ", ")
    }

    /// Subtitle = distinct plan-city countries joined; falls back to the timeline country.
    static func country(_ t: TRPTimeline) -> String {
        let countries = dedup((t.plans ?? []).compactMap { $0.city?.countryName }.filter { !$0.isEmpty })
        if !countries.isEmpty { return countries.joined(separator: ", ") }
        return t.city.countryName
    }

    static func imageURL(_ t: TRPTimeline) -> URL? {
        let candidates = [t.city.image] + (t.plans ?? []).map { $0.city?.image }
        for case let s? in candidates where !s.isEmpty {
            if let url = URL(string: s) { return url }
        }
        return nil
    }

    static func dateRangeText(_ t: TRPTimeline) -> String {
        let s = earliestStart(t)?.toString(format: "MM/dd/yyyy")
        let e = latestEnd(t)?.toString(format: "MM/dd/yyyy")
        switch (s, e) {
        case let (s?, e?): return "\(s) - \(e)"
        case let (s?, nil): return s
        default: return ""
        }
    }

    /// Whole days from today to the trip start; nil when started/ongoing/undated.
    static func daysUntil(_ t: TRPTimeline) -> Int? {
        guard let start = earliestStart(t) else { return nil }
        let cal = Calendar.current
        let startDay = cal.startOfDay(for: start)
        let today = cal.startOfDay(for: Date())
        let days = cal.dateComponents([.day], from: today, to: startDay).day ?? 0
        return days > 0 ? days : nil
    }

    private static func dedup(_ items: [String]) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for i in items where !seen.contains(i) {
            seen.insert(i); out.append(i)
        }
        return out
    }
}
