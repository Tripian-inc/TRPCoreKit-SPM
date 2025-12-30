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
        noPlansDescription: "Add must see attractions, restaurants and cafes or block time to rest and recharge."
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
}
