//
//  CreateTripContainerViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 27.09.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation

public protocol CreateTripContainerViewModelDelegate: AnyObject {
    func stepChanged()
    func tripProcessCompleted()
}

class CreateTripContainerViewModel {
    
    public weak var delegate: CreateTripContainerViewModelDelegate?
    
    private var currentStep = CreateTripSteps.tripInformation
    private let steps: [CreateTripSteps] = [.tripInformation, .stayShare, .pickedInformation, .personalize]
    
    public var isEditing: Bool = false
    
    public func getCurrentStep() -> CreateTripSteps {
        return currentStep
    }
    
    public func getPagingNumber() -> Int {
        return steps.count
    }
    
    public func getPagingTitle(index: Int) -> String {
        return steps[index].getTitle()
    }
    
    public func backStepAction() {
        if let previousStep = currentStep.getPreviousStep() {
            currentStep = previousStep
            delegate?.stepChanged()
        }
    }
    
    public func goNextStep() {
        ///if next step is nil then user is in last step
        guard let nextStep = currentStep.getNextStep() else {
            self.createTripAction()
            return
        }
        currentStep = nextStep
        delegate?.stepChanged()
    }
    
    public func isLastStep() -> Bool {
        return currentStep.getNextStep() == nil
    }
    
    private func createTripAction() {
        self.delegate?.tripProcessCompleted()
    }
    
    public func getButtonTitle() -> String {
        if isLastStep() {
            return isEditing ? "Edit my plan" : "Create my plan"
        }
        return "Continue"
    }
}


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
            return "Destination"
        case .stayShare:
            return "Traveler Info"
        case .pickedInformation:
            return "Itinerary Profile"
        case .personalize:
            return "Personal Interests"
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
