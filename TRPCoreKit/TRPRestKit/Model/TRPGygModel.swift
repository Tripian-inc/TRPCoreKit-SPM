//
//  TRPGygModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 2020-12-30.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation

public struct TRPGygInfoModel: Codable {
    
    public init(tourName: String,
                tourId: Int,
                image: String? = nil,
                optionId: Int,
                dateTime: String,
                people: String?,
                bookingHash: String,
                shoppingCartHash: String? = nil,
                shoppingCartId: String? = nil,
                status: String? = nil) {
        self.tourName = tourName
        self.tourId = tourId
        self.image = image
        self.optionId = optionId
        self.dateTime = dateTime
        self.bookingHash = bookingHash
        self.shoppingCartHash = shoppingCartHash
        self.shoppingCartId = shoppingCartId
        self.status = status
        self.people = people
    }
    
    public var tourName: String
    public var tourId: Int
    public var image: String?
    public var optionId: Int
    public var dateTime: String
    public var bookingHash: String
    public var shoppingCartHash: String?
    public var shoppingCartId: String?
    public var status: String?
    public var people: String?
    
    enum CodingKeys: String, CodingKey {
        case tourName = "tour_name"
        case tourId = "tour_id"
        case image
        case optionId = "option_id"
        case dateTime = "date_time"
        case bookingHash = "booking_hash"
        case shoppingCartHash = "shopping_cart_hash"
        case shoppingCartId = "shopping_cart_id"
        case status
        case people
    }
    
    public func getParams() -> [String: Any] {
        var params = [String: Any]()
        params[CodingKeys.tourName.rawValue] = tourName
        params[CodingKeys.tourId.rawValue] = tourId
        params[CodingKeys.image.rawValue] = image
        params[CodingKeys.optionId.rawValue] = optionId
        params[CodingKeys.dateTime.rawValue] = dateTime
        params[CodingKeys.bookingHash.rawValue] = bookingHash
        params[CodingKeys.shoppingCartHash.rawValue] = shoppingCartHash
        params[CodingKeys.shoppingCartId.rawValue] = shoppingCartId
        params[CodingKeys.status.rawValue] = status
        params[CodingKeys.people.rawValue] = people
        return params
    }
    
}
