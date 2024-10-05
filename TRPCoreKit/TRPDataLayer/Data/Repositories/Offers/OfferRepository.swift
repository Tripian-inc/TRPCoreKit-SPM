//
//  OfferRepository.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 28.08.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation


public typealias OfferResultsValue = (Result<[TRPOffer], Error>, TRPPagination?)

public typealias OfferResultValue = (Result<TRPOffer, Error>)

public typealias OptInOfferResultsValue = (Result<[TRPPoi], Error>, TRPPagination?)

public typealias OptInOfferResultStatus = (Result<Bool, Error>)

public typealias OptInOfferNew = (Result<Bool, Error>) -> Void

public protocol OfferRepository {

    var results: ValueObserver<[TRPOffer]> {get set}
    
    var poiResults: ValueObserver<[TRPPoi]> {get set}
    
    var error: ValueObserver<Error> {get set}
    
    func fetchOffers(dateFrom: String,
                     dateTo:String,
                     northEast: TRPLocation?,
                     southWest: TRPLocation?,
                     typeId: [Int]?,
                     excludeOptIn: Bool?,
                     completion: @escaping (OfferResultsValue) -> Void)
    
    func fetchOffer(offerId: Int,
                    completion: @escaping (OfferResultValue) -> Void)
    
    func fetchOptInOffers(dateFrom: String?,
                          dateTo:String?,
                          completion: @escaping (OptInOfferResultsValue) -> Void)
    
    
    func addOptInOffer(offerId: Int,
                       claimDate: String?,
                       completion: @escaping (OptInOfferResultStatus) -> Void)
    
    
    func removeOptInOffer(offerId: Int,
                          completion: @escaping (OptInOfferResultStatus) -> Void)
    
}
