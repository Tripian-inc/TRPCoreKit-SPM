//
//  AddPlanSteps.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation

public enum AddPlanSteps {
    case selectDayAndCity
    case timeAndTravelers
    case categorySelection
    
    func getPreviousStep() -> AddPlanSteps? {
        switch self {
        case .selectDayAndCity:
            return nil
        case .timeAndTravelers:
            return .selectDayAndCity
        case .categorySelection:
            return .timeAndTravelers
        }
    }
    
    func getNextStep() -> AddPlanSteps? {
        switch self {
        case .selectDayAndCity:
            return .timeAndTravelers
        case .timeAndTravelers:
            return .categorySelection
        case .categorySelection:
            return nil
        }
    }
    
    func getTitle() -> String {
        switch self {
        case .selectDayAndCity:
            return AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.addActivity)
        case .timeAndTravelers:
            return AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.smartRecommendations)
        case .categorySelection:
            return AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.smartRecommendations)
        }
    }
    
    func getIndex() -> Int {
        switch self {
        case .selectDayAndCity:
            return 0
        case .timeAndTravelers:
            return 1
        case .categorySelection:
            return 2
        }
    }
}
