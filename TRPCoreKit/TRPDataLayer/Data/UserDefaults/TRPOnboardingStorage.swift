//
//  TRPOnboardingStorage.swift
//  TRPCoreKit
//
//  Created by Cem Caygoz on 25.03.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import Foundation

/// Storage for onboarding-related UserDefaults values
struct TRPOnboardingStorage {

    /// Whether the user has seen the onboarding at least once
    @Storage(key: "trp_onboarding_has_seen", value: false)
    static var hasSeenOnboarding: Bool

    /// Number of times the user has tapped "Continue" on the onboarding
    @Storage(key: "trp_onboarding_continue_count", value: 0)
    static var continueCount: Int

    /// Whether the user has permanently dismissed the onboarding (via "Skip" or close button)
    @Storage(key: "trp_onboarding_dismissed_permanently", value: false)
    static var dismissedPermanently: Bool

    // MARK: - Helper Methods

    /// Determines whether the onboarding should be shown
    /// - Returns: true if onboarding should be displayed
    static func shouldShowOnboarding() -> Bool {
        // If permanently dismissed, never show again
        if dismissedPermanently {
            return false
        }

        // If never seen before, must show
        if !hasSeenOnboarding {
            return true
        }

        // If continue count is less than 3, show again
        return continueCount < 3
    }

    /// Called when user taps "Continue" button
    static func didTapContinue() {
        hasSeenOnboarding = true
        continueCount += 1
    }

    /// Called when user taps "Skip" or close button
    static func didTapDismiss() {
        hasSeenOnboarding = true
        dismissedPermanently = true
    }

    /// Resets all onboarding storage (for testing purposes)
    static func reset() {
        hasSeenOnboarding = false
        continueCount = 0
        dismissedPermanently = false
    }
}
