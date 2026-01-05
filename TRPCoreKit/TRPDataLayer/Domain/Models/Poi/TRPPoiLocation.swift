//
//  TRPPoiLocation.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation

public struct TRPPoiLocation: Codable, Hashable {
    public let id: Int
    public let name: String
    public let locationType: String
    public let country: String
    public let continent: String
    
    public init(id: Int,
                name: String,
                locationType: String,
                country: String,
                continent: String) {
        self.id = id
        self.name = name
        self.locationType = locationType
        self.country = country
        self.continent = continent
    }
}
