//
//  AddPlanContainerViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

public protocol AddPlanContainerViewModelDelegate: AnyObject {
    func stepChanged()
    func planCompleted(data: AddPlanData)
}

public struct AddPlanData {
    public var selectedDay: Date?
    public var selectedCity: TRPCity?
    public var selectedMode: AddPlanMode = .none
    public var startingPointLocation: TRPLocation? // Latitude/longitude coordinates
    public var startingPointName: String? // Display name for the starting point
    public var startTime: Date?
    public var endTime: Date?
    public var travelers: Int = 0
    public var selectedCategories: [String] = []
}

public enum AddPlanMode {
    case none
    case smartRecommendations
    case manual
}

public class AddPlanContainerViewModel {
    
    // MARK: - Properties
    public weak var delegate: AddPlanContainerViewModelDelegate?
    private var currentStep: AddPlanSteps = .selectDayAndCity
    public var planData = AddPlanData()
    
    private let availableDays: [Date]
    private let availableCities: [TRPCity]
    private let selectedDayIndex: Int
    
    // MARK: - Initialization
    public init(days: [Date], cities: [TRPCity], selectedDayIndex: Int) {
        self.availableDays = days
        self.availableCities = cities
        self.selectedDayIndex = selectedDayIndex

        // Pre-select day and city
        if selectedDayIndex < days.count {
            self.planData.selectedDay = days[selectedDayIndex]
        }
        self.planData.selectedCity = cities.first
    }
    
    // MARK: - Public Methods
    public func start() {
        currentStep = .selectDayAndCity
        delegate?.stepChanged()
    }
    
    public func goNextStep() {
        if let nextStep = currentStep.getNextStep() {
            currentStep = nextStep
            delegate?.stepChanged()
        } else {
            // Last step completed
            delegate?.planCompleted(data: planData)
        }
    }
    
    public func backStepAction() {
        if let previousStep = currentStep.getPreviousStep() {
            currentStep = previousStep
            delegate?.stepChanged()
        }
    }
    
    public func getCurrentStep() -> AddPlanSteps {
        return currentStep
    }
    
    public func getButtonTitle() -> String {
        if currentStep.getNextStep() == nil {
            return "Continuar" // Last step
        }
        return "Continuar"
    }
    
    public func getAvailableDays() -> [Date] {
        return availableDays
    }
    
    public func getAvailableCities() -> [TRPCity] {
        return availableCities
    }
    
    public func getSelectedDayIndex() -> Int {
        return selectedDayIndex
    }
}
