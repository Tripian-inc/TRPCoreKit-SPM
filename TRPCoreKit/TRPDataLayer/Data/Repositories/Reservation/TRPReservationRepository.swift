//
//  TRPReservationRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 25.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
final public class TRPReservationRepository: ReservationRepository {
    
    
    public var results: ValueObserver<[TRPReservation]> = .init([])
    
    public var error: ValueObserver<Error> = .init(nil)
    
    
    private(set) var remoteApi: ReservationRemoteApi
    private(set) var localStorage: UserReservationLocalStorage
    
    
    public init(remoteApi: ReservationRemoteApi = TRPReservationRemoteApi(),
                localStorage: UserReservationLocalStorage = TRPUserReservationLocalStorage()) {
        
        self.remoteApi = remoteApi
        self.localStorage = localStorage
    }
    
    
    public func fetchReservation(cityId: Int, from: String?, to: String?, provider: String?, completion: @escaping (ReservationResultsValue) -> Void) {
        remoteApi.fetchReservation(cityId: cityId, from: from, to: to, provider: provider) {[weak self] results in
            switch results {
            case .success(let reservations):
                self?.results.value = reservations
                completion(.success(reservations))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func addReservation(key: String, provider: String, tripHash: String?, poiId: String?, value: [String : Any]?, completion: @escaping (ReservationResultValue) -> Void) {
        
        remoteApi.addReservation(key: key, provider: provider, tripHash: tripHash, poiId: poiId, value: value) {[weak self] results in
            switch results {
            case .success(let reservation):
                
                if self?.results.value == nil {
                   self?.results.value = [reservation]
                }else {
                    self?.results.value?.append(reservation)
                }
                
                
                completion(.success(reservation))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
    }
    
    public func deleteReservation(id: Int, completion: @escaping (ReservationResultStatus) -> Void) {
        remoteApi.deleteReservation(id: id) { [weak self] results in
            switch results {
            case .success(let status):
                
                if status {
                    if let observableResult = self?.results.value, let index = observableResult.firstIndex(where: {$0.id == id}) {
                        self?.results.value?.remove(at: index)
                    }
                }
                
                completion(.success(status))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
    public func updateReservation(id: Int,
                                key: String,
                                provider: String,
                                tripHash: String?,
                                poiId: String?,
                                value: [String : Any]?,
                                completion: @escaping (ReservationResultValue) -> Void) {
        remoteApi.updateReservation(id: id, key: key, provider: provider, tripHash: tripHash, poiId: poiId, value: value) { [weak self] result in
            switch result {
            case .success(let reservation):
                //TODO: BURASI UPDATE E GÖRE GÜNCELLENECEK.
                if self?.results.value == nil {
                   self?.results.value = [reservation]
                }else {
                    if let index = self?.results.value?.firstIndex(where: {$0.id == id}) {
                        self?.results.value![index] = reservation
                    }
                }
                
                completion(.success(reservation))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}
