//
//  OfferRemoteApi.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 28.08.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

public protocol OfferRemoteApi {
    
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
    
    
    func deleteOptInOffer(offerId: Int,
                          completion: @escaping (OptInOfferResultStatus) -> Void)
}
