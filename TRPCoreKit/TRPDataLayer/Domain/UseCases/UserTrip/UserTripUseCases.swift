//
//  UserTripUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public protocol FetchUserUpcomingTripUseCase {
    
    func executeUpcomingTrip(completion: ((Result<[TRPUserTrip], Error>) -> Void)? )
}

public protocol FetchUserPastTripUseCase {
    
    func executePastTrip(completion: ((Result<[TRPUserTrip], Error>) -> Void)? )
}

public protocol DeleteUserTripUseCase {
    
    func executeDeleteTrip(tripHash: String, completion: ((Result<Bool, Error>) -> Void)? )
}

public protocol ObserveUserUpcomingTripsUseCase {
    
    var upcomingTrips: ValueObserver<[TRPUserTrip]> { get }
}

public protocol ObserveUserPastTripsUseCase {
    
    var pastTrips: ValueObserver<[TRPUserTrip]> { get }
}

