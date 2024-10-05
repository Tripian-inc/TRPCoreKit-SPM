//
//  TripUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public protocol FetchTripUseCase {
    
    func executeFetchTrip(tripHash: String, completion: ((Result<TRPTrip, Error>) -> Void)?)
       
    
}


public protocol CreateTripUseCase {
    
    func executeCreateTrip(profile: TRPTripProfile, completion: ((Result<TRPTrip, Error>) -> Void)?)
    
}

public protocol EditTripUseCase {
    
    func executeEditTrip(profile: TRPEditTripProfile, completion: ((Result<TRPTrip, Error>) -> Void)?)
    
    func doNotGenerate(newProfile: TRPTripProfile) -> Bool
}

