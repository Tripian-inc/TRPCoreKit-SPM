//
//  OfferUseCases.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 28.08.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit


public protocol FetchOfferUseCase {
    
    func executeOffers(dateFrom: String?, dateTo: String?, northEast: TRPLocation?, southWest: TRPLocation?, typeId: [Int]?, excludeOptIn: Bool?, completion: ((Result<[TRPOffer], Error>) -> Void)? )
    
    func executeOffer(offerId: Int, completion: ((Result<TRPOffer, Error>) -> Void)? )
    
}

/// Get Poi list that user opted in offer
public protocol FetchOptInOfferUseCase {
    
    func executeOptInOffers(dateFrom: String?, dateTo: String?, completion: ((Result<[TRPPoi], Error>) -> Void)? )
    
}

public protocol AddOptInOfferUseCase {
    
    func executeAddOptInOffer(id: Int, claimDate: String?, completion: ((Result<Bool, Error>) -> Void)?)
    
}

public protocol DeleteOptInOfferUseCase {
    
    func executeDeleteOptInOffer(id: Int, completion: ((Result<Bool, Error>) -> Void)?)
    
}

public protocol ObserveOptInOfferUseCase {
    
    var values: ValueObserver<[TRPOffer]> { get }
    
    var poiValues: ValueObserver<[TRPPoi]> { get }

}
