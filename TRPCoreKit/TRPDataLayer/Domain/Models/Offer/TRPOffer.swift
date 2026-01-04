//
//  TRPOffer.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 9.08.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation

public struct TRPOffer: Codable {
    public var id: Int
    public var poiId: String = ""
    public var businessId: Int = 0
    public var title: String = ""
    public var description:  String?
    public var currency: OfferCurrencyType = .usd
    public var caption: String = ""
    public var productName: String = ""
    public var threshold: Double = 0
    public var discount: Double = 0
    public var discountedProductCount: Int = 0
    public var quantity: Int = 0
    public var timeframe: TRPOfferTimeFrame?
    public var imageUrl: String?
    public var productType: TRPOfferProductType?
    public var offerType: OfferType = .quantity
    public var usage: Int = 0
//    var tags: String?
    public var optIn: Bool = false
    public var optInClaimDate: String = ""
    public var status: OfferStatus = .active
    
    public init(offerId: Int) {
        self.id = offerId
    }
}

public enum OfferCurrencyType: String, Codable {
    case usd = "USD"
    case cad = "CAD"
}

public enum OfferType: String, Codable {
    case percentage
    case amount
    case quantity
}

public enum OfferStatus: String, Codable {
    case active
    case inactive
    case archive
}
