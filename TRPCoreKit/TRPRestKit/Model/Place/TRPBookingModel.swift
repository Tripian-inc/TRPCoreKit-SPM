//
//  TRPBookingModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 26.02.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation
public struct TRPBookingInfoModel: Decodable {
    
    public var providerId: Int?
    public var providerName: String?
    public var products: [TRPBookingProductInfoModel]?
    
    private enum CodingKeys: String, CodingKey {
        case providerId = "providerId"
        case providerName = "providerName"
        case products
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        providerId = try values.decodeIfPresent(Int.self, forKey: .providerId)
        providerName = try values.decodeIfPresent(String.self, forKey: .providerName)
        products = try values.decodeIfPresent([TRPBookingProductInfoModel].self, forKey: .products)
        
    }
}

public struct TRPBookingProductInfoModel: Decodable {

    public var id: String?
    
    public var title: String?
    
    public var currency: String?
    
    public var price: Float?
    
    public var priceDescription: String?
    
    public var image: String?
    
    public var rating: Float?
    
    public var ratingCount: Int?
    
    public var duration: String?
    
    public var info: [String]?
    
    public var url: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case currency
        case price
        case priceDescription = "price_description"
        case image
        case rating
        case ratingCount = "rating_count"
        case duration
        case info
        case url
    }
    
}
