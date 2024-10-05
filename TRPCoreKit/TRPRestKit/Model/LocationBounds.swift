//
//  LocationBounds.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 16.06.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation

public struct LocationBounds {
    public var northEast: TRPLocation
    public var southWest: TRPLocation
    
    public init(northEast: TRPLocation, southWest: TRPLocation) {
        self.northEast = northEast
        self.southWest = southWest
    }
}
