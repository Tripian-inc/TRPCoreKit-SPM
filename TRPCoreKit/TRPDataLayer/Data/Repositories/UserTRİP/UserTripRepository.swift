//
//  UserTripRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public typealias UserTripResultsValue = (Result<[TRPUserTrip], Error>)
public typealias UserTripDeleteResult = (Result<Bool, Error>)

public protocol UserTripRepository {
    
    var upcomingTrips: ValueObserver<[TRPUserTrip]> {get set}
    
    var pastTrips: ValueObserver<[TRPUserTrip]> {get set}
    
    func fetchTrip(to: String,
                   completion: @escaping (UserTripResultsValue) -> Void)
    
    func fetchTrip(from: String,
                   completion: @escaping (UserTripResultsValue) -> Void)
    
    func deleteTrip(tripHash hash: String,
                    completion: @escaping (UserTripDeleteResult) -> Void)
    
    func fetchLocalTrip(completion: @escaping (UserTripResultsValue) -> Void)
}
