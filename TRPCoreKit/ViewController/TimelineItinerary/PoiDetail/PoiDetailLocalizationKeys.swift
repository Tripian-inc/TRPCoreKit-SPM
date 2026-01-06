//
//  PoiDetailLocalizationKeys.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 29.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation

public struct PoiDetailLocalizationKeys {
    // MARK: - Main Content
    public static let activities = "poiDetail.section.activities"
    public static let seeMore = "poiDetail.button.seeMore"
    public static let readFullDescription = "poiDetail.button.readFullDescription"
    // freeCancellation and from are now in CommonLocalizationKeys

    // MARK: - Key Data Section
    public static let keyData = "poiDetail.section.keyData"
    public static let phone = "poiDetail.label.phone"
    public static let openingHours = "poiDetail.label.openingHours"
    public static let closed = "poiDetail.label.closed"

    // MARK: - Meeting Point Section
    public static let meetingPoint = "poiDetail.section.meetingPoint"
    public static let whereItStarts = "poiDetail.label.whereItStarts"
    public static let viewMap = "poiDetail.button.viewMap"

    // MARK: - Features Section
    public static let features = "poiDetail.section.features"

    // MARK: - Map Action Sheet
    public static let openIn = "poiDetail.actionSheet.openIn"
    // cancel is now in CommonLocalizationKeys

    // MARK: - Default English Values
    private static let defaultValues: [String: String] = [
        activities: "Activities",
        seeMore: "See more",
        readFullDescription: "Read full description",
        keyData: "Key Data",
        phone: "Phone",
        openingHours: "Opening Hours",
        closed: "Closed",
        meetingPoint: "Meeting Point",
        whereItStarts: "Where it starts",
        viewMap: "View map",
        features: "Features",
        openIn: "Open in"
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
