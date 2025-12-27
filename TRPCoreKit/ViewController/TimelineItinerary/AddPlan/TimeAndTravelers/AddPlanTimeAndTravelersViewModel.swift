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
        
        // Set default starting point to city center if none is selected
        if containerViewModel.planData.startingPointLocation == nil {
            let cityCenterLocation = createCityCenterLocation()
            containerViewModel.planData.startingPointLocation = cityCenterLocation
            containerViewModel.planData.startingPointName = getCityCenterDisplayName()
        }
    }
    
    // MARK: - Public Methods
    public func getStartTime() -> Date? {
        return containerViewModel?.planData.startTime
    }
    
    public func getEndTime() -> Date? {
        return containerViewModel?.planData.endTime
    }
    
    public func getTravelerCount() -> Int {
        return containerViewModel?.planData.travelers ?? 0
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
        let current = containerViewModel?.planData.travelers ?? 0
        containerViewModel?.planData.travelers = current + 1
    }
    
    public func decrementTravelers() {
        let current = containerViewModel?.planData.travelers ?? 0
        if current > 0 {
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

    public func clearSelection() {
        // Reset to city center instead of nil
        containerViewModel?.planData.startingPointLocation = createCityCenterLocation()
        containerViewModel?.planData.startingPointName = getCityCenterDisplayName()
        containerViewModel?.planData.startTime = nil
        containerViewModel?.planData.endTime = nil
        containerViewModel?.planData.travelers = 0
    }
    
    // MARK: - Private Methods
    private func createCityCenterLocation() -> TRPLocation? {
        guard let city = containerViewModel?.planData.selectedCity else { return nil }
        return city.coordinate
    }
    
    private func getCityCenterDisplayName() -> String? {
        guard let city = containerViewModel?.planData.selectedCity else { return nil }
        return "\(city.name) - \(AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.cityCenter))"
    }
    
    // Keep this method for backwards compatibility if needed elsewhere
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
