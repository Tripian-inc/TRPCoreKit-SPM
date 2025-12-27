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

    // MARK: - Default English Values
    private static let defaultValues: [String: String] = [
        navigationTitle: "Plan Your Itinerary"
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
