//
//  PaymentViewModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2020-12-21.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPProvider
import TRPDataLayer

enum PaymentCellType {
    case title
    case input
    case reviewOrder
    case doubleInput
    case cardImages
}
enum PaymentCellUIType {
    case reviewYourOrder
    case review
    case paymentInfo
    case cardName
    case cardNumber
    case cardDateCVC
    case cardImages
}

class PaymentVieUIwModel {
    
    var type: PaymentCellUIType
    var cellType: PaymentCellType
    var data: Any?
    var placeHolder: String
    
    internal init(type: PaymentCellUIType, cellType: PaymentCellType, data: Any? = nil, placeHolder: String) {
        self.type = type
        self.cellType = cellType
        self.data = data
        self.placeHolder = placeHolder
    }
}

struct PaymentReviewOrder {
    var tourName: String
    var date: String
    var optionInfo: String
    var peopleInfo: String
    var totalPrice: String
    
    init(tourName: String,
         date: String,
         optionInfo: String,
         peopleInfo: String,
         totalPrice: String) {
        self.tourName = tourName
        self.date = date
        self.peopleInfo = peopleInfo
        self.totalPrice = totalPrice
        self.optionInfo = optionInfo
    }
    
    init(gygModel: GYGReviewOrder) {
        var people = ""
        for item in gygModel.people ?? []{
            people += "\(item.numberOfTours ?? 0) x \(item.name) "
        }
        
        let price = gygModel.price != nil ? "\(gygModel.price!)" : "Price"
        let dateTime: String = gygModel.dateTime ?? ""//convertReadableDateTime(gygModel.dateTime ?? "")
        
        tourName = gygModel.title ?? ""
        date = dateTime
        optionInfo = gygModel.optionTitle ?? ""
        peopleInfo = people
        totalPrice = price
    }
    

    private func convertReadableDateTime(_ dateTime: String?) -> String {
        guard let convertedDate = dateTime?.toDateWithoutUTC(format: "yyyy-MM-dd'T'HH:mm:ss") else {return ""}
        return convertedDate.toStringWithoutTimeZone(format: "d MMM yyyy HH:mm")
    }
    
}


protocol PaymentViewModelDelegate: ViewModelDelegate{
    func paymentViewModelPaymentSuccessfull(_ card: GYGPaymentResult?)
    func showSuccessMessage()
}


class PaymentViewModel: TableViewViewModelProtocol {
    
    typealias T = PaymentVieUIwModel
    
    var cellViewModels: [PaymentVieUIwModel] = [] {
        didSet {
            delegate?.viewModel(dataLoaded: true)
        }
    }
    
    var numberOfCells: Int { return cellViewModels.count}
    weak var delegate: PaymentViewModelDelegate?
    private var holderName: String = ""
    private var cardNo: String = ""
    private var cardCVC: String = ""
    private var cardMMYY: String = ""
    
    
    //--- USE CASES
    public var tripModeUseCases: TRPTripModeUseCases?
    public var paymentUseCases: PaymentUseCase?
    public var toursUseCase: TRPTourOptionsUseCases?
    public var bookingUseCases: TRPMakeBookingUseCases?
    public var reservationUseCases: TRPReservationUseCases?
    public var cityName: String = ""
    
    init() {}
    
    func start() {
        createCellModels()
        fetchConfiguration()
    }
    
    func getCellViewModel(at indexPath: IndexPath) -> PaymentVieUIwModel {
        return cellViewModels[indexPath.row]
    }
    
    public func setHolderName(_ value: String) {
        self.holderName = value
    }
    
    public func setCardNo(_ value: String) {
        self.cardNo = value
    }
    
    public func setCVC(_ value: String) {
        self.cardCVC = value
    }
    
    public func setMMYY(_ value: String) {
        self.cardMMYY = value
    }
    
    public func isValidInputValues() -> Bool {
        var invalid = [String]()
        let cardNoCount = cardNo.removeWhiteSpace().count
        if  cardNoCount < 13 || cardNoCount > 20 {
            invalid.append("Card Number")
        }
        
        let expiry = getExpiryDate(cardMMYY)
        if expiry.mm.isEmpty || expiry.yy.isEmpty {
            invalid.append("CVC")
        }
        
        if cardMMYY.count < 3 {
            invalid.append("Expire Date")
        }
        
        if !invalid.isEmpty {
            let expilane = "Please check \(invalid.toString(", "))."
            delegate?.viewModel(showMessage: expilane, type: .error)
            return false
        }
        return true
    }
    
    public func sendCardInfo() {
        
        let dateTime = getExpiryDate(cardMMYY)
        
        let card = GYGCard(holderName: holderName,
                           number: cardNo,
                           securityCode: cardCVC,
                           expiryMonth: dateTime.mm,
                           expiryYear: dateTime.yy)
        
        paymentUseCases?.setCreditCard(card: card)
        
        let adyenToken = paymentUseCases?.createAdyenKey()
        print("Adyen Token \(adyenToken!)")
        delegate?.viewModel(showPreloader: true)
        paymentUseCases?.postCart(completion: { [weak self] result in
            self?.delegate?.viewModel(showPreloader: false)
            switch result {
            case .success(let cardResult):
                if let card = cardResult {
                    self?.sendPaymentInfoTripianServer(card)
                }else {
                    print("[Error] Card is nil")
                }
                
                self?.delegate?.paymentViewModelPaymentSuccessfull(cardResult)
            case .failure(let error):
                self?.delegate?.viewModel(error: error)
            }
        })
    }
    
    
    private func sendPaymentInfoTripianServer(_ model: GYGPaymentResult) {
        
//        guard let tour = bookingUseCases?.tour else {return}
//        guard let tripHash = tripModeUseCases?.trip.value?.tripHash else {return}
//      
//        var tempModel = model
//        tempModel.tourName = tour.title
//        tempModel.tourImage = tour.pictures.first?.url
//        tempModel.cityName = cityName
//        
//        var shopingCart: [String:Any] = [:]
//        shopingCart["shopping_cart"] = tempModel.dictionary ?? [:]
//        
//        var data: [String:Any] = [:]
//        data["data"] = shopingCart
//        
//        reservationUseCases?.executeAddReservation(key: "GYG", provider: "GYG", tripHash: tripHash, poiId: nil, values: data) { result in
//            switch result {
//            case .success(let reservation):
//                self.delegate?.showSuccessMessage()
//                print("Reservasyon Sonucu: \(reservation)")
//            case .failure(let error):
//                self.delegate?.viewModel(error: error)
//            }
//        }
    }
    
    
    //todo: - Seperate card ino
    private func getExpiryDate(_ value: String) -> (mm: String, yy: String) {
        let expiry = value.components(separatedBy: "/")
        if expiry.count == 2 {
            return (expiry[0],expiry[1])
        }
        return ("","")
    }
    
}


extension PaymentViewModel {
    
    private func createCellModels() {
        
        let reviewTitle = PaymentVieUIwModel(type: .reviewYourOrder, cellType: .title, data: nil, placeHolder: "Review your order")
    
        let reviewOrderInfo = createPaymentReviewData()
        let review = PaymentVieUIwModel(type: .review, cellType: .reviewOrder, data: reviewOrderInfo, placeHolder: "")
        
        let creditCardTitle = PaymentVieUIwModel(type: .paymentInfo, cellType: .title, data: nil, placeHolder: "Payment Info")
        
        let cardName = PaymentVieUIwModel(type: .cardName, cellType: .input, data: nil, placeHolder: "Name on card")
        let cardNumber = PaymentVieUIwModel(type: .cardNumber, cellType: .input, data: nil, placeHolder: "Credit card number")
        let yearAndCVC = PaymentVieUIwModel(type: .cardDateCVC, cellType: .doubleInput, data: nil, placeHolder: "")
        
        //TODO: - Confiddeki kard isimleri eklenecek
        let cardImages = PaymentVieUIwModel(type: .cardImages, cellType: .cardImages, data: [GYGCardType](), placeHolder: "")
        
        cellViewModels = [reviewTitle,
                          review,
                          creditCardTitle,
                          cardName,
                          cardNumber,
                          yearAndCVC,
                          cardImages
        ]
    }
    
    private func createPaymentReviewData() -> PaymentReviewOrder {
         guard let order = paymentUseCases?.getReviewOrder() else {
             return PaymentReviewOrder(tourName: "", date: "", optionInfo: "", peopleInfo: "", totalPrice: "")
         }
         
         var people = ""
         for item in order.people ?? []{
             people += "\(item.numberOfParticipants) x \(item.name) "
         }
         
         let curreny = toursUseCase?.currency != nil ? toursUseCase!.currency : ""
         
         let price = order.price != nil ? "\(curreny) \(order.price!)" : "Price"
         let dateTime: String = convertReadableDateTime(order.dateTime)
         
         return PaymentReviewOrder(tourName: order.title ?? "",
                            date: dateTime,
                            optionInfo: order.option?.title ?? "",
                            peopleInfo: people,
                            totalPrice: price)
     }
    
    private func convertReadableDateTime(_ dateTime: String?) -> String {
        guard let convertedDate = dateTime?.toDateWithoutUTC(format: "yyyy-MM-dd'T'HH:mm:ss") else {return ""}
        return convertedDate.toStringWithoutTimeZone(format: "d MMM yyyy HH:mm")
    }
    
    private func fetchConfiguration() {
        paymentUseCases?.getConfiguration(completion: { [weak self] result in
            switch result {
            case .success(let methods):
                if let encrytedMethod = methods.first(where: {$0.name == "encrypted_credit_card"}),
                   let brands = encrytedMethod.brands {
                    let convertedCardImages = brands.compactMap({ GYGCardType(rawValue: $0.code) })
                    self?.updateCreditCardCells(convertedCardImages)
                }
            case .failure(let error):
                self?.delegate?.viewModel(error: error)
            }
        })
    }
    
    
    private func updateCreditCardCells(_ data: [GYGCardType]) {
        guard let cells = cellViewModels.first(where: {$0.cellType == .cardImages}) else { return }
        cells.data = data
    }
}


extension Encodable {
  var dictionary: [String: Any]? {
    guard let data = try? JSONEncoder().encode(self) else { return nil }
    return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
  }
}
