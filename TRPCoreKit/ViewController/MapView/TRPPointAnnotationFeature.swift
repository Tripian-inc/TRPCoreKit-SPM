//
//  TRPPointAnnotationFeature.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 18.09.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation
public struct TRPPointAnnotationFeature {
    var id: String
    var name: String
    var lat: Double
    var lon: Double
    var iconType: String
    
    public init(id: String, name: String, lat: Double, lon: Double, iconType: String) {
        self.id = id
        self.name = name
        self.lat = lat
        self.lon = lon
        self.iconType = iconType
    }
}
