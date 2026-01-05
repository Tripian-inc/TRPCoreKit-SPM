//
//  TRPTripRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 5.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

public class TRPTripRemoteApi: TripRemoteApi {
    
    public init() {}
    
    public func createTrip(profile: TRPTripProfile, completion: @escaping (TripResultValue) -> Void) {
        
        guard let tripSettings = TripProfileMapper().makeTripSettings(profile: profile) else { return }
        
        TRPRestKit().createTrip(settings: tripSettings) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let result = result as? TRPTripModel, let converted = TripMapper().map(result) {
                completion(.success(converted))
            }
        }
    }
    
    public func editTrip(profile: TRPEditTripProfile, completion: @escaping (TripResultValue) -> Void) {
        
        guard let tripSetting = TripProfileMapper().makeTripSettings(editTripProfile: profile, tripHash: profile.tripHash) else {return}
        
        TRPRestKit().editTrip(settings: tripSetting) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let result = result as? TRPTripModel, let converted = TripMapper().map(result) {
                completion(.success(converted))
            }
        }
    }
    
    public func fetchTrip(tripHash: String, completion: @escaping (TripResultValue) -> Void) {
        TRPRestKit().getTrip(withHash: tripHash) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let result = result as? TRPTripModel, let converted = TripMapper().map(result) {
                completion(.success(converted))
            }
        }
    }
    
    public func deleteTrip(tripHash: String, completion: @escaping (TripResultStatus) -> Void) {
        TRPRestKit().deleteTrip(hash: tripHash) { (result, error) in
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
