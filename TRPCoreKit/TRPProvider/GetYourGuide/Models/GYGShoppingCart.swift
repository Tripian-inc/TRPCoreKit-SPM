//
//  GYGShoppingCart.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 2020-12-11.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public struct GYGShoppingCart: Codable {
    public let shoppingCartID: Int
    public let billing: GYGBilling
    public let traveler: GYGTraveler
    public let payment: GYGPayment
    
    enum CodingKeys: String, CodingKey {
        case shoppingCartID = "shopping_cart_id"
        case billing, traveler, payment
    }
    
}


// MARK: - Payment
public struct GYGPayment: Codable {
    public let encryptedCreditCard: GYGEncryptedCreditCard
//    public let returnUrl: String
    
    enum CodingKeys: String, CodingKey {
        case encryptedCreditCard = "encrypted_credit_card"
//        case returnUrl = "return_url"
    }
    
    
    init(format: String = "adyen", data token: String) {
        self.encryptedCreditCard = GYGEncryptedCreditCard(format: format, data: token)
//        self.returnUrl = "http://cruisegenie.return"
    }
    
}

// MARK: - EncryptedCreditCard
public struct GYGEncryptedCreditCard: Codable {
    public let format, data: String
    
    public init(format: String, data: String){
        self.format = format
        self.data = data
    }
}
