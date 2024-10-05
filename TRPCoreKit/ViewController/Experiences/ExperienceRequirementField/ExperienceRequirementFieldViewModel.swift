//
//  ExperienceRequirementFieldViewModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2020-12-01.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

//RequirementFieldSubView(title: "Hotel adresi ", placeHolder: "Lütfen açık adresinizii giriniz", numberOfLine: 4)

struct ExperienceRequirementFieldUIModel {
    var type: ExperienceRequirementFieldViewModel.UIType = .input
    let title: String
    let subTitle: String?
    let placeHolder: String
    let numberOfLine: Int
}

protocol ExperienceRequirementFieldViewModelDelegate: ViewModelDelegate {
    func experienceRequirementFieldBookingCompleted(_ booking: GYGBookings?)
}


class ExperienceRequirementFieldViewModel {
    
    enum UIType {
        case input
        case bottomAction
    }
    
    let bookingParameters: [GYGBookingParameter]
    let language: GYGCondLanguage?
    let pickUp: String?
    weak var delegate: ExperienceRequirementFieldViewModelDelegate?
    var languageModel:ExperienceRequirementFieldUIModel?
    var requiredInfoModel: ExperienceRequirementFieldUIModel?
    var hotelModel: ExperienceRequirementFieldUIModel?
    var selectedLanguage: String?
    var selectedLanguageType: String?
    
    
    
    public var bookingParametersUseCase: BookingParametersUseCase?
    public var postBookingUseCase: PostBookingUseCase?
    
    
    init(bookingParameters: [GYGBookingParameter], language: GYGCondLanguage?, pickUp: String?) {
        self.bookingParameters = bookingParameters
        self.language = language
        self.pickUp = pickUp
    }
    
    func start() {
        
        if let lang = language, bookingParameters.contains(where: {$0.name == "language"})  {
            if !lang.languageAudio.isEmpty || !lang.languageBooklet.isEmpty || !lang.languageLive.isEmpty {
                languageModel = ExperienceRequirementFieldUIModel(type: .bottomAction, title: "Language", subTitle: nil, placeHolder: " Select language", numberOfLine: 0)
            }
        }
        
        if bookingParameters.contains(where: {$0.name.lowercased() == "hotel"}) {
            var pickupAddress = ""
            
            if let pick = pickUp, pick.count > 0 {
                pickupAddress = " \(pick)"
            }else {
                pickupAddress = " Hotel name, address, etc"
            }
            
            hotelModel =  ExperienceRequirementFieldUIModel(type: .bottomAction, title: "Pickup address", subTitle: nil, placeHolder: pickupAddress, numberOfLine: 2)
        }
        
        if let supplier = bookingParameters.first(where: {$0.name == "supplier_requested_question"}) {
            requiredInfoModel = ExperienceRequirementFieldUIModel(title: "Required Information", subTitle: supplier.description, placeHolder: "Enter your information", numberOfLine: 2)
        }
        
        delegate?.viewModel(dataLoaded: true)
    }
    
    
    
    public func isInputValuesValid(language: String?,
                                  hotel: String?,
                                  supplier: String?) -> Bool {
        
        if isMandatoryParameters("hotel") {
            if hotel == nil {
                print("[Error] Hotel is nil")
                return false
            }
            if hotel!.count < 4 {
                print("[Error] Hotel is not invalid")
                return false
            }
        }
        
        if isMandatoryParameters("language") {
            if language == nil {
                print("[Error] Language is nil")
                return false
            }
            if language!.count < 1 {
                print("[Error] Language is not invalid")
                return false
            }
        }
        
        if isMandatoryParameters("supplier_requested_question") {
            if supplier == nil {
                print("[Error] Requested Question is nil")
                return false
            }
        }
        
        return true
    }
    
    
    private func isMandatoryParameters(_ parameters: String) -> Bool {
        guard let bookingParameter = bookingParameters.first(where: {$0.name == parameters}) else {return false}
        return bookingParameter.mandatory ?? true
    }
    
    private func isRequeredParameters(_ parameters: String) -> Bool {
        return bookingParameters.contains(where: {$0.name == parameters})
    }
    
    func setSelectedLanugage(language: String, type: String) {
        self.selectedLanguage = language
        self.selectedLanguageType = type
    }
    
    public func setBookingParameters(language: String?,
                                     hotel: String?,
                                     supplier: String?) {
        var parameters = [GYGBookingParameterProperty]()
        
        if let lang = selectedLanguage, let type = selectedLanguageType {
            parameters.append(GYGBookingParameterProperty(name: "language", value1: type, value2: lang))
        }
        
        if isRequeredParameters("hotel"), let hotel = hotel {
            parameters.append(GYGBookingParameterProperty(name: "hotel", value1: hotel))
        }
        
        if isRequeredParameters("supplier_requested_question"), let supplier = supplier {
            parameters.append(GYGBookingParameterProperty(name: "supplier_requested_question", value1: supplier))
        }
        bookingParametersUseCase?.setBookingParameters(parameters)
        //bookingParametersUseCase?.setBookingParameters(T##bookingParameters: [GYGBookingParameterProperty]##[GYGBookingParameterProperty])
    }
    
    public func makeBooking() {
        delegate?.viewModel(showPreloader: true)
        postBookingUseCase?.postBooking(completion: { [weak self] result in
            self?.delegate?.viewModel(showPreloader: false)
            switch result {
            case .success(let booking):
                self?.delegate?.experienceRequirementFieldBookingCompleted(booking)
            case .failure(let error):
                self?.delegate?.viewModel(error: error)
            }
        })
    }
    
   
}
