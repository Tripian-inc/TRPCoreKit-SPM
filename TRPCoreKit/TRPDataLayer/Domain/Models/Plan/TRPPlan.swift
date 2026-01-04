//
//  TRPPlan.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 5.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public struct TRPPlan: Codable {
    
    public var id: Int
    
    public var date: String
    
    public var startTime: String?
    
    public var endTime: String?
    
    public var steps: [TRPStep]
    
    public var generatedStatus: Int
    
    public var statusMessage: String?
    
    
    func getPoi() -> [TRPPoi] {
        return steps.map({$0.poi})
    }
    
    
    
}

extension TRPPlan: Equatable {

    public static func == (lhs: TRPPlan, rhs: TRPPlan) -> Bool {
        lhs.id == rhs.id
    }

}
