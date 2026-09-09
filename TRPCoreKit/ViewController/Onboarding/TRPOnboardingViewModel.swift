//
//  TRPOnboardingViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Caygoz on 25.03.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import Foundation

// MARK: - Delegate Protocol

public protocol TRPOnboardingViewModelDelegate: ViewModelDelegate {
    func onboardingViewModel(shouldDismiss: Bool, wasSkipped: Bool)
}

// MARK: - ViewModel

public class TRPOnboardingViewModel {

    // MARK: - Properties

    public weak var delegate: TRPOnboardingViewModelDelegate?

    // MARK: - Public Methods

    /// Checks whether the onboarding should be shown
    public static func shouldShowOnboarding() -> Bool {
        return TRPOnboardingStorage.shouldShowOnboarding()
    }

    /// Called when user taps the "Continue" button
    public func didTapContinue() {
        TRPOnboardingStorage.didTapContinue()
        delegate?.onboardingViewModel(shouldDismiss: true, wasSkipped: false)
    }

    /// Called when user taps the "Skip" button or close button
    public func didTapDismiss() {
        TRPOnboardingStorage.didTapDismiss()
        delegate?.onboardingViewModel(shouldDismiss: true, wasSkipped: true)
    }

    // MARK: - Localized Content

    public var title: String {
        OnboardingLocalizationKeys.localized(OnboardingLocalizationKeys.title)
    }

    public var badgeText: String {
        OnboardingLocalizationKeys.localized(OnboardingLocalizationKeys.badgeBeta)
    }

    public var feature1Title: String {
        OnboardingLocalizationKeys.localized(OnboardingLocalizationKeys.feature1Title)
    }

    public var feature1Description: String {
        OnboardingLocalizationKeys.localized(OnboardingLocalizationKeys.feature1Description)
    }

    public var feature2Title: String {
        OnboardingLocalizationKeys.localized(OnboardingLocalizationKeys.feature2Title)
    }

    public var feature2Description: String {
        OnboardingLocalizationKeys.localized(OnboardingLocalizationKeys.feature2Description)
    }

    public var feature3Title: String {
        OnboardingLocalizationKeys.localized(OnboardingLocalizationKeys.feature3Title)
    }

    public var feature3Description: String {
        OnboardingLocalizationKeys.localized(OnboardingLocalizationKeys.feature3Description)
    }

    public var footerLine1: String {
        OnboardingLocalizationKeys.localized(OnboardingLocalizationKeys.footerLine1)
    }

    public var footerLine2: String {
        OnboardingLocalizationKeys.localized(OnboardingLocalizationKeys.footerLine2)
    }

    public var continueButtonTitle: String {
        OnboardingLocalizationKeys.localized(OnboardingLocalizationKeys.buttonContinue)
    }

    public var skipButtonTitle: String {
        OnboardingLocalizationKeys.localized(OnboardingLocalizationKeys.buttonSkip)
    }
}
