//
//  GYGBookingsParser.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 2020-12-08.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
// MARK: - GYGBookingsParser
struct GYGBookingsParser: Codable {
    let bookings: GYGBookings
}

// MARK: - Bookings
public struct GYGBookings: Codable {
    public let shoppingCartID: Int
    public let shoppingCartHash: String
    public let bookingID: Int
    public let bookingHash, status: String
    public let returnCode: Int

    enum CodingKeys: String, CodingKey {
        case shoppingCartID = "shopping_cart_id"
        case shoppingCartHash = "shopping_cart_hash"
        case bookingID = "booking_id"
        case bookingHash = "booking_hash"
        case status
        case returnCode = "return_code"
    }
}
