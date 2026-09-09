//
//  FetchTourOptionsUseCases.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 2020-12-26.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol FetchTourOptionsUseCase {
    
//    func tourAvailabilities(id: Int,
//                                fromDate from: String,
//                                toDate to:String,
//                                completion: @escaping (Result<[GYGAvailability], Error>) -> Void)
    
    func tourAvailability(id: Int,
                          completion: @escaping (Result<GYGAvailability, Error>) -> Void)
    
    func tourOptions(tourId id: Int,
                    fromDate from: String? ,
                    toDate to:String? ,
                    completion: @escaping (Result<[GYGTourOption], Error>) -> Void)
    
//    func optionPricings(optionId id: Int,
//                        completion: @escaping (Result<[GYGOptionPricing], Error>) -> Void)
    
    func tourPriceBreakdown(tourId id: Int, dateTime: String, participants: [GYGPricingBreakdownParticipantsProperty], completion: @escaping (Result<[GYGOptionPricing], Error>) -> Void)
    
}

public protocol TourOptionDataHolder {
//    var availabilities: [GYGAvailability] { get set }
    var availability: GYGAvailability { get set }
    var tourOptions: [GYGTourOption] { get set}
    var optionsPricing: [GYGOptionPricing] { get set}
}

public class TRPTourOptionsUseCases: TourOptionDataHolder {
    
    public let language: String
    public let currency: String
    
//    public var availabilities: [GYGAvailability] = []
    public var availability: GYGAvailability = GYGAvailability()
    public var tourOptions: [GYGTourOption] = []
    public var optionsPricing: [GYGOptionPricing] = []
  
    
    public init(language: String = "en",
                currency: String = "EUR") {
        self.language = language
        self.currency = currency
    }
}

extension TRPTourOptionsUseCases: FetchTourOptionsUseCase {
//    public func tourAvailabilities(id: Int, fromDate from: String, toDate to: String, completion: @escaping (Result<[GYGAvailability], Error>) -> Void) {
//        GetYourGuideApi().tourAvailabilities(id: id, language: language, currency: currency, fromDate: from, toDate: to) {[weak self] result in
//            switch result{
//            case .success(let availabilities):
//                self?.availabilities = availabilities
//                completion(.success(availabilities))
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
    public func tourAvailability(id: Int, completion: @escaping (Result<GYGAvailability, Error>) -> Void) {
        GetYourGuideApi().tourAvailability(id: id, language: language, currency: currency) {[weak self] result in
            switch result{
            case .success(let availability):
                self?.availability = availability
                completion(.success(availability))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func tourOptions(tourId id: Int, fromDate from: String?, toDate to: String?, completion: @escaping (Result<[GYGTourOption], Error>) -> Void) {
        
        GetYourGuideApi().tourOptions(tourId: id, language: language, currency: currency, fromDate: from, toDate: to) { [weak self] result in
            switch result{
            case .success(let options):
                self?.tourOptions = options
                completion(.success(options))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
//    public func optionPricings(optionId id: Int, completion: @escaping (Result<[GYGOptionPricing], Error>) -> Void) {
//        GetYourGuideApi().optionPricings(optionId: id, language: language, currency: currency) { [weak self] result in
//            switch result{
//            case .success(let pricing):
//                self?.optionsPricing = pricing
//                completion(.success(pricing))
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
    
    public func tourPriceBreakdown(tourId id: Int, dateTime: String, participants: [GYGPricingBreakdownParticipantsProperty], completion: @escaping (Result<[GYGOptionPricing], Error>) -> Void) {
        GetYourGuideApi().priceBreakdown(tourId: id, dateTime: dateTime, participants: participants) { [weak self] result in
            switch result{
            case .success(let pricing):
//                self?.optionsPricing = pricing
                completion(.success(pricing))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}
