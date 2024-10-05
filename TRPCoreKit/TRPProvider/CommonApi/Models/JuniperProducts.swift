//
//  JuniperProducts.swift
//  TRPProvider
//
//  Created by Cem Çaygöz on 25.08.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation

public class JuniperProduct: Codable {
    public let code: String
    public let destinationZone: String?
    public let end: String?
    public let hasAdditionalRequiredFields: Bool?
    public let order: Int?
    public let serviceInfo: JuniperServiceInfo?
    public let serviceOptions: [JuniperServiceOption?]?
    public let start: String?
    public let status: String?
    
    private enum CodingKeys: String, CodingKey {
        case code = "Code"
        case destinationZone = "DestinationZone"
        case end = "End"
        case hasAdditionalRequiredFields = "HasAdditionalRequiredFields"
        case order = "Order"
        case serviceInfo = "ServiceInfo"
        case serviceOptions = "ServiceOptions"
        case start = "Start"
        case status = "Status"
    }
    
    public func getImage() -> String {
        if let image = serviceInfo?.images?.first??.fileName {
            return image.replacingOccurrences(of: "upload_p", with: "upload").replacingOccurrences(of: "http://", with: "https://")
        }
        return ""
    }
    
    public func getCheapestPrice() -> String {
        var prices: [JuniperPrice] = []

        serviceOptions?.forEach { option in
            option?.dates?.forEach { date in
                date?.prices?.forEach { price in
                    if let price = price {
                        prices.append(price)
                    }
                }
            }
        }

        if !prices.isEmpty {
            if let minPrice = prices.min(by: { ($0.service ?? 0.0) < ($1.service ?? 0.0) }) {
                return "$\(String(format: "%.2f", minPrice.service ?? 0))"
            }
        }
        return ""
    }
    
    public func getProductUrl(city: String? = nil) -> String {
        if let destinationZone = destinationZone {
            let splittedCode = code.split(separator: "¬")
            if splittedCode.count > 1 {
                let encodeCode = "\(splittedCode[1])¥TKT¥\(splittedCode[0])¥\(destinationZone)¥\(code)"
                if let city = city {
                    let url = "https://www.nexustours.com/en/services/\(city)/\(encodeCode)"
                    return url
                }
            }
        }
        return ""
    }
}

public struct JuniperServiceInfo: Codable {
    public let description: String?
    public let images: [JuniperImage?]?
    public let latitude: Double?
    public let longitude: Double?
    public let name: String?
    
    private enum CodingKeys: String, CodingKey {
        case description = "Description"
        case images = "Images"
        case latitude = "Latitude"
        case longitude = "Longitude"
        case name = "Name"
    }
}

public struct JuniperImage: Codable {
    public let featured: Bool?
    public let fileName: String?
    
    private enum CodingKeys: String, CodingKey {
        case featured = "Featured"
        case fileName = "FileName"
    }
}

public struct JuniperServiceOption: Codable {
    public let childrenAllowed: Bool?
    public let code: String?
    public let dates: [JuniperDate?]?
    public let description: String?
    public let name: String?
    public let order: Int?
    
    private enum CodingKeys: String, CodingKey {
        case childrenAllowed = "ChildrenAllowed"
        case code = "Code"
        case dates = "Dates"
        case description = "Description"
        case name = "Name"
        case order = "Order"
    }
}

public struct JuniperDate: Codable {
    public let duration: Int?
    public let end: String?
    public let prices: [JuniperPrice?]?
    public let ratePlanCode: String?
    public let start: String?
    
    private enum CodingKeys: String, CodingKey {
        case duration = "Duration"
        case end = "End"
        case prices = "Prices"
        case ratePlanCode = "RatePlanCode"
        case start = "Start"
    }
}

public struct JuniperPrice: Codable {
    public let commissionAmount: Double?
    public let commissionIncluded: Bool?
    public let currency: String?
    public let gross: Double?
    public let nett: Double?
    public let service: Double?
    public let type: String?
    
    private enum CodingKeys: String, CodingKey {
        case commissionAmount = "CommissionAmount"
        case commissionIncluded = "CommissionIncluded"
        case currency = "Currency"
        case gross = "Gross"
        case nett = "Nett"
        case service = "Service"
        case type = "Type"
    }
}

public struct JuniperCityInfo: Codable {
    public let cityName: String?
    public let zoneId: Int?
}
