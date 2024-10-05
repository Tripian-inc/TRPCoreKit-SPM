//
//  UserTripRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol UserTripRemoteApi {
    
    func fetchTrip(to: String,
                   completion: @escaping (UserTripResultsValue) -> Void)
    
    func fetchTrip(from: String,
                   completion: @escaping (UserTripResultsValue) -> Void)
    
    func deleteTrip(tripHash: String,
                   completion: @escaping (UserTripDeleteResult) -> Void)
}
