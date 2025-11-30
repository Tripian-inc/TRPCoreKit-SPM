//
//  TRPGygModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 2020-12-30.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation

//public struct TRPGygInfoModel: Codable {
//    
//    public let data: TRPGYGDataModel?
//    
//}

// MARK: - DataClass
public struct TRPGYGDataModel: Codable {
    public let shoppingCart: TRPGygShoppingCart?

    enum CodingKeys: String, CodingKey {
        case shoppingCart = "shopping_cart"
    }
}



public struct TRPGygShoppingCart: Codable {
    public let status: String?
    public let billing: Billing?
    public let shoppingCartHash: String?
    public let bookings: [Booking]?
    public let traveler: Traveler?
    public let shoppingCartID: Int?
    public let paymentInfo: PaymentInfo?
    public var tourName: String?
    public var tourImage: String?
    public var cityName: String?
    
    enum CodingKeys: String, CodingKey {
        case status, billing
        case shoppingCartHash = "shopping_cart_hash"
        case bookings, traveler
        case shoppingCartID = "shopping_cart_id"
        case paymentInfo = "payment_info"
        case tourName = "tour_name"
        case tourImage = "tour_image"
        case cityName = "city_name"
    }
}

// MARK: - Billing
public struct Billing: Codable {
    public let state, email: String?
    public let isCompany: Bool?
    public let salutationCode, phoneNumber, addressLine2, companyName: String?
    public let firstName, city, postalCode: String?
    public let invoice: Bool?
    public let lastName, addressLine1, countryCode: String?

    enum CodingKeys: String, CodingKey {
        case state, email
        case isCompany = "is_company"
        case salutationCode = "salutation_code"
        case phoneNumber = "phone_number"
        case addressLine2 = "address_line_2"
        case companyName = "company_name"
        case firstName = "first_name"
        case city
        case postalCode = "postal_code"
        case invoice
        case lastName = "last_name"
        case addressLine1 = "address_line_1"
        case countryCode = "country_code"
    }
}

// MARK: - Booking
public struct Booking: Codable {
    public let ticket: Ticket?
    public let bookingID: Int?
    public let shoppingCartHash: String?
    public let bookable: Bookable?
    public let bookingStatus, bookingHash: String?
    public let shoppingCartID: Int?

    enum CodingKeys: String, CodingKey {
        case ticket
        case bookingID = "booking_id"
        case shoppingCartHash = "shopping_cart_hash"
        case bookable
        case bookingStatus = "booking_status"
        case bookingHash = "booking_hash"
        case shoppingCartID = "shopping_cart_id"
    }
}

// MARK: - Bookable
public struct Bookable: Codable {
    public let datetimeType: String?
    public let categories: [Category]?
    public let price: Double?
    public let tourID: Int?
    public let cancellationPolicyText, datetime, validUntil: String?
    public let datetimeUTC: String?
    public let bookingParameters: [BookingParameter]?
    public let optionID: Int?

    enum CodingKeys: String, CodingKey {
        case datetimeType = "datetime_type"
        case categories, price
        case tourID = "tour_id"
        case cancellationPolicyText = "cancellation_policy_text"
        case datetime
        case validUntil = "valid_until"
        case datetimeUTC = "datetime_utc"
        case bookingParameters = "booking_parameters"
        case optionID = "option_id"
    }
}

// MARK: - BookingParameter
public struct BookingParameter: Codable {
    public let name: String?
}

// MARK: - Category
public struct Category: Codable {
    public let name: String?
    public let categoryID, numberOfParticipants: Int?

    enum CodingKeys: String, CodingKey {
        case name
        case categoryID = "category_id"
        case numberOfParticipants = "number_of_participants"
    }
}

// MARK: - Ticket
public struct Ticket: Codable {
    public let bookingReference, voucherInformation, emergencyPhoneNumber, ticketHash: String?
    public let emergencyEmail: String?
    public let ticketURL: String?
    public let supplierBookingCodes: [SupplierBookingCode]?

    enum CodingKeys: String, CodingKey {
        case bookingReference = "booking_reference"
        case voucherInformation = "voucher_information"
        case emergencyPhoneNumber = "emergency_phone_number"
        case ticketHash = "ticket_hash"
        case emergencyEmail = "emergency_email"
        case ticketURL = "ticket_url"
        case supplierBookingCodes = "supplier_booking_codes"
    }
}

// MARK: - SupplierBookingCode
public struct SupplierBookingCode: Codable {
    public let code, ticketHash, label, type: String?

    enum CodingKeys: String, CodingKey {
        case code
        case ticketHash = "ticket_hash"
        case label, type
    }
}

// MARK: - PaymentInfo
public struct PaymentInfo: Codable {
    public let paymentMethod: String?
    public  let precouponPrice, totalPrice: Double?
    public let paymentCurrency, invoiceReference: String?

    enum CodingKeys: String, CodingKey {
        case paymentMethod = "payment_method"
        case precouponPrice = "precoupon_price"
        case totalPrice = "total_price"
        case paymentCurrency = "payment_currency"
        case invoiceReference = "invoice_reference"
    }
}

// MARK: - Traveler
public struct Traveler: Codable {
    public let salutationCode, email, lastName, phoneNumber: String?
    public let firstName: String?

    enum CodingKeys: String, CodingKey {
        case salutationCode = "salutation_code"
        case email
        case lastName = "last_name"
        case phoneNumber = "phone_number"
        case firstName = "first_name"
    }
}
