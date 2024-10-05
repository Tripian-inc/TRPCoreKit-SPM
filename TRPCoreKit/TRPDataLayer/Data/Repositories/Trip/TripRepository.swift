//
//  TripRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 5.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public typealias TripResultValue = (Result<TRPTrip, Error>)

public typealias TripResultStatus = (Result<Bool, Error>)


public protocol TripRepository {
    func fetchTrip(tripHash: String, completion: @escaping (TripResultValue) -> Void)
    
    func createTrip(profile: TRPTripProfile, completion: @escaping (TripResultValue) -> Void)
    
    func editTrip(profile: TRPEditTripProfile, completion: @escaping (TripResultValue) -> Void)
    
    func deleteTrip(tripHash: String, completion: @escaping (TripResultStatus) -> Void)
    
    func fetchLocalTrip(tripHash: String, completion: @escaping (TripResultValue) -> Void)
    
    func saveTrip(tripHash: String, data: TRPTrip) 
}

