//
//  TRPOfferRepository.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 28.08.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit


final public class TRPOfferRepository: OfferRepository {
    public var results: ValueObserver<[TRPOffer]> = .init([])
    public var poiResults: ValueObserver<[TRPPoi]> = .init([])
    
    public var error: ValueObserver<Error> = .init(nil)
    
    public var remoteApi: OfferRemoteApi
    
    public init(remoteApi: OfferRemoteApi = TRPOfferRemoteApi()) {
        self.remoteApi = remoteApi
    }
    
    public func fetchOffers(dateFrom: String, dateTo: String, northEast: TRPLocation?, southWest: TRPLocation?, typeId: [Int]?, excludeOptIn: Bool?, completion: @escaping (OfferResultsValue) -> Void) {
        remoteApi.fetchOffers(dateFrom: dateFrom, dateTo: dateTo, northEast: northEast, southWest: southWest, typeId: typeId, excludeOptIn: excludeOptIn, completion: completion)
    }
    
    public func fetchOffer(offerId: Int, completion: @escaping (OfferResultValue) -> Void) {
        remoteApi.fetchOffer(offerId: offerId, completion: completion)
    }
    
    public func fetchOptInOffers(dateFrom: String?, dateTo: String?, completion: @escaping (OptInOfferResultsValue) -> Void) {
        remoteApi.fetchOptInOffers(dateFrom: dateFrom, dateTo: dateTo, completion: completion)
    }
    
    public func addOptInOffer(offerId: Int, claimDate:String?, completion: @escaping (OptInOfferResultStatus) -> Void) {
        remoteApi.addOptInOffer(offerId: offerId, claimDate: claimDate, completion: completion)
    }
    
    public func removeOptInOffer(offerId: Int, completion: @escaping (OptInOfferResultStatus) -> Void) {
        remoteApi.deleteOptInOffer(offerId: offerId, completion: completion)
    }
    
    
}
