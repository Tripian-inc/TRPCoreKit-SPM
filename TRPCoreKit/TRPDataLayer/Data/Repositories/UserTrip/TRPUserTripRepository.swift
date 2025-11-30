//
//  TRPUserTripRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
final public class TRPUserTripRepository: UserTripRepository {
    
    public var upcomingTrips: ValueObserver<[TRPUserTrip]> = .init([])
    public var pastTrips: ValueObserver<[TRPUserTrip]> = .init([])
    
    
    private var remoteApi: UserTripRemoteApi
    private var localStorage: UserTripLocalStorage
    
    
    public init(remoteApi: UserTripRemoteApi = TRPUserTripRemoteApi(),
                localStorage: UserTripLocalStorage = TRPUserTripLocalStorage() ) {
        
        self.remoteApi = remoteApi
        self.localStorage = localStorage
    }
    
    public func fetchTrip(to: String, completion: @escaping (UserTripResultsValue) -> Void) {
        remoteApi.fetchTrip(to: to, completion: completion)
    }
    
    public func fetchTrip(from: String, completion: @escaping (UserTripResultsValue) -> Void) {
        remoteApi.fetchTrip(from: from, completion: completion)
    }
    
    public func deleteTrip(tripHash hash: String, completion: @escaping (UserTripDeleteResult) -> Void) {
        remoteApi.deleteTrip(tripHash: hash, completion: completion)
    }
    
    public func fetchLocalTrip(completion: @escaping (UserTripResultsValue) -> Void) {
        localStorage.fetchMYTrip(completion: completion)
    }
    
}
