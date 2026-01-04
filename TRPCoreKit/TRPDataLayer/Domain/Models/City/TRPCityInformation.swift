//
//  TRPCityInformation.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 4.09.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

public struct TRPCityInformationData: Codable {
    public let id: String?
    public let information: TRPCityInformation?
}

public struct TRPCityInformation: Codable {
    public let wifiInformation: TRPCityWifiInformation?
    public let lifeQualityIndices: TRPCityLifeQualityIndices?
    public let emergencyNumbers: TRPCityEmergencyNumbers?
    public let powerInformation: TRPCityPowerInformation?
    public let bestTimeToVisit: TRPCityBestTimeToVisit?
}

public struct TRPCityWifiInformation: Codable {
    public let mobile: String?
    public let broadband: String?
}

public struct TRPCityLifeQualityIndices: Codable {
    public let safetyIndex: TRPCityQualityIndex?
    public let healthCareIndex: TRPCityQualityIndex?
    public let propertyPriceToIncomeRatio: TRPCityQualityIndex?
    public let trafficCommuteTimeIndex: TRPCityQualityIndex?
    public let purchasingPowerIndex: TRPCityQualityIndex?
    public let qualityOfLifeIndex: TRPCityQualityIndex?
    public let climateIndex: TRPCityQualityIndex?
    public let pollutionIndex: TRPCityQualityIndex?
    public let costOfLivingIndex: TRPCityQualityIndex?
}

public struct TRPCityQualityIndex: Codable {
    public let rating: String?
    public let value: Double?
    
    public func getQualityText() -> String? {
        guard let rating, let value else { return nil }
        return "\(rating) - \(value)"
    }
}

public struct TRPCityEmergencyNumbers: Codable {
    public let fire: String?
    public let police: String?
    public let ambulance: String?
    public let notes: String?
}

public struct TRPCityPowerInformation: Codable {
    public let plugs: [String]?
    public let voltage: String?
    public let frequency: String?
}

public struct TRPCityBestTimeToVisit: Codable {
    public let notes: String?
    public let offSeason: TRPCitySeason?
    public let peakSeason: TRPCitySeason?
    public let shoulderSeason: TRPCitySeason?
}

public struct TRPCitySeason: Codable {
    public let description: String?
    public let months: [String]?
}
