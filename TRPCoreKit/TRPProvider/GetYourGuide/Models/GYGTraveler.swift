//
//  GYGTraveler.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 2020-12-26.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

// MARK: - Traveler
public struct GYGTraveler: Codable {
    
    
    public let salutationCode, firstName, lastName, email: String
    public let phoneNumber: String
    
    enum CodingKeys: String, CodingKey {
        case salutationCode = "salutation_code"
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case phoneNumber = "phone_number"
    }
    
    public init(salutationCode: String, firstName: String, lastName: String, email: String, phoneNumber: String) {
        self.salutationCode = salutationCode
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phoneNumber = phoneNumber
    }
    
    public init(billing: GYGBilling) {
        self.salutationCode = billing.salutationCode ?? ""
        self.firstName = billing.firstName
        self.lastName = billing.lastName
        self.email = billing.email
        self.phoneNumber = billing.phoneNumber
    }
    
}
