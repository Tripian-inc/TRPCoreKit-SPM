//
//  TRPStep.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 5.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public struct TRPHour: Codable {
    
    public var from: String?
    
    public var to: String?
}


public struct TRPStep: Codable {
    
    public var id: Int
    
    public var planId: Int?
    
    public var poi: TRPPoi
    
    public var order: Int = 0
    
    public var score: Float?
    
    public var times: TRPHour?
    
    public var alternatives: [String]
    
}

extension TRPStep: Equatable {
    
    public static func == (lhs: TRPStep, rhs: TRPStep) -> Bool {
        return lhs.id == rhs.id
    }
    
}

extension TRPStep {
    public func isHotelPoi() -> Bool {
        return poi.placeType == .hotel
    }
}
