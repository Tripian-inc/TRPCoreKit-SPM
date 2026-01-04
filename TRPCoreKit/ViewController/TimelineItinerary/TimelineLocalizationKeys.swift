//
//  TimelineLocalizationKeys.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 27.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation

public struct TimelineLocalizationKeys {
    // MARK: - Navigation
    public static let navigationTitle = "timeline.navigation.title"

    // MARK: - Booked Activity Cell
    public static let reservation = "timeline.bookedActivity.reservation"
    public static let confirmed = "timeline.bookedActivity.confirmed"
    public static let freeCancellation = "timeline.bookedActivity.freeCancellation"
    public static let adults = "timeline.bookedActivity.adults"
    public static let child = "timeline.bookedActivity.child"
    public static let children = "timeline.bookedActivity.children"

    // MARK: - Remove Activity Alert
    public static let removeActivityTitle = "timeline.removeActivity.title"
    public static let removeActivityMessage = "timeline.removeActivity.message"
    public static let remove = "timeline.removeActivity.remove"
    public static let cancel = "timeline.removeActivity.cancel"

    // MARK: - Remove Recommendations Alert
    public static let removeRecommendationsTitle = "timeline.removeRecommendations.title"
    public static let removeRecommendationsMessage = "timeline.removeRecommendations.message"

    // MARK: - Empty State
    public static let noPlansYet = "timeline.emptyState.noPlansYet"
    public static let noPlansDescription = "timeline.emptyState.noPlansDescription"

    // MARK: - Segment/Cell Labels
    public static let recommendations = "timeline.label.recommendations"
    public static let activityBadge = "timeline.label.activityBadge"
    public static let pointOfInterest = "timeline.label.pointOfInterest"
    public static let unknown = "timeline.label.unknown"
    public static let unknownLocation = "timeline.label.unknownLocation"
    public static let from = "timeline.label.from"

    // MARK: - Duration & Distance Formats
    public static let durationHours = "timeline.format.hours"
    public static let durationMinutes = "timeline.format.minutes"
    public static let durationCombined = "timeline.format.durationCombined"
    public static let distanceFormat = "timeline.format.distance"

    // MARK: - Errors
    public static let error = "timeline.error.title"
    public static let errorSomethingWentWrong = "timeline.error.somethingWentWrong"
    public static let errorGenerationFailed = "timeline.error.generationFailed"
    public static let errorTimeout = "timeline.error.timeout"

    // MARK: - Default English Values
    private static let defaultValues: [String: String] = [
        navigationTitle: "Plan Your Itinerary",
        reservation: "Reservation",
        confirmed: "Confirmed",
        freeCancellation: "Free cancellation",
        adults: "Adults",
        child: "Child",
        children: "Children",
        removeActivityTitle: "Remove Activity",
        removeActivityMessage: "Are you sure you want to remove this activity from your itinerary?",
        remove: "Remove",
        cancel: "Cancel",
        removeRecommendationsTitle: "Remove Recommendations",
        removeRecommendationsMessage: "Are you sure you want to remove these recommendations from your itinerary?",
        noPlansYet: "No Plans Yet",
        noPlansDescription: "Add must see attractions, restaurants and cafes or block time to rest and recharge.",
        recommendations: "Recommendations",
        activityBadge: "Activity",
        pointOfInterest: "Point of interest",
        unknown: "Unknown",
        unknownLocation: "Unknown Location",
        from: "From",
        durationHours: "%dh",
        durationMinutes: "%dm",
        durationCombined: "%dh %dm",
        distanceFormat: "%d min (%@ km)",
        error: "Error",
        errorSomethingWentWrong: "Something went wrong. Please try again.",
        errorGenerationFailed: "Failed to generate your itinerary. Please try again.",
        errorTimeout: "Request timed out. Please try again."
    ]

    // MARK: - Helper Methods
    public static func localized(_ key: String) -> String {
        let localizedValue = TRPLanguagesController.shared.getLanguageValue(for: key)

        // If the localization returns the key itself or is empty, use default English value
        if localizedValue.isEmpty || localizedValue == key {
            return defaultValues[key] ?? key
        }

        return localizedValue
    }

    // MARK: - Format Helpers

    /// Formats duration in minutes to localized string (e.g., "2h 30m" or "45m")
    public static func formatDuration(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 && mins > 0 {
            let format = localized(durationCombined)
            return String(format: format, hours, mins)
        } else if hours > 0 {
            let format = localized(durationHours)
            return String(format: format, hours)
        } else {
            let format = localized(durationMinutes)
            return String(format: format, mins)
        }
    }

    /// Formats distance with walking time (e.g., "5 min (0.4 km)")
    public static func formatDistance(minutes: Int, kilometers: String) -> String {
        let format = localized(distanceFormat)
        return String(format: format, minutes, kilometers)
    }
}
