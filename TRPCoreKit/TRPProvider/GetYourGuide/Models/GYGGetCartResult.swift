//
//  GYGGetCartResult.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 2020-12-27.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public struct GYGGetCartResult: Codable {

    public let shoppingCart: GYGPaymentResult
    
    enum CodingKeys: String, CodingKey {
        case shoppingCart = "shopping_cart"
    }

}


