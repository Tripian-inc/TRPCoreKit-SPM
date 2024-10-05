//
//  GYGCard.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 2020-12-23.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public struct GYGCard {
    
    
    
    public var holderName: String?
    public var number: String?
    public var securityCode: String?
    public var expiryMonth: String?
    public var expiryYear: String?
    
    public init(holderName: String? = nil,
                  number: String? = nil,
                  securityCode: String? = nil,
                  expiryMonth: String? = nil,
                  expiryYear: String? = nil) {
        self.holderName = holderName
        self.number = number
        self.securityCode = securityCode
        self.expiryMonth = expiryMonth
        self.expiryYear = expiryYear
    }
    
}
