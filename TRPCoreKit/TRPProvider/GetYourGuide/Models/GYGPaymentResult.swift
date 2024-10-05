//
//  GYGPaymentResult.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 2020-12-26.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public struct GYGPaymentResult: Codable {
    
    public let status: String
    public let billing: GYGBilling?
    public let shoppingCartHash: String?
    public let traveler: GYGTraveler?
    public let bookings: [GYGPaymentBooking]?
    public let shoppingCartID: Int?
    public let paymentInfo: GYGPaymentInfo?
    public var tourName: String?
    public var tourImage: String?
    public var cityName: String?
    
    enum CodingKeys: String, CodingKey {
        case status, billing
        case shoppingCartHash = "shopping_cart_hash"
        case traveler, bookings
        case shoppingCartID = "shopping_cart_id"
        case paymentInfo = "payment_info"
        case tourName = "tour_name"
        case tourImage = "tour_image"
        case cityName = "city_name"
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try values.decode(String.self, forKey: .status)
        self.shoppingCartHash = try values.decode(String.self, forKey: .shoppingCartHash)
        self.shoppingCartID = try values.decode(Int.self, forKey: .shoppingCartID)
        
        if let billing = try? values.decodeIfPresent(GYGBilling.self, forKey: .billing) {
            self.billing = billing
        }else {
            self.billing = nil
        }
        
        if let traveller = try? values.decodeIfPresent(GYGTraveler.self, forKey: .traveler) {
            traveler = traveller
        }else {
            traveler = nil
        }
        
        if let bookings = try? values.decodeIfPresent([GYGPaymentBooking].self, forKey: .bookings) {
            self.bookings = bookings
        }else {
            self.bookings = []
        }
        
        if let paymentInfo = try? values.decodeIfPresent(GYGPaymentInfo?.self, forKey: .paymentInfo) {
            self.paymentInfo = paymentInfo
        }else {
            self.paymentInfo = nil
        }
        tourName = try values.decodeIfPresent(String.self, forKey: .tourName)
    }
    
 
    
}

public struct GYGPaymentInfo: Codable {
    public let paymentMethod: String?
    public let precouponPrice, totalPrice: Double
    public let paymentCurrency, invoiceReference: String?

    enum CodingKeys: String, CodingKey {
        case paymentMethod = "payment_method"
        case precouponPrice = "precoupon_price"
        case totalPrice = "total_price"
        case paymentCurrency = "payment_currency"
        case invoiceReference = "invoice_reference"
    }
}


public struct GYGPaymentBooking: Codable {
    public let bookable: GYGBookable?
    public let bookingID: Int?
    public let shoppingCartHash: String?
    public let ticket: GYGTicket?
    public let bookingStatus, bookingHash: String?
    public let shoppingCartID: Int?

    enum CodingKeys: String, CodingKey {
        case bookable
        case bookingID = "booking_id"
        case shoppingCartHash = "shopping_cart_hash"
        case ticket
        case bookingStatus = "booking_status"
        case bookingHash = "booking_hash"
        case shoppingCartID = "shopping_cart_id"
    }
}

// MARK: - Bookable
public struct GYGBookable: Codable {
    public let datetimeType: String?
    public let tourID: Int?
    public let datetime: String?
    public let price: Double?
    public let categories: [GYGCategory]?
    public let cancellationPolicyText, validUntil: String?
    public let datetimeUTC: String?
    public let bookingParameters: [GYGBookingParameter]?
    public let optionID: Int?

    enum CodingKeys: String, CodingKey {
        case datetimeType = "datetime_type"
        case tourID = "tour_id"
        case datetime, price, categories
        case cancellationPolicyText = "cancellation_policy_text"
        case validUntil = "valid_until"
        case datetimeUTC = "datetime_utc"
        case bookingParameters = "booking_parameters"
        case optionID = "option_id"
    }
}

public struct GYGTicket: Codable {
    public let bookingReference, voucherInformation, emergencyPhoneNumber, ticketHash: String?
    public let emergencyEmail: String?
    public let supplierBookingCodes: [GYGSupplierBookingCode]?
    public let ticketURL: String?

    enum CodingKeys: String, CodingKey {
        case bookingReference = "booking_reference"
        case voucherInformation = "voucher_information"
        case emergencyPhoneNumber = "emergency_phone_number"
        case ticketHash = "ticket_hash"
        case emergencyEmail = "emergency_email"
        case supplierBookingCodes = "supplier_booking_codes"
        case ticketURL = "ticket_url"
    }
}

// MARK: - SupplierBookingCode
public struct GYGSupplierBookingCode: Codable {
    public let code, ticketHash, label, type: String?

    enum CodingKeys: String, CodingKey {
        case code
        case ticketHash = "ticket_hash"
        case label, type
    }
}
