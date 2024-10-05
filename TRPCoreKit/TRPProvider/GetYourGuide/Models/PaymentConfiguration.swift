//
//  PaymentConfiguration.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 2020-12-10.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

// MARK: - DataClass
struct GYGPaymentConfiuration: Codable {
    let paymentMethods: [GYGPaymentMethod]

    enum CodingKeys: String, CodingKey {
        case paymentMethods = "payment_methods"
    }
}

// MARK: - PaymentMethod
public struct GYGPaymentMethod: Codable {
    public let name: String
    public let publicKey: String?
    public let brands: [GYGBrand]?

    enum CodingKeys: String, CodingKey {
        case name
        case publicKey = "public_key"
        case brands
    }
}

// MARK: - Brand
public struct GYGBrand: Codable {
    public let code: Int
    public let name: String
}
