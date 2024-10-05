//
//  TripRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 5.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol TripRemoteApi {
       
    func createTrip(profile: TRPTripProfile, completion: @escaping (TripResultValue) -> Void)
       
    func editTrip(profile: TRPEditTripProfile, completion: @escaping (TripResultValue) -> Void)
    
    func fetchTrip(tripHash: String, completion: @escaping (TripResultValue) -> Void)
    
    func deleteTrip(tripHash: String, completion: @escaping (TripResultStatus) -> Void)
       
}
