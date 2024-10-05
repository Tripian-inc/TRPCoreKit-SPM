//
//  TRPPace.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 6.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public enum TRPPace: String, CaseIterable, Codable {
    
    case slow = "slow"
    case normal = "normal"
    case fast = "fast"
    
    public init?(rawValue: String) {
        switch rawValue.lowercased() {
        case TRPPace.slow.rawValue:
            self = .slow
        case TRPPace.normal.rawValue:
            self = .normal
        case TRPPace.fast.rawValue:
            self = .fast
        default:
            self = .normal
        }
    }
    
    public func displayName() -> String {
        switch self {
        case .slow:
            return "Slow"
        case .normal:
            return "Moderate"
        case .fast:
            return "Packed"
        }
    }
    
    
    public func id() -> Int {
        switch self {
        case .slow:
            return 998871
        case .normal:
            return 998872
        case .fast:
            return 998873
        }
    }
}
