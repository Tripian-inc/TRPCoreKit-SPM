//
//  TRPBooking.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public struct TRPBooking: Codable {
    
    public var providerId: Int?
    
    public var providerName: String?
    
    public var products: [TRPBookingProduct]?
    
    public func firstProduct() -> TRPBookingProduct? {
        return products?.first
    }
}

public struct TRPBookingProduct: Codable {
    
    public var id: String
    
    public var title: String
    
    public var currency: String?
    
    public var price: Float?
    
    public var priceDescription: String?
    
    public var image: String?
    
    public var rating: Float?
    
    public var ratingCount: Int?
    
    public var duration: String?
    
    public var info: [String] = []
    
    public var url: String?
    
}
