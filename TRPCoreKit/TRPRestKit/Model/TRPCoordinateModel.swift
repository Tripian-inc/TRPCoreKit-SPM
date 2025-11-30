//
//  TRPCoordinateModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 25.05.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation

/// Includes information about the coordination system
public struct TRPCoordinateModel: Decodable {
    
    /// latitude
    public var lat: Double
    /// longitude
    public var lon: Double
    
    private enum CodingKeys: String, CodingKey {
        case lat
        case lon = "lng"
    }
    
    /// Initializes a new object with decoder
    ///
    /// - Parameter decoder: Json decoder
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        lat = try values.decode(Double.self, forKey: .lat)
        lon = try values.decode(Double.self, forKey: .lon)
    }
}
