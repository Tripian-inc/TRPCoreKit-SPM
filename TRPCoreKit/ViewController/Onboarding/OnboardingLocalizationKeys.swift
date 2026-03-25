//
//  OnboardingLocalizationKeys.swift
//  TRPCoreKit
//
//  Created by Cem Caygoz on 25.03.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import Foundation

public struct OnboardingLocalizationKeys {

    // MARK: - Title & Badge
    public static let title = "onboarding.title"
    public static let badgeBeta = "onboarding.badge.beta"

    // MARK: - Feature 1
    public static let feature1Title = "onboarding.feature1.title"
    public static let feature1Description = "onboarding.feature1.description"

    // MARK: - Feature 2
    public static let feature2Title = "onboarding.feature2.title"
    public static let feature2Description = "onboarding.feature2.description"

    // MARK: - Feature 3
    public static let feature3Title = "onboarding.feature3.title"
    public static let feature3Description = "onboarding.feature3.description"

    // MARK: - Footer
    public static let footerLine1 = "onboarding.footer.line1"
    public static let footerLine2 = "onboarding.footer.line2"

    // MARK: - Buttons
    public static let buttonContinue = "onboarding.button.continue"
    public static let buttonSkip = "onboarding.button.skip"

    // MARK: - Default Values (Spanish)
    private static let defaultValues: [String: String] = [
        title: "Visualiza tus itinerarios",
        badgeBeta: "BETA",
        feature1Title: "Diseña tus rutas →",
        feature1Description: "Todos los planes ordenados cronológicamente y por días.",
        feature2Title: "Crea tu agenda →",
        feature2Description: "Organiza todo lo que quieres hacer desde cero o déjate inspirar por nuestras recomendaciones.",
        feature3Title: "Tus planes guardados →",
        feature3Description: "Añádelos al itinerario para tenerlos a mano, de un vistazo.",
        footerLine1: "No disponible en todos los destinos aún...",
        footerLine2: "¡Pero estamos trabajando en ello!",
        buttonContinue: "Continuar",
        buttonSkip: "Omitir"
    ]

    // MARK: - Helper Methods

    /// Returns the localized value for the given key, with fallback to default Spanish value
    public static func localized(_ key: String) -> String {
        let localizedValue = TRPLanguagesController.shared.getLanguageValue(for: key)

        // If the localization returns the key itself or is empty, use default value
        if localizedValue.isEmpty || localizedValue == key {
            return defaultValues[key] ?? key
        }

        return localizedValue
    }
}
