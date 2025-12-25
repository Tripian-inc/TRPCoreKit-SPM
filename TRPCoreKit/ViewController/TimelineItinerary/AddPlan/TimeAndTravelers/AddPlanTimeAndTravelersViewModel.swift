//
//  AddPlanTimeAndTravelersViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation

public class AddPlanTimeAndTravelersViewModel {
    
    // MARK: - Properties
    private weak var containerViewModel: AddPlanContainerViewModel?
    private var savedPOIs: [TRPPoi] = [] // TODO: Load from actual data source
    
    // MARK: - Initialization
    public init(containerViewModel: AddPlanContainerViewModel) {
        self.containerViewModel = containerViewModel
        // TODO: Initialize savedPOIs from timeline data or trip data
        
        // Set default starting point to city center if none is selected
        if containerViewModel.planData.startingPoint == nil {
            containerViewModel.planData.startingPoint = createCityCenterPOI()
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
    
    public func getStartingPoint() -> TRPPoi? {
        return containerViewModel?.planData.startingPoint
    }
    
    public func setStartingPoint(_ poi: TRPPoi?) {
        containerViewModel?.planData.startingPoint = poi
    }
    
    public func getSavedPOIs() -> [TRPPoi] {
        return savedPOIs
    }
    
    public func getCityName() -> String? {
        return containerViewModel?.planData.selectedCity?.name
    }
    
    public func getCityCenterPOI() -> TRPPoi? {
        return createCityCenterPOI()
    }
    
    public func clearSelection() {
        // Reset to city center instead of nil
        containerViewModel?.planData.startingPoint = createCityCenterPOI()
        containerViewModel?.planData.startTime = nil
        containerViewModel?.planData.endTime = nil
        containerViewModel?.planData.travelers = 0
    }
    
    // MARK: - Private Methods
    private func createCityCenterPOI() -> TRPPoi? {
        guard let city = containerViewModel?.planData.selectedCity else { return nil }
        
        let cityCenter = TRPPoi(
            id: "city_center_\(city.id)",
            cityId: city.id,
            name: "\(city.name) - \(AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.cityCenter))",
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
            coordinate: city.coordinate,
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
