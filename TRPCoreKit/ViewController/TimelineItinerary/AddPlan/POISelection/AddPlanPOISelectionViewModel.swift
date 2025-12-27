//
//  AddPlanPOISelectionViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

public class AddPlanPOISelectionViewModel {
    
    // MARK: - Properties
    private var allPOIs: [TRPPoi]
    private var filteredPOIs: [TRPPoi]
    private let cityName: String?
    private let cityCenterPOI: TRPPoi?
    
    // MARK: - Initialization
    public init(savedPOIs: [TRPPoi], cityName: String?, cityCenterPOI: TRPPoi?) {
        self.allPOIs = savedPOIs
        self.filteredPOIs = savedPOIs
        self.cityName = cityName
        self.cityCenterPOI = cityCenterPOI
    }
    
    // MARK: - Public Methods
    public func getSavedPOIs() -> [TRPPoi] {
        return filteredPOIs
    }
    
    public func getCityName() -> String? {
        return cityName
    }
    
    public func getCityCenterPOI() -> TRPPoi? {
        return cityCenterPOI
    }

    public func getCityCenterLocation() -> TRPLocation? {
        return cityCenterPOI?.coordinate
    }

    public func getCityCenterDisplayName() -> String? {
        return cityCenterPOI?.name
    }

    public func searchPOIs(with searchText: String) {
        if searchText.isEmpty {
            filteredPOIs = allPOIs
        } else {
            filteredPOIs = allPOIs.filter { poi in
                poi.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}
