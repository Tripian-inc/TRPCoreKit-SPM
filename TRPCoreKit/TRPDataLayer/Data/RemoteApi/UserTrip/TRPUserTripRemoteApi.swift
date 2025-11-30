//
//  TRPUserTripRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

final public class TRPUserTripRemoteApi: UserTripRemoteApi {
    
    
    

    public init() {}
    
    public func fetchTrip(to: String, completion: @escaping (UserTripResultsValue) -> Void) {
        TRPRestKit().userTrips(to: to) { (result, error, pagination) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let result = result as? [TRPUserTripInfoModel] {
                let converted = UserTripMapper().map(result)
                completion(.success(converted))
            }
        }
    }
    
    public func fetchTrip(from: String, completion: @escaping (UserTripResultsValue) -> Void) {
        TRPRestKit().userTrips(from: from) { (result, error, pagination) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let result = result as? [TRPUserTripInfoModel] {
                let converted = UserTripMapper().map(result)
                completion(.success(converted))
            }
        }
    }
    
    
    public func deleteTrip(tripHash: String, completion: @escaping (UserTripDeleteResult) -> Void) {
        TRPRestKit().deleteTrip(hash: tripHash) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let _ = result as? TRPDeleteUserTripInfo {
                completion(.success(true))
            }
        }
    }
}
