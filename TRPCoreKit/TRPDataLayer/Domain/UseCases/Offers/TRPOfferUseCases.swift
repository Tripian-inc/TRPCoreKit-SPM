//
//  TRPOfferUseCases.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 28.08.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit


public final class TRPOfferUseCases: ObserverController {
    
    
    private(set) var repository: OfferRepository
    public var dateFrom: String = ""
    public var dateTo: String = ""
    
    public init(offerRepository: OfferRepository = TRPOfferRepository()) {
        self.repository = offerRepository
    }
    
    public init(offerRepository: OfferRepository = TRPOfferRepository(), dateFrom: String, dateTo: String) {
        self.repository = offerRepository
        self.dateFrom = dateFrom
        self.dateTo = dateTo
    }
    
    private func clearValuesInRepository() {
        repository.results.value = []
        repository.poiResults.value = []
    }
    
    public func remove() {
        repository.results.removeObservers()
        repository.poiResults.removeObservers()
    }
    
    deinit {
        repository.results.removeObservers()
        repository.poiResults.removeObservers()
    }
}

extension TRPOfferUseCases: ObserveOptInOfferUseCase {
    

    public var values: ValueObserver<[TRPOffer]> {
        return repository.results
    }
    public var poiValues: ValueObserver<[TRPPoi]> {
        return repository.poiResults
    }
}

extension TRPOfferUseCases: FetchOfferUseCase {
    public func executeOffers(dateFrom: String?, dateTo: String?, northEast: TRPLocation?, southWest: TRPLocation?, typeId: [Int]?, excludeOptIn: Bool?, completion: ((Result<[TRPOffer], Error>) -> Void)?) {
        let onComplete = completion ?? {result in }
        var dateFromParam = self.dateFrom
        var dateToParam = self.dateTo
        if let _dateFrom = dateFrom, let _dateTo = dateTo {
            dateFromParam = _dateFrom
            dateToParam = _dateTo
        }
        repository.fetchOffers(dateFrom: dateFromParam, dateTo: dateToParam, northEast: northEast, southWest: southWest, typeId: typeId, excludeOptIn: excludeOptIn) { (result, pagination) in
            switch(result) {
            case .success(let offers):
                onComplete(.success(offers))
            case .failure(let error):
                onComplete(.failure(error))
            }
            
        }
    }
    
    public func executeOffer(offerId: Int, completion: ((Result<TRPOffer, Error>) -> Void)?) {
        let onComplete = completion ?? {result in }
        repository.fetchOffer(offerId: offerId) { result in
            switch(result) {
            case .success(let offer):
                onComplete(.success(offer))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
}

extension TRPOfferUseCases: FetchOptInOfferUseCase {
    public func executeOptInOffers(dateFrom: String?, dateTo: String?, completion: ((Result<[TRPPoi], Error>) -> Void)?) {
        if let dateFrom = dateFrom {
            self.dateFrom = dateFrom
        }
        if let dateTo = dateTo {
            self.dateTo = dateTo
        }
        let onComplete = completion ?? { result in }
        clearValuesInRepository()
        repository.fetchOptInOffers(dateFrom: self.dateFrom, dateTo: self.dateTo) { [weak self](result, pagination) in
            switch(result) {
            case .success(let optInOfferPois):
                self?.repository.poiResults.value = optInOfferPois
                self?.repository.results.value = self?.getOffersFromPois(pois: optInOfferPois)
                onComplete(.success(optInOfferPois))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
    
    private func getOffersFromPois(pois: [TRPPoi]) -> [TRPOffer] {
        
        let offers = pois.compactMap({ poi in
            return poi.offers
        })
        return offers.reduce([], +)
    }
    
}

extension TRPOfferUseCases: AddOptInOfferUseCase {
    public func executeAddOptInOffer(id: Int, claimDate: String?, completion: ((Result<Bool, Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        repository.addOptInOffer(offerId: id, claimDate: claimDate) { (result) in
            switch(result) {
            case .success(let status):
                onComplete(.success(status))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
    
}

extension TRPOfferUseCases: DeleteOptInOfferUseCase {
    public func executeDeleteOptInOffer(id: Int, completion: ((Result<Bool, Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        repository.removeOptInOffer(offerId: id) { (result) in
            switch(result) {
            case .success(let status):
                onComplete(.success(status))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
    
}
