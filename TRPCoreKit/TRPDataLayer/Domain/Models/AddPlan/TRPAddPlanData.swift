//
//  TRPAddPlanData.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - Extracted from ViewModel to separate model file
//

import Foundation

// MARK: - AddPlan Mode

/// Mode for adding plans to timeline
public enum TRPAddPlanMode {
    case none
    case smartRecommendations
    case manual
}

// MARK: - AddPlan Data

/// Data container for AddPlan flow
/// Shared state between AddPlan child view controllers
public struct TRPAddPlanData {
    /// Selected day for the plan
    public var selectedDay: Date?

    /// Selected city for the plan
    public var selectedCity: TRPCity?

    /// Selected mode (smart recommendations, manual, etc.)
    public var selectedMode: TRPAddPlanMode = .none

    /// Starting point coordinates (lat/lon)
    public var startingPointLocation: TRPLocation?

    /// Display name for the starting point
    public var startingPointName: String?

    /// Start time for the plan
    public var startTime: Date?

    /// End time for the plan
    public var endTime: Date?

    /// Number of travelers
    public var travelers: Int = 0

    /// Selected activity categories (e.g., "guided_tours", "food")
    public var selectedCategories: [String] = []

    /// Timeline trip hash for segment creation
    public var tripHash: String?

    /// Available days from timeline/itinerary
    public var availableDays: [Date] = []

    public init() {}
}

// MARK: - Type Aliases for Backward Compatibility

public typealias AddPlanMode = TRPAddPlanMode
public typealias AddPlanData = TRPAddPlanData
