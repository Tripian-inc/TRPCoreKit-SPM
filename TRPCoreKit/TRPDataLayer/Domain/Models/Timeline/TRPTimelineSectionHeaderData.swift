//
//  TRPTimelineSectionHeaderData.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - Extracted from ViewModel to separate model file
//

import Foundation

// MARK: - Section Header Data

/// Data structure for timeline section header display
/// Used by TRPTimelineItineraryVC to configure section headers
public struct TRPTimelineSectionHeaderData {
    /// Name of the city for this section
    public let cityName: String

    /// Whether this is the first section in the list
    public let isFirstSection: Bool

    /// Whether to show the section header (false for single-city timelines)
    public let shouldShowHeader: Bool

    /// Whether the timeline has multiple destinations
    public let hasMultipleDestinations: Bool

    public init(
        cityName: String,
        isFirstSection: Bool,
        shouldShowHeader: Bool,
        hasMultipleDestinations: Bool
    ) {
        self.cityName = cityName
        self.isFirstSection = isFirstSection
        self.shouldShowHeader = shouldShowHeader
        self.hasMultipleDestinations = hasMultipleDestinations
    }
}
