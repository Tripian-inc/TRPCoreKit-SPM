//
//  TRPReservationUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 2.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public final class TRPReservationUseCases {
    
    private(set) var repository: ReservationRepository
    
    
    //NOTE: CİTYID VE TRIPHASH İ BURAYA DAHA SONRA FRAMEWORK OLARAK DAGITILDIĞINDA BİRDEN FAZLA ŞEHİRDE KULLANILACAĞI İÇİN EKLEMEDİM.
    public init(reservationRepository: ReservationRepository = TRPReservationRepository()) {
        self.repository = reservationRepository
    }
    
}

extension TRPReservationUseCases: ObserveReservationUseCase {
    
    public var reservations: ValueObserver<[TRPReservation]> {
        repository.results
    }
    
}

extension TRPReservationUseCases: FetchReservationUseCase {
    
    public func executefetchReservation(cityId: Int, from: String?, to: String?, completion: ((Result<[TRPReservation], Error>) -> Void)?) {
        let onComplete = completion ?? {result in }
        repository.fetchReservation(cityId: cityId, from: from, to: to, provider: nil) { result in
            switch result {
            case .success(let reservations):
                onComplete(.success(reservations))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
    
}


extension TRPReservationUseCases: AddReservationUseCase {
    
    public func executeAddReservation(key: String, provider: String, tripHash: String?, poiId: String?, values: [String : Any]?, completion: ((Result<TRPReservation, Error>) -> Void)?) {
        let onComplete = completion ?? {result in }
        repository.addReservation(key: key, provider: provider, tripHash: tripHash, poiId: poiId, value: values) { result in
            switch result {
            case .success(let reservation):
                onComplete(.success(reservation))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
    
}

extension TRPReservationUseCases: DeleteReservationUseCase {
    
    public func executeDeleteReservation(id: Int, completion: ((Result<Bool, Error>) -> Void)?) {
        let onComplete = completion ?? {result in }
        repository.deleteReservation(id: id) { result in
            switch result {
            case .success(let status):
                onComplete(.success(status))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
    
}


extension TRPReservationUseCases: UpdateReservationUseCase {
    
    public func executeUpdateReservation(id: Int,
                                         key: String,
                                         provider: String,
                                         tripHash: String?,
                                         poiId: String?,
                                         values: [String : Any]?,
                                         completion: ((Result<TRPReservation, Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        
        repository.updateReservation(id: id, key: key, provider: provider, tripHash: tripHash, poiId: poiId, value: values) { result in
            switch result {
            case .success(let status):
                onComplete(.success(status))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
        
    }
    
    
}
