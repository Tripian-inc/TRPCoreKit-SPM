//
//  AddPlanTimeAndTravelersViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

public class AddPlanTimeAndTravelersViewModel {
    
    // MARK: - Properties
    private weak var containerViewModel: AddPlanContainerViewModel?
    private var savedPOIs: [TRPPoi] = [] // TODO: Load from actual data source
    
    // MARK: - Initialization
    public init(containerViewModel: AddPlanContainerViewModel) {
        self.containerViewModel = containerViewModel
        // TODO: Initialize savedPOIs from timeline data or trip data

        if containerViewModel.planData.startingPointLocation == nil {
            setStartingPointToCityCenter()
        }

        if containerViewModel.planData.travelers == 0 {
            containerViewModel.planData.travelers = 1
        }
    }
    
    // MARK: - Public Methods
    public func getSelectedDay() -> Date? {
        return containerViewModel?.planData.selectedDay
    }

    public func getStartTime() -> Date? {
        return containerViewModel?.planData.startTime
    }

    public func getEndTime() -> Date? {
        return containerViewModel?.planData.endTime
    }
    
    public func getTravelerCount() -> Int {
        let count = containerViewModel?.planData.travelers ?? 1
        return count > 0 ? count : 1
    }
    
    public func setStartTime(_ time: Date?) {
        containerViewModel?.planData.startTime = time
    }
    
    public func setEndTime(_ time: Date?) {
        containerViewModel?.planData.endTime = time
    }
    
    public func setTravelerCount(_ count: Int) {
        containerViewModel?.planData.travelers = count
    }
    
    public func incrementTravelers() {
        let current = containerViewModel?.planData.travelers ?? 1
        containerViewModel?.planData.travelers = current + 1
    }
    
    public func decrementTravelers() {
        let current = containerViewModel?.planData.travelers ?? 1
        if current > 1 {
            containerViewModel?.planData.travelers = current - 1
        }
    }
    
    public func getStartingPointLocation() -> TRPLocation? {
        return containerViewModel?.planData.startingPointLocation
    }
    
    public func getStartingPointName() -> String? {
        return containerViewModel?.planData.startingPointName
    }
    
    public func setStartingPoint(location: TRPLocation?, name: String?) {
        containerViewModel?.planData.startingPointLocation = location
        containerViewModel?.planData.startingPointName = name
    }
    
    public func getSavedPOIs() -> [TRPPoi] {
        return savedPOIs
    }
    
    public func getCityName() -> String? {
        return containerViewModel?.planData.selectedCity?.name
    }

    public func getCityId() -> Int? {
        return containerViewModel?.planData.selectedCity?.id
    }

    public func getSelectedCity() -> TRPCity? {
        return containerViewModel?.planData.selectedCity
    }

    // MARK: - Time Picker Bounds
    // Thin wrappers over `TimePickerBounds`; all honour the selected city's IANA timezone, falling back to device tz.

    public func getMinimumStartTime() -> Date? {
        return TimePickerBounds.minimumStartTime(
            selectedDay: getSelectedDay(),
            city: getSelectedCity()
        )
    }

    public func getMinimumEndTime() -> Date? {
        return TimePickerBounds.minimumEndTime(
            selectedDay: getSelectedDay(),
            city: getSelectedCity(),
            currentStartTime: getStartTime()
        )
    }

    /// "Today" → next top of the hour in the city's tz; future days → nil (picker default).
    public func getDefaultInitialTime() -> Date? {
        return TimePickerBounds.defaultInitialTime(
            selectedDay: getSelectedDay(),
            city: getSelectedCity()
        )
    }

    /// When a start time exists, opens one hour past it (13:30 → 14:30); otherwise mirrors `getDefaultInitialTime`.
    public func getDefaultInitialEndTime() -> Date? {
        return TimePickerBounds.defaultInitialEndTime(
            selectedDay: getSelectedDay(),
            city: getSelectedCity(),
            currentStartTime: getStartTime()
        )
    }

    // MARK: - Day & City Selection

    public func getAvailableDays() -> [Date] {
        return containerViewModel?.getAvailableDays() ?? []
    }

    public func getAvailableCities() -> [TRPCity] {
        return containerViewModel?.getAvailableCities() ?? []
    }

    public func hasSingleCity() -> Bool {
        return getAvailableCities().count == 1
    }

    public func getSelectedDayIndex() -> Int {
        guard let selectedDay = containerViewModel?.planData.selectedDay else { return 0 }
        let days = getAvailableDays()
        return days.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: selectedDay) }) ?? 0
    }

    public func selectDay(_ day: Date) {
        containerViewModel?.planData.selectedDay = day
    }

    public func selectCity(_ city: TRPCity) {
        containerViewModel?.planData.selectedCity = city
    }

    public func getCitiesForSelectedDay() -> (mapped: [TRPCity], other: [TRPCity]) {
        guard let selectedDay = containerViewModel?.planData.selectedDay else {
            return (mapped: [], other: getAvailableCities())
        }
        return containerViewModel?.getCitiesForDate(selectedDay) ?? (mapped: [], other: getAvailableCities())
    }

    public func hasDateCityMapping() -> Bool {
        return containerViewModel?.hasDateCityMapping() ?? false
    }

    public func getCityCenterDisplayName() -> String? {
        guard let city = containerViewModel?.planData.selectedCity else { return nil }
        return "\(city.name) - \(AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.cityCenter))"
    }

    public func setStartingPointToCityCenter() {
        let cityCenterLocation = createCityCenterLocation()
        let cityCenterName = getCityCenterDisplayName()
        containerViewModel?.planData.startingPointLocation = cityCenterLocation
        containerViewModel?.planData.startingPointName = cityCenterName
    }

    public func isStartingPointCityCenter() -> Bool {
        guard let currentLocation = containerViewModel?.planData.startingPointLocation else {
            return true
        }

        let availableCities = containerViewModel?.getAvailableCities() ?? []

        for city in availableCities {
            if areCoordinatesEqual(currentLocation, city.coordinate) {
                return true
            }
        }

        return false
    }

    private func areCoordinatesEqual(_ loc1: TRPLocation, _ loc2: TRPLocation) -> Bool {
        let tolerance = 0.0001
        return abs(loc1.lat - loc2.lat) < tolerance && abs(loc1.lon - loc2.lon) < tolerance
    }

    public func clearSelection() {
        setStartingPointToCityCenter()
        containerViewModel?.planData.startTime = nil
        containerViewModel?.planData.endTime = nil
        containerViewModel?.planData.travelers = 1
    }
    
    // MARK: - POI Selection Data

    public func getBookedActivities() -> [TRPTimelineSegment] {
        return containerViewModel?.getBookedActivities() ?? []
    }

    public func getFavouriteItems() -> [TRPSegmentFavoriteItem] {
        return containerViewModel?.getFavouriteItems() ?? []
    }

    public func getBoundarySW() -> TRPLocation? {
        return containerViewModel?.planData.selectedCity?.boundarySouthWest
    }

    public func getBoundaryNE() -> TRPLocation? {
        return containerViewModel?.planData.selectedCity?.boundaryNorthEast
    }

    // MARK: - Private Methods
    private func createCityCenterLocation() -> TRPLocation? {
        guard let city = containerViewModel?.planData.selectedCity else { return nil }
        return city.coordinate
    }

    public func getCityCenterPOI() -> TRPPoi? {
        guard let city = containerViewModel?.planData.selectedCity else { return nil }
        guard let location = createCityCenterLocation() else { return nil }
        
        let cityCenter = TRPPoi(
            id: "city_center_\(city.id)",
            cityId: city.id,
            name: getCityCenterDisplayName() ?? "City Center",
            image: nil,
            gallery: nil,
            duration: nil,
            price: nil,
            rating: nil,
            ratingCount: nil,
            description: nil,
            webUrl: nil,
            phone: nil,
            hours: nil,
            address: city.name,
            icon: "city_center",
            coordinate: location,
            bookings: nil,
            categories: [],
            tags: [],
            mustTries: [],
            cuisines: nil,
            attention: nil,
            closed: [],
            distance: nil,
            safety: [],
            locations: [],
            status: true,
            placeType: .poi,
            offers: [],
            additionalData: nil
        )
        
        return cityCenter
    }
}
