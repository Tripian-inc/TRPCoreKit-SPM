//
//  TRPUserTrip.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public struct TRPUserTrip {
    
    public var id: Int
    
    public var tripHash: String
    public var tripType: Int?
    
    public var tripProfile: TRPTripProfile
    public var cruise: TRPUserTripCruise?
    
    public var city: TRPCity
    
}

public struct TRPUserTripCruise {
    
    public var cruiseId: Int?
    
    public var cruiseName: String?
}
