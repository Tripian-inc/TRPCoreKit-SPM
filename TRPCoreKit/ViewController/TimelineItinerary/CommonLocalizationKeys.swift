//
//  CommonLocalizationKeys.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 06.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import Foundation

/// Shared localization keys used across multiple modules (AddPlan, Timeline, PoiDetail)
public struct CommonLocalizationKeys {
    // MARK: - Common Buttons
    public static let cancel = "common.button.cancel"
    public static let confirm = "common.button.confirm"
    public static let continueButton = "common.button.continue"
    public static let select = "common.button.select"

    // MARK: - Common Labels
    public static let from = "common.label.from"
    public static let freeCancellation = "common.label.freeCancellation"

    // MARK: - Default English Values
    private static let defaultValues: [String: String] = [
        cancel: "Cancel",
        confirm: "Confirm",
        continueButton: "Continue",
        select: "Select",
        from: "From",
        freeCancellation: "Free cancellation"
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
