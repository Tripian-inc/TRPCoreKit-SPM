//
//  AddPlanSelectDayViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation

public class AddPlanSelectDayViewModel {
    
    // MARK: - Properties
    private weak var containerViewModel: AddPlanContainerViewModel?
    
    // MARK: - Initialization
    public init(containerViewModel: AddPlanContainerViewModel) {
        self.containerViewModel = containerViewModel
    }
    
    // MARK: - Public Methods
    public func getAvailableDays() -> [Date] {
        return containerViewModel?.getAvailableDays() ?? []
    }
    
    public func getAvailableCities() -> [TRPCity] {
        return containerViewModel?.getAvailableCities() ?? []
    }
    
    public func getSelectedDay() -> Date? {
        return containerViewModel?.planData.selectedDay
    }
    
    public func getSelectedCity() -> TRPCity? {
        return containerViewModel?.planData.selectedCity
    }
    
    public func getSelectedMode() -> AddPlanMode {
        return containerViewModel?.planData.selectedMode ?? .none
    }
    
    public func setSelectedMode(_ mode: AddPlanMode) {
        containerViewModel?.planData.selectedMode = mode
    }
    
    public func selectDay(_ day: Date) {
        containerViewModel?.planData.selectedDay = day
    }
    
    public func selectCity(_ city: TRPCity) {
        containerViewModel?.planData.selectedCity = city
    }
    
    public func clearSelection() {
        if let days = containerViewModel?.getAvailableDays(), !days.isEmpty {
            containerViewModel?.planData.selectedDay = days.first
        }
        if let cities = containerViewModel?.getAvailableCities(), !cities.isEmpty {
            containerViewModel?.planData.selectedCity = cities.first
        }
    }
    
    public func setStartTime(_ time: Date?) {
        containerViewModel?.planData.startTime = time
    }
    
    public func setEndTime(_ time: Date?) {
        containerViewModel?.planData.endTime = time
    }
    
    public func getStartTime() -> Date? {
        return containerViewModel?.planData.startTime
    }
    
    public func getEndTime() -> Date? {
        return containerViewModel?.planData.endTime
    }
    
    public func getSelectedManualCategory() -> String? {
        return containerViewModel?.planData.selectedCategories.first
    }

    public func setSelectedManualCategory(_ categoryId: String?) {
        containerViewModel?.planData.selectedCategories = categoryId != nil ? [categoryId!] : []
    }

    // MARK: - Date-City Mapping

    /// Get cities for currently selected day
    /// Returns mapped cities first, then other cities
    public func getCitiesForSelectedDay() -> (mapped: [TRPCity], other: [TRPCity]) {
        guard let selectedDay = containerViewModel?.planData.selectedDay else {
            return (mapped: [], other: getAvailableCities())
        }
        return containerViewModel?.getCitiesForDate(selectedDay) ?? (mapped: [], other: getAvailableCities())
    }

    /// Check if date-city mapping is available
    public func hasDateCityMapping() -> Bool {
        return containerViewModel?.hasDateCityMapping() ?? false
    }
}
