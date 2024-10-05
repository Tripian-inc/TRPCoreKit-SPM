//
//  TRPTripRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 6.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
final public class TRPTripRepository: TripRepository {
    
    private(set) var remoteApi: TripRemoteApi
    
    private(set) var localStorage: TripLocalStorage
    
    public init(remoteApi: TripRemoteApi = TRPTripRemoteApi(),
                localStorage: TripLocalStorage = TRPTripLocalStorage()) {
        self.remoteApi = remoteApi
        self.localStorage = localStorage
    }
    
    public func fetchTrip(tripHash: String, completion: @escaping (TripResultValue) -> Void) {
        remoteApi.fetchTrip(tripHash: tripHash, completion: completion)
    }
    
    public func createTrip(profile: TRPTripProfile, completion: @escaping (TripResultValue) -> Void) {
        remoteApi.createTrip(profile: profile, completion: completion)
    }
    
    public func editTrip(profile: TRPEditTripProfile, completion: @escaping (TripResultValue) -> Void) {
        remoteApi.editTrip(profile: profile, completion: completion)
    }
    
    public func deleteTrip(tripHash: String, completion: @escaping (TripResultStatus) -> Void) {
        remoteApi.deleteTrip(tripHash: tripHash, completion: completion)
    }
    
    public func fetchLocalTrip(tripHash: String, completion: @escaping (TripResultValue) -> Void) {
        localStorage.fetchTrip(tripHash: tripHash, completion: completion)
    }
    
    public func saveTrip(tripHash: String, data: TRPTrip) {
        localStorage.saveTrip(tripHash: tripHash, data: data)
    }
}
