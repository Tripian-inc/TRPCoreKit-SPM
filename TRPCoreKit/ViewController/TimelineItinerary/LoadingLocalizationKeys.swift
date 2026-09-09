//
//  LoadingLocalizationKeys.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 24.03.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import Foundation

public struct LoadingLocalizationKeys {
    // MARK: - Rotating Text Keys
    public static let findingActivities = "loading.text.findingActivities"
    public static let tailoringRecommendations = "loading.text.tailoringRecommendations"
    public static let optimizingRoute = "loading.text.optimizingRoute"

    // MARK: - Single Text Keys
    public static let gettingActivities = "loading.text.gettingActivities"
    public static let gettingPlaces = "loading.text.gettingPlaces"
    public static let loadingTimeSlots = "loading.text.loadingTimeSlots"
    public static let addingToItinerary = "loading.text.addingToItinerary"
    public static let removingFromPlan = "loading.text.removingFromPlan"
    public static let changingTime = "loading.text.changingTime"
    public static let gettingYourItineraryPlan = "loading.text.gettingYourItineraryPlan"

    // MARK: - Default English Values
    private static let defaultValues: [String: String] = [
        findingActivities: "Finding the best activities in your city",
        tailoringRecommendations: "Tailoring recommendations to your preferences",
        optimizingRoute: "Optimizing your route",
        gettingActivities: "Getting Activities",
        gettingPlaces: "Getting Places",
        loadingTimeSlots: "Loading available times",
        addingToItinerary: "Adding to your itinerary...",
        removingFromPlan: "Removing from plan",
        changingTime: "Changing time",
        gettingYourItineraryPlan: "Getting your itinerary plan"
    ]

    // MARK: - Helper Methods
    public static func localized(_ key: String) -> String {
        let localizedValue = TRPLanguagesController.shared.getLanguageValue(for: key)

        if localizedValue.isEmpty || localizedValue == key {
            return defaultValues[key] ?? key
        }

        return localizedValue
    }

    public static func allRotatingTexts() -> [String] {
        return [
            localized(findingActivities),
            localized(tailoringRecommendations),
            localized(optimizingRoute)
        ]
    }
}
