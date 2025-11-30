//
//  TRPReservationRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 25.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

final public class TRPReservationRemoteApi: ReservationRemoteApi {
    
    
    public init() {}
    
    public func fetchReservation(cityId: Int, from: String?, to: String?, provider: String?, completion: @escaping (ReservationResultsValue) -> Void) {
        TRPRestKit().getUserReservation(cityId: cityId, from: from, to: to, provider: provider, limit: 99) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let result = result as? [TRPReservationInfoModel] {
                let converted = ReservationMapper().map(result)
                completion(.success(converted))
            }
        }
    }
    
    public func addReservation(key: String, provider: String, tripHash: String?, poiId: String?, value: [String : Any]?, completion: @escaping (ReservationResultValue) -> Void) {
        TRPRestKit().addUserReservation(key: key, provider: provider, tripHash: tripHash, poiId: poiId, value: value) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let result = result as? TRPReservationInfoModel {
                let converted = ReservationMapper().map(result)
                completion(.success(converted))
            }
        }
    }
    
    public func updateReservation(id: Int, key: String, provider: String, tripHash: String?, poiId: String?, value: [String : Any]?, completion: @escaping (ReservationResultValue) -> Void) {
        //TRPRestKit().userReser
        
        TRPRestKit().updateUserReservation(id: id, key: key, provider: provider, tripHash: tripHash, poiId: poiId, value: value) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let result = result as? TRPReservationInfoModel {
                let converted = ReservationMapper().map(result)
                completion(.success(converted))
            }
        }
    }
    
    public func deleteReservation(id: Int, completion: @escaping (ReservationResultStatus) -> Void) {
        TRPRestKit().deleteUserReservation(id: id) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let result = result as? TRPParentJsonModel {
                
                completion(.success(result.success))
            }
        }
    }
    
    
    
    
}
