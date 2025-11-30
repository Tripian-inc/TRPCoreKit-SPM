//
//  TRPOfferResponse.swift
//  TRPRestKit
//
//  Created by Cem Çaygöz on 9.08.2022.
//  Copyright © 2022 Evren Yaşar. All rights reserved.
//

import Foundation

public struct TRPOfferInfoModel: Decodable {
    public var id: Int
    public var poiId: String
    public var businessId: Int
    public var title: String
    public var description:  String?
    public var currency: String
    public var caption: String
    public var productName: String?
    public var giftName: String?
    public var threshold: Double?
    public var discount: Double?
    public var discountedProductCount: Int?
    public var quantity: Int?
    public var timeframe: TRPOffersTimeFrameModel
    public var imageUrl: String?
    public var productType: TRPOffersProductTypeModel
    public var offerType: String?
    public var usage: Int?
    public var optIn: Bool?
    public var optInClaimDate: String?
    public var status: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case businessId
        case title
        case description
//        case originalPrice
        case discount
        case discountedProductCount
        case poiId = "tripianPoiId"
        case quantity
        case imageUrl
        case currency
        case timeframe
//        case tags
        case productType
        case caption
        case offerType
        case productName
        case usage
        case optIn
        case optInClaimDate
        case status
        case threshold
        case giftName
    }
}


public struct TRPOffersTimeFrameModel: Codable {
    public let start, end: String
}
