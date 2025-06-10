//
//  CreateTripSteps.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.05.2025.
//


public enum CreateTripSteps {
    case tripInformation
    case stayShare
    case pickedInformation
    case personalize
    
    func getPreviousStep() -> CreateTripSteps? {
        switch self {
        case .tripInformation:
            return nil
        case .stayShare:
            return .tripInformation
        case .pickedInformation:
            return .stayShare
        case .personalize:
            return .pickedInformation
        }
    }
    
    func getNextStep() -> CreateTripSteps? {
        switch self {
        case .tripInformation:
            return .stayShare
        case .stayShare:
            return .pickedInformation
        case .pickedInformation:
            return .personalize
        case .personalize:
            return nil
        }
    }
    
    func getTitle() -> String {
        switch self {
        case .tripInformation:
            return TRPLanguagesController.shared.getLanguageValue(for: "trips.createNewTrip.stepHeaders.destination")
        case .stayShare:
            return TRPLanguagesController.shared.getLanguageValue(for: "trips.createNewTrip.stepHeaders.travelerInfo")
        case .pickedInformation:
            return TRPLanguagesController.shared.getLanguageValue(for: "trips.createNewTrip.stepHeaders.itineraryProfile")
        case .personalize:
            return TRPLanguagesController.shared.getLanguageValue(for: "trips.createNewTrip.stepHeaders.personalInterests")
        }
    }
    
    func getIndex() -> Int {
        switch self {
        case .tripInformation:
            return 0
        case .stayShare:
            return 1
        case .pickedInformation:
            return 2
        case .personalize:
            return 3
        }
    }
}
