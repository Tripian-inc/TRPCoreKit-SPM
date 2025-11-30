//
//  TRPOfferProductType.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 9.08.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation

public struct TRPOfferProductType: Codable {
    public let id: Int
    public let name: String
    public let receiveMethod: OfferProductTypeRecieveMethod
}

public enum OfferProductTypeRecieveMethod: String, Codable {
    case takeOut = "take-out"
    case dineIn = "dine-in"
    
    public func getMethodName() -> String {
        switch self {
        case .takeOut:
            return "Take Out"
        case .dineIn:
            return "Dine In"
        } 
    }
}
