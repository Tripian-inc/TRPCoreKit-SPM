//
//  CreateTripContainerViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 27.09.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation

public protocol CreateTripContainerViewModelDelegate: ViewModelDelegate {
    func stepChanged()
    func tripProcessCompleted()
    func askEditTripConfirmation()
    func tripGenerated(hash: String)
}

class CreateTripContainerViewModel {
    
    public weak var delegate: CreateTripContainerViewModelDelegate?
    public var editTripUseCase: EditTripUseCase?
    public var observeTripAllDay: ObserveTripCheckAllPlanUseCase?
    public var fetchTripAllDay: FetchTripCheckAllPlanUseCase?
    public var createTripUseCase: CreateTripUseCase?
    public var fetchUserTripUseCase: FetchUserUpcomingTripUseCase?
    
    private var currentStep = CreateTripSteps.tripInformation
    private let steps: [CreateTripSteps] = [.tripInformation, .stayShare, .pickedInformation, .personalize]
    
    public var isEditing: Bool = false
    public var nexusDestinationId: Int?
    
    private var tripProfile: TRPTripProfile?
    
    private var tryCount = 0
    
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
            let editText = TRPLanguagesController.shared.getLanguageValue(for: "trips.editTrip.submit")
            let createText = TRPLanguagesController.shared.getLanguageValue(for: "trips.createNewTrip.form.submit")
            return isEditing ? editText : createText
        }
        return TRPLanguagesController.shared.getLanguageValue(for: "trips.createNewTrip.form.continue")
    }
}

extension CreateTripContainerViewModel {
    func createOrEditTrip(profile: TRPTripProfile) {
        tripProfile = profile
        if !isEditing {
            if nexusDestinationId == nil && profile.additionalData == nil {
                getJuniperDestinationId(cityId: profile.cityId)
                return
            }
            createTrip()
        } else {
            
            guard let doNotGenerate = editTripUseCase?.doNotGenerate(newProfile: profile), doNotGenerate else {
                delegate?.askEditTripConfirmation()
                return
            }
            editTrip()
        }
    }
    
    func editTrip() {
        
        guard let tripProfile = tripProfile as? TRPEditTripProfile else { return }
        delegate?.viewModel(showPreloader: true)
        
        editTripUseCase?.executeEditTrip(profile: tripProfile) { [weak self] result in
            guard let strongSelf = self else { return }
            strongSelf.tripGenerationResult(result: result)
        }
    }
    
    private func createTrip() {
        guard let tripProfile else { return }
        if tripProfile.additionalData.isNilOrEmpty() && nexusDestinationId != nil {
            tripProfile.additionalData = "\(nexusDestinationId!)"
        }
        delegate?.viewModel(showPreloader: true)
        createTripUseCase?.executeCreateTrip(profile: tripProfile) { [weak self] result in
            guard let strongSelf = self else { return }
            strongSelf.tripGenerationResult(result: result)
        }
    }
    
    private func tripGenerationResult(result: Result<TRPTrip, Error>) {
        switch result {
        case .success(let trip):
            fetchUpcomingTrip()
            checkTripIsGenerated(tripHash: trip.tripHash)
        case .failure(let error):
            print("[Error] \(error.localizedDescription)")
            delegate?.viewModel(showPreloader: false)
            delegate?.viewModel(error: error)
        }
    }
    
    private func getJuniperDestinationId(cityId: Int) {
        delegate?.viewModel(showPreloader: true)
        TripianCommonApi().getDestinationIdFromCity(cityId) { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let cityInfo):
                guard let zoneId = cityInfo?.zoneId else {
                    strongSelf.delegate?.viewModel(showPreloader: false)
                    return
                }
                strongSelf.nexusDestinationId = zoneId
                strongSelf.tripProfile?.additionalData = "\(zoneId)"
                strongSelf.createTrip()
            case .failure(let failure):
                strongSelf.delegate?.viewModel(showPreloader: false)
                strongSelf.delegate?.viewModel(error: failure)
                print(failure)
                return
            }
        }
    }
    
    private func fetchUpcomingTrip() {
        fetchUserTripUseCase?.executeUpcomingTrip(completion: nil)
    }
    
    func checkTripIsGenerated(tripHash hash: String) {
        
        observeTripAllDay?.firstTripGenerated.addObserver(self, observer: { [weak self] status in
            self?.tryCount += 1
            if !status {
                if self?.tryCount ?? 0 > 8 {
                    self?.delegate?.viewModel(showPreloader: false)
                    self?.delegate?.viewModel(error: GeneralError.customMessage(TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.localExperiences.tourDetails.bookingStatus.rejected.description")))
                }
                return
            }
            self?.delegate?.viewModel(showPreloader: true)
            self?.delegate?.tripGenerated(hash: hash)
        })
        
        fetchTripAllDay?.executeFetchTripCheckAllPlanGenerate(tripHash: hash, completion: nil)
    }
}
