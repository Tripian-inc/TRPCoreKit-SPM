//
//  TRPPagination.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 18.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public enum TRPPagination {
    
    // Pages have shown yet. Value is a link
    case continues(String)
    // request is completed. Pages were showed.
    case completed
}

extension TRPPagination: Hashable {
    
    public var hashValue: Int {
        return rawValue.hashValue
    }
    
    public static func == (lhs: TRPPagination, rhs: TRPPagination) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    private var rawValue : String {
        let value : String
        switch self {
        case .completed:
            value = "completed"
        case .continues(let url):
            value = url
        }
        return value
    }
    
}
