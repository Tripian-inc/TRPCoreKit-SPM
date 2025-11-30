//
//  TRPGooglePlaceLocation.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 5.02.2019.
//  Copyright © 2019 Evren Yaşar. All rights reserved.
//

import Foundation


/// This model provides you to use information of Place
public struct TRPGooglePlaceLocation {
    
    /// A String value. Id of place
    public var id: String
    /// A TRPLocation object. Center location of place.
    public var location: TRPLocation
    /// A String value. Address of Hotel.
    public var hotelAddress: String
    
    public var name: String?
    
}
