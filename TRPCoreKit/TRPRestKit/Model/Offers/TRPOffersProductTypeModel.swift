//
//  TRPOffersProductTypeModel.swift
//  TRPRestKit
//
//  Created by Cem Çaygöz on 9.08.2022.
//  Copyright © 2022 Evren Yaşar. All rights reserved.
//

import Foundation

public struct TRPOffersProductTypeModel: Decodable {
    public var id: Int
    public var name: String
    public var receiveMethod: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case receiveMethod
    }
}
