//
//  ExperienceBillingViewModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2020-11-07.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPProvider
enum ExperienceBillingCellType {
    case title
    case input
    case click
    case checkBox
}

enum ExperienceBillingType: String {
    case firstName = "First Name"
    case lastName = "Last Name"
    case email = "E-mail"
    case phone = "Phone"
    case country = "Country"

    case billingDetails = "Billing Details"
    case travelDetails = "Travel Details"
    case sameAsBilling = "Same as billing details"
    
    case travellerfirstName = "Traveler's First Name"
    case travellerlastName = "Traveler's Last Name"
    case travelleremail = "Traveler's E-mail"
    case travellerphone = "Traveler's Phone"
}

class ExperienceBillingModel {
    var type: ExperienceBillingType
    var cellType: ExperienceBillingCellType
    var data: String?
    var placeHolder: String
    
    internal init(type: ExperienceBillingType, cellType: ExperienceBillingCellType, data: String? = nil, placeHolder: String) {
        self.type = type
        self.cellType = cellType
        self.data = data
        self.placeHolder = placeHolder
    }
}

class ExperienceBillingViewModel: TableViewViewModelProtocol {
    
    typealias T = ExperienceBillingModel
    
    var cellViewModels: [ExperienceBillingModel] = [] {
        didSet {
            delegate?.viewModel(dataLoaded: true)
        }
    }
    
    var numberOfCells: Int { return cellViewModels.count}
    
    weak var delegate: ViewModelDelegate?
    private var isTravellerDisable = true
    private var countryCode: String?
    
    
    // USE CASE
    public var billingUseCases: BillingUseCase?
    public var paymentUseCases: PaymentUseCase?
    public var checkBookingInCardUseCase: CheckCardAndBookingUseCase?
    
    init() {}
    
    func start() {
        prepareData()
        clearOtherBookingInCard()
    }
    
    func getCellViewModel(at indexPath: IndexPath) -> ExperienceBillingModel {
        return cellViewModels[indexPath.row]
    }
    
    public func showTraveller(_ isOn: Bool) {
        isTravellerDisable = isOn
        if isOn {
            addTravellersInfoOnCell()
        }else {
            removeTravellersInfoOnCell()
        }
    }
    
    public func isValidInputs() -> Bool {
        var status = true
        let billingCell: [ExperienceBillingType] = [.firstName, .lastName, .country, .phone]
        let travellerCell: [ExperienceBillingType] = [.travellerfirstName, .travellerlastName, .travellerphone]
        
        for type in billingCell {
            let text = getDataWith(type: type)
            if text == nil {
                delegate?.viewModel(showMessage: "Please check \(type.rawValue)", type: .error)
                print("BU BOŞ OLAMAZ \(type.rawValue)")
                status = false
                break;
            }else if text != nil, text!.isEmpty {
                print("BU BOŞ OLAMAZ \(type.rawValue)")
                delegate?.viewModel(showMessage: "Please check \(type.rawValue)", type: .error)
                status = false
                break;
            }
        }
        
        if let text = getDataWith(type: .email), text.isEmpty {
            status = false
        }
        
        if isTravellerDisable {
            return status
        }
        
        for type in travellerCell {
            let text = getDataWith(type: type)
            if text == nil {
                print("BU BOŞ OLAMAZ \(type.rawValue)")
                delegate?.viewModel(showMessage: "Please check \(type.rawValue)", type: .error)
                status = false
                break;
            }else if text != nil, text!.isEmpty {
                print("BU BOŞ OLAMAZ \(type.rawValue)")
                delegate?.viewModel(showMessage: "Please check \(type.rawValue)", type: .error)
                status = false
                break;
            }
        }
        
        if let text = getDataWith(type: .travelleremail), text.isEmpty {
            status = false
        }
        
        return status
    }

    public func sendBillingAndTravelInfo() {
        guard let firstName = getDataWith(type: .firstName),
              let lastName = getDataWith(type: .lastName),
              let email = getDataWith(type: .email),
              let country = countryCode,
              let phone = getDataWith(type: .phone) else {
            return
        }
        
        let billing = GYGBilling(firstName: firstName,
                                 lastName: lastName,
                                 email: email,
                                 addressLine1: "",
                                 addressLine2: "",
                                 city: "",
                                 postalCode: "",
                                 state: "",
                                 countryCode: country,
                                 phoneNumber: phone)
        
        billingUseCases?.setBillingInfo(billing)
        
        guard let tFirstName = getDataWith(type: .travellerfirstName),
              let tLastName = getDataWith(type: .travellerlastName),
              let tEmail = getDataWith(type: .travelleremail),
              let tPhone = getDataWith(type: .travellerphone) else {
            return
        }
        
        let traveller = GYGTraveler(salutationCode: "m",
                                    firstName: tFirstName,
                                    lastName: tLastName,
                                    email: tEmail,
                                    phoneNumber: tPhone)
        billingUseCases?.setTravellerInfo(traveller)
    }
    
    
    
    
    
    public func updateCountryCell(_ name: String, _ code: String) {
        self.countryCode = code
        cellViewModels.first(where: {$0.type == .country})?.data = name
        delegate?.viewModel(dataLoaded: true)
    }
}

extension ExperienceBillingViewModel {
    
    private func prepareData() {
        var tempModel: [ExperienceBillingModel] = []
        tempModel.append(.init(type: .billingDetails, cellType: .title, data: nil, placeHolder: ExperienceBillingType.billingDetails.rawValue))
        tempModel.append(.init(type: .firstName, cellType: .input, data: nil, placeHolder: ExperienceBillingType.firstName.rawValue))
        tempModel.append(.init(type: .lastName, cellType: .input, data: nil, placeHolder: ExperienceBillingType.lastName.rawValue))
        tempModel.append(.init(type: .email, cellType: .input, data: nil, placeHolder: ExperienceBillingType.email.rawValue))
        tempModel.append(.init(type: .phone, cellType: .input, data: nil, placeHolder: ExperienceBillingType.phone.rawValue))
        tempModel.append(.init(type: .country, cellType: .click, data: nil, placeHolder: ExperienceBillingType.country.rawValue))
        tempModel.append(.init(type: .travelDetails, cellType: .title, data: nil, placeHolder: ExperienceBillingType.travelDetails.rawValue))
        tempModel.append(.init(type: .sameAsBilling, cellType: .checkBox, data: nil, placeHolder: ExperienceBillingType.sameAsBilling.rawValue))
        cellViewModels = tempModel
    }
    
    private func addTravellersInfoOnCell() {
        [ExperienceBillingType.travellerfirstName,
         ExperienceBillingType.travellerlastName,
         ExperienceBillingType.travelleremail,
         ExperienceBillingType.travellerphone].forEach { (type) in
            self.removeCellWithType(type)
        }
        
    }
    
    private func removeTravellersInfoOnCell() {
        var tempModel = [ExperienceBillingModel]()
        tempModel.append(.init(type: .travellerfirstName, cellType: .input, data: nil, placeHolder: ExperienceBillingType.travellerfirstName.rawValue))
        tempModel.append(.init(type: .travellerlastName, cellType: .input, data: nil, placeHolder: ExperienceBillingType.travellerlastName.rawValue))
        tempModel.append(.init(type: .travelleremail, cellType: .input, data: nil, placeHolder: ExperienceBillingType.travelleremail.rawValue))
        tempModel.append(.init(type: .travellerphone, cellType: .input, data: nil, placeHolder: ExperienceBillingType.travellerphone.rawValue))
        
        cellViewModels.append(contentsOf: tempModel)
    }
    
    
    private func removeCellWithType(_ type: ExperienceBillingType) {
        if let index = cellViewModels.firstIndex(where: {$0.type == type}) {
            cellViewModels.remove(at: index)
        }
    }
    
    private func getDataWith(type: ExperienceBillingType) -> String? {
        if let model = cellViewModels.first(where: {$0.type == type}) {
            return model.data
        }
        return nil
    }
    
    private func clearOtherBookingInCard() {
        delegate?.viewModel(showPreloader: true)
        checkBookingInCardUseCase?.removeOldBookingInCardIfNeedeed(completion: { [weak self] result in
            self?.delegate?.viewModel(showPreloader: false)
            switch result {
            case .success(let status):
                ()
                //TODO: SİLİNİP SİLİNMEME DURUMUNA GÖRE HATA VER
            case .failure(let error):
                self?.delegate?.viewModel(error: error)
            }
        })
    }
}

