//
//  GetYourGuideApi.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 11.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public class GetYourGuideApi {
    
    static let DEVELOPER_MODE = false
    
    var network: Networking?
    
    
    var testApiKey = "api.testing20.gygtest.com"
    var productApiKey = "api.getyourguide.com"
    
    private let currency = "USD"
    
    private var networkController: NetworkController?
    
    
    public init(network: Networking = Networking()) {
        self.network = network
        networkController = createNetworkController(network: network)
    }
    
    private func createNetworkController(network: Networking) -> NetworkController {
        
        var urlComponent = URLComponents()
        urlComponent.scheme = "https"
        if GetYourGuideApi.DEVELOPER_MODE {
            urlComponent.host = testApiKey
        }else {
            urlComponent.host = productApiKey
        }
        let network =  NetworkController(network: network).urlComponent(urlComponent).addValue("X-ACCESS-TOKEN", value: TRPProvider.shared.getGygApiKey())
        network.provider = .gyg
        return network
    }
 
    public func jsonParser() {
//        let bookingHash = "PXYB4N00PRSRD0ANFHY09HA30Q7DO9WD"
//        let cardHash = "58YAF7I7OJSKFUKFHK0IUNQLJ1FB3L3L"
        
        /*getBooking(hash: "PXYB4N00PRSRD0ANFHY09HA30Q7DO9WD") { (result) in
            print("Result")
            print(result)
        }*/
        
        /*deleteBooking(hash:hash) { (result) in
            print("Result")
            print(result)
        }*/
  
    }
}


//MARK: - Tours
extension GetYourGuideApi {
    
    //preformatted: String = "teaser",
    public func tours(cityName: String,
                      categoryIds: [Int]? = nil,
                      preformatted: String = "full",
                      language: String = "en",
                      currency: String = "usd",
                      fromDate from: String? = nil,
                      toDate to:String? = nil,
                      limit: Int = 500,
                      offset: Int = 0,
                      duration: Int = 1440,
                      completion: @escaping (Result<[GYGTour], Error>) -> Void) {
        
        
        let path = "/1/tours"
        
        var params = [URLQueryItem]()
        params.append(URLQueryItem(name: "cnt_language", value: "\(language)"))
        params.append(URLQueryItem(name: "currency", value: "\(currency)"))
        params.append(URLQueryItem(name: "q", value: "\(cityName)"))
        params.append(URLQueryItem(name: "preformatted", value: "\(preformatted)"))
        params.append(URLQueryItem(name: "limit", value: "\(limit)"))
        params.append(URLQueryItem(name: "offset", value: "\(offset)"))
//        params.append(URLQueryItem(name: "duration[]", value: "\(duration)"))
        if let categories = categoryIds, categories.count > 0 {
            let converted = categories.map{"\($0)"}
            for category in converted {
                params.append(URLQueryItem(name: "categories[]", value: category))
            }
//            params.append(URLQueryItem(name: "categories", value: converted.joined(separator: ",")))
            
        }
        if let from = from {
            params.append(URLQueryItem(name: "date[]", value: from))
        }
        if let to = to {
            params.append(URLQueryItem(name: "date[]", value: to))
        }
        
        networkController?
            .urlComponentPath(path)
            .parameters(params)
            .responseDecodable(type: GYGGenericDataParser<GYGTours>.self) { (result) in
            switch result {
            case .success(let model):
                completion(.success(model.data?.tours ?? []))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
}

//MARK: - Tour
extension GetYourGuideApi {
    
    public func tour(id: Int,
                     preformatted: String = "full",
                     language: String = "en",
                     currency: String = "usd",
                     completion: @escaping (Result<GYGTour, Error>) -> Void) {
        let path = "/1/tours/\(id)"
        var params = [String: String]()
        params["cnt_language"] = "\(language)"
        params["currency"] = "\(currency)"
        params["preformatted"] = "\(preformatted)"
        
        networkController?.urlComponentPath(path).parameters(params).responseDecodable(type: GYGGenericDataParser<GYGTours>.self) { (result) in
            switch result {
            case .success(let model):
                if let tour = model.data?.tours?.first {
                    completion(.success(tour))
                }else {
                    print("Error tour is not found")
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
    
    /// <#Description#>
    /// - Parameters:
    ///   - id: TourId
    ///   - language: <#language description#>
    ///   - currency: <#currency description#>
    ///   - from: "Y-m-dTH:i:s"
    ///   - to: "Y-m-dTH:i:s"
    ///   - completion: <#completion description#>
//    public func tourAvailabilities(id: Int,
//                                   language: String = "en",
//                                   currency: String = "usd",
//                                   fromDate from: String,
//                                   toDate to:String,
//                                   completion: @escaping (Result<[GYGAvailability], Error>) -> Void) {
//        let path = "/1/tours/\(id)/availabilities"
//        var params = [URLQueryItem]()
//        params.append(URLQueryItem(name: "cnt_language", value: "\(language)"))
//        params.append(URLQueryItem(name: "currency", value: "\(currency)"))
//        params.append(URLQueryItem(name: "date[]", value: from))
//        params.append(URLQueryItem(name: "date[]", value: to))
//
//        networkController?.urlComponentPath(path).parameters(params).responseDecodable(type: GYGGenericDataParser<GYGAvailabilities>.self) { (result) in
//            switch result {
//            case .success(let model):
//
//                print("MODEL \(model)")
//                completion(.success(model.data?.availabilities ?? []))
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
    
    public func tourAvailability(id: Int,
                                 language: String = "en",
                                 currency: String = "usd",
                                 completion: @escaping (Result<GYGAvailability, Error>) -> Void) {
        let path = "/1/tours/\(id)/availability"
        var params = [URLQueryItem]()
        params.append(URLQueryItem(name: "cnt-language", value: "\(language)"))
        
        networkController?.urlComponentPath(path).parameters(params).responseDecodable(type: GYGAvailability.self) { (result) in
            switch result {
            case .success(let model):
                
//                print("MODEL \(model)")
                completion(.success(model))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
    public func tourOptions(tourId id: Int,
                                   language: String = "en",
                                   currency: String = "usd",
                                   fromDate from: String? = nil,
                                   toDate to:String? = nil,
                                   completion: @escaping (Result<[GYGTourOption], Error>) -> Void) {
        let path = "/1/tours/\(id)/options"
        var params = [String: String]()
        params["cnt_language"] = "\(language)"
        params["currency"] = "\(currency)"
        if let fromDate = from {
            params["date[]"] = fromDate
        }
        if let toDate = to {
            params["date[]"] = toDate
        }
        
        networkController?.urlComponentPath(path).parameters(params).responseDecodable(type: GYGGenericDataParser<GYGToursOptionParser>.self) { (result) in
            switch result {
            case .success(let model):
                
                print("MODEL \(model)")
                completion(.success(model.data?.options ?? []))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
    public func options(optionId id: Int,
                        language: String = "en",
                        currency: String = "usd",
                        completion: @escaping (Result<GYGTourOption?, Error>) -> Void) {
        let path = "/1/options/\(id)"
        var params = [String: String]()
        params["cnt_language"] = "\(language)"
        params["currency"] = "\(currency)"
        
        
        networkController?.urlComponentPath(path).parameters(params).responseDecodable(type: GYGGenericDataParser<GYGToursOptionParser>.self) { (result) in
            switch result {
            case .success(let model):
                print("MODEL \(model)")
                completion(.success(model.data?.options?.first))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}


//MARK: - Category
extension GetYourGuideApi {
    
    public func categories(language: String = "en",
                           currency: String = "usd",
                           limit: Int? = nil,
                           completion: @escaping (Result<[GYGCategory], Error>) -> Void) {
        
        let path = "/1/categories"
        var params = [String: String]()
        params["cnt_language"] = "\(language)"
        params["currency"] = "\(currency)"
        
        if let limit = limit {
            params["limit"] = "\(limit)"
        }
        
        networkController?.urlComponentPath(path).parameters(params).responseDecodable(type: GYGGenericDataParser<GYGCategories>.self) { (result) in
            switch result {
            case .success(let model):
                completion(.success(model.data?.categories ?? []))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
    public func category(id: Int,
                         language: String = "en",
                         currency: String = "usd",
                         limit: Int? = nil,
                         completion: @escaping (Result<[GYGCategory], Error>) -> Void) {
        
        let path = "/1/categories/\(id)"
        var params = [String: String]()
        params["cnt_language"] = "\(language)"
        params["currency"] = "\(currency)"
        
        if let limit = limit {
            params["limit"] = "\(limit)"
        }
        
        networkController?.urlComponentPath(path).parameters(params).responseDecodable(type: GYGGenericDataParser<GYGCategories>.self) { (result) in
            switch result {
            case .success(let model):
                completion(.success(model.data?.categories ?? []))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}


//MARK: - Reviews
extension GetYourGuideApi {
    
    public func reviews(tourId:Int,
                        language: String = "en",
                        currency: String = "usd",
                        sortfield: GYGSortField? = nil,
                        sortDirection: GYGSortDirection? = nil,
                        limit: Int? = nil,
                        completion: @escaping (Result<GYGReviews, Error>) -> Void) {
        
        let path = "/1/reviews/tour/\(tourId)"
        var params = [String: String]()
        params["cnt_language"] = "\(language)"
        params["currency"] = "\(currency)"
        
        if let sortField = sortfield {
            params["sortfield"] = sortField.rawValue
        }
        
        if let sortDirection = sortDirection {
            params["sortdirection"] = sortDirection.rawValue
        }
        
        if let limit = limit {
            params["limit"] = "\(limit)"
        }
        
        
        networkController?.urlComponentPath(path).parameters(params).responseDecodable(type: GYGGenericDataParser<GYGToursParser>.self) { (result) in
            switch result {
            case .success(let model):
                
                if model.data?.reviews != nil {
                    completion(.success(model.data!.reviews!))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
}


extension GetYourGuideApi {
    
//    public func optionPricings(optionId id: Int,
//                                   language: String = "en",
//                                   currency: String = "usd",
//                                   completion: @escaping (Result<[GYGOptionPricing], Error>) -> Void) {
//        let path = "/1/options/\(id)/pricings"
//        var params = [String: String]()
//        params["cnt_language"] = "\(language)"
//        params["currency"] = "\(currency)"
//
//        networkController?.urlComponentPath(path).parameters(params).responseDecodable(type: GYGGenericDataParser<GYGPricingWithCategoryParser>.self) { (result) in
//            switch result {
//            case .success(let model):
//
//                print("MODEL \(model)")
//                completion(.success(model.data?.pricing ?? []))
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
    
    public func priceBreakdown(tourId id: Int,
                               dateTime: String,
                               participants: [GYGPricingBreakdownParticipantsProperty],
                               currency: String = "USD",
                               completion: @escaping (Result<[GYGOptionPricing], Error>) -> Void) {
        
        let path = "/1/tours/\(id)/price-breakdown"
       
        var dataParams = [String: Any]()
        dataParams["date"] = "\(dateTime)"
        var participantsParams = [String: Any]()
        participants.forEach { param in
            participantsParams[param.participantCategory] = param.count
        }
        dataParams["participants"] = participantsParams
        let baseData = ["currency": currency]
        
        var main = [String: Any]()
        main["base_data"] = baseData
        main["data"] = dataParams
        
        networkController?
            .urlComponentPath(path)
            .bodyParameters(main)
            .httpMethod(.post)
            .addValue("Content-Type", value: "application/json")
            .responseDecodable(type: GYGPricingWithCategoryParser.self) { (result) in
            switch result {
            case .success(let model):
                completion(.success(model.tourOptions ?? []))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

extension GetYourGuideApi {
    
    public func booking(optionId: Int,
                        dateTime: String,
                        price: Double,
                        categories: [GYGBookingCategoryPropety],
                        bookingParameters: [GYGBookingParameterProperty],
                        language: String = "en",
                        currency: String = "USD",
                        completion: @escaping (Result<GYGBookings?, Error>) -> Void) {
        
        let path = "/1/bookings"
       
        var bookableParams = [String: Any]()
        bookableParams["option_id"] = "\(optionId)"
        bookableParams["datetime"] = "\(dateTime)"
        bookableParams["price"] = "\(price)"
        bookableParams["categories"] = categories.map{$0.getParams()}
        bookableParams["booking_parameters"] = bookingParameters.map({$0.getParams()})
        let bookable = ["bookable": bookableParams]
        let booking = ["booking": bookable]
        let baseData = ["cnt_language": language, "currency": currency]
        
        var main = [String: Any]()
        main["base_data"] = baseData
        main["data"] = booking
        
        networkController?
            .urlComponentPath(path)
            .bodyParameters(main)
            .httpMethod(.post)
            .addValue("Content-Type", value: "application/json")
            .responseDecodable(type: GYGGenericDataParser<GYGBookingsParser>.self) { (result) in
            switch result {
            case .success(let model):
                completion(.success(model.data?.bookings))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func getBooking(hash: String,
                           language: String = "en",
                           currency: String = "usd",
                           completion: @escaping (Result<GYGPaymentBooking?, Error>) -> Void) {
        let path = "/1/bookings/\(hash)"
        var params = [String: String]()
        params["cnt_language"] = "\(language)"
        params["currency"] = "\(currency)"
        networkController?
            .urlComponentPath(path)
            .parameters(params)
            .httpMethod(.get)
            .addValue("Content-Type", value: "application/json")
            .responseDecodable(type: GYGGenericDataParser<GYGGetBookingResult>.self) { (result) in
            switch result {
            case .success(let model):
                completion(.success(model.data?.booking))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
    func deleteBooking(hash: String,
                       language: String = "en",
                       currency: String = "usd",
                       completion: @escaping (Result<GYGBookings?, Error>) -> Void) {
        let path = "/1/bookings/\(hash)"
        var params = [String: String]()
        params["cnt_language"] = "\(language)"
        params["currency"] = "\(currency)"
        networkController?
            .urlComponentPath(path)
            .parameters(params)
            .httpMethod(.delete)
            .addValue("Content-Type", value: "application/json")
            .responseDecodable(type: GYGGenericDataParser<GYGBookingsParser>.self) { (result) in
            switch result {
            case .success(let model):
                completion(.success(model.data?.bookings))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}



extension GetYourGuideApi {
    
    public func paymentConfiguration(country: String = "US",
                                        language: String = "en",
                                        currency: String = "usd",
                                        completion: @escaping (Result<[GYGPaymentMethod], Error>) -> Void) {
        let path = "/1/configuration/payment"
        
        var params = [String: String]()
        params["cnt_language"] = "\(language)"
        params["currency"] = "\(currency)"
        params["country"] = "\(country)"
        
        networkController?.urlComponentPath(path).parameters(params).responseDecodable(type: GYGGenericDataParser<GYGPaymentConfiuration>.self) { (result) in
            switch result {
            case .success(let model):
                print("MODEL \(model)")
                completion(.success(model.data?.paymentMethods ?? []))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func cart(shoppingCartId: Int,
                     shoppingCartHash: String,
                     billing: GYGBilling,
                     traveler: GYGTraveler? = nil,
                     payment: GYGPayment,
                     language: String = "en",
                     currency: String = "USD",
                     completion: @escaping (Result<GYGPaymentResult?, Error>) -> Void) {
        
        let path = "/1/carts"
        let travelModel = traveler == nil ? GYGTraveler(billing: billing) : traveler!
        let shoppingCart = GYGShoppingCart(shoppingCartID: shoppingCartId,
                                           billing: billing,
                                           traveler: travelModel,
                                           payment: payment)
        let data = DataClass(shoppingCart)
        let baseData = BaseData(language, currency)
        let mainData = MainData(baseData, data)
    
        _ = networkController!.encodeData(mainData)
        networkController?
            .urlComponentPath(path)
            .bodyData(mainData)
            .httpMethod(.post)
            .addValue("Content-Type", value: "application/json")
            .addValue("accept", value: "application/json")
            .responseDecodable(type: GYGGenericDataParser<GYGPaymentResult>.self) { (result) in
            switch result {
            case .success(let model):
                print("MODEL \(model)")
                completion(.success(model.data))
            case .failure(let error):
                print("Mazinga \(error)")
                completion(.failure(error))
            }
        }
    }
    
    public func getCart(hash: String,
                        language: String = "en",
                        currency: String = "usd",
                        completion: @escaping (Result<GYGPaymentResult?, Error>) -> Void) {
        let path = "/1/carts/\(hash)"
        var params = [String: String]()
        params["cnt_language"] = "\(language)"
        params["currency"] = "\(currency)"
        networkController?
            .urlComponentPath(path)
            .parameters(params)
            .httpMethod(.get)
            .addValue("Content-Type", value: "application/json")
            .responseDecodable(type: GYGGenericDataParser<GYGGetCartResult>.self) { (result) in
            switch result {
            case .success(let model):
                completion(.success(model.data?.shoppingCart))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    

    public func delete(language: String = "en",
                           currency: String = "usd",
                           bookingHash: String,
                           completion: @escaping (Result<Bool, Error>) -> Void) {
        
        let path = "/1/bookings/\(bookingHash)"
        var params = [String: String]()
        params["cnt_language"] = "\(language)"
        params["currency"] = "\(currency)"
        params["currency"] = "\(currency)"
        
        
        networkController?.urlComponentPath(path).parameters(params).httpMethod(.delete).responseDecodable(type: GYGGenericDataParser<GYGDeleteResponse>.self) { (result) in
            switch result {
            case .success(let model):
                completion(.success(true))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}


//TODO: - DATA YAPISI DEĞİŞECEK
struct MainData: Codable {
    let baseData: BaseData
    let data: DataClass

    enum CodingKeys: String, CodingKey {
        case baseData = "base_data"
        case data
    }
    
    init(_ baseData: BaseData, _ data: DataClass) {
        self.baseData = baseData
        self.data = data
    }
}

// MARK: - BaseData
struct BaseData: Codable {
    
    let cntLanguage, currency: String

    enum CodingKeys: String, CodingKey {
        case cntLanguage = "cnt_language"
        case currency
    }
    
    public init(_ cntLanguage: String, _ currency: String) {
        self.cntLanguage = cntLanguage
        self.currency = currency
    }
    
    
}

// MARK: - DataClass
public struct DataClass: Codable {
    
    let shoppingCart: GYGShoppingCart

    enum CodingKeys: String, CodingKey {
        case shoppingCart = "shopping_cart"
    }
    
    public init(_ shoppingCart: GYGShoppingCart) {
        self.shoppingCart = shoppingCart
    }
    
}











public protocol CustomDecodable {
    func getParams() -> [String: Any]
}

public struct GYGBookingCategoryPropety: CustomDecodable {

    public var categoryId: Int
    public var numberOfParticipants: Int
    public var name: String
    public var price: Double
    
    public init(categoryId: Int, name:String, numberOfParticipants: Int, price: Double) {
        self.categoryId = categoryId
        self.name = name
        self.numberOfParticipants = numberOfParticipants
        self.price = price
    }
    
    public func getParams() -> [String : Any] {
        return ["category_id": categoryId, "number_of_participants": numberOfParticipants]
    }
}


public struct GYGBookingParameterProperty: CustomDecodable {
    public var name: String
    public var value1: String
    public var value2: String?
    
    public init(name: String, value1: String, value2: String? = nil) {
        self.name = name
        self.value1 = value1
        self.value2 = value2
    }
    
    public func getParams() -> [String : Any] {
        var params = [String: String]()
        params["name"] = name
        params["value_1"] = value1
        if let wrappedValue2 = value2 {
            params["value_2"] = wrappedValue2
        }
        return params
    }
    
}

public struct GYGDeleteResponse: Codable {
    
}

public struct GYGPricingBreakdownParticipantsProperty: CustomDecodable {
    public var participantCategory: String
    public var count: Int
    
    public init(participantCategory: String, count: Int) {
        self.participantCategory = participantCategory
        self.count = count
    }
    
    public func getParams() -> [String : Any] {
        var params = [String: Int]()
        params[participantCategory] = count
        return params
    }
}
