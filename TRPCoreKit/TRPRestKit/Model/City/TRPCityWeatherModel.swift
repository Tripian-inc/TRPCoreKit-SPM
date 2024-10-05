//
//  TRPCityWeatherModel.swift
//  TRPRestKit
//
//  Created by Cem Çaygöz on 16.04.2024.
//  Copyright © 2024 Evren Yaşar. All rights reserved.
//

import Foundation

public class TRPCityWeatherModel: NSObject, Decodable {
    
    
    public var date: String?
    public var maxTempC: Double?
    public var minTempC: Double?
    public var maxTempF: Double?
    public var minTempF: Double?
    public var weatherIcon: String?
    public var weatherText: String?
    
    
    /// Tag matcher
    private enum CodingKeys: String, CodingKey {
        case date
        case maxTempC
        case minTempC
        case maxTempF
        case minTempF
        case weatherIcon
        case weatherText
    }
    
}
