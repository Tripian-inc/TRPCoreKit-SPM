//
//  Pagination.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 25.05.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation

/// Indicates status of page that about request
///
/// - continues: pages have shown yet.
/// - completed: request is completed. Pages were showed.
public enum Pagination {
    // Pages have shown yet. Value is a link
    case continues(String)
    // request is completed. Pages were showed.
    case completed
}

extension Pagination: Equatable {

    /// Compare to pagination objec
    public static func == (lhs: Pagination, rhs: Pagination) -> Bool {
        
        switch (lhs, rhs) {
        case (.completed, .completed):
            return true
        case (.continues, .continues):
            return true
        default:
            return false
        }
        
    }
}
