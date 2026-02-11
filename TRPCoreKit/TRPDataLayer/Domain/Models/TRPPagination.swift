//
//  TRPPagination.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 18.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

/// Pagination info from API response
public struct TRPPaginationInfo {
    public let total: Int
    public let count: Int
    public let perPage: Int
    public let currentPage: Int
    public let totalPages: Int

    public init(total: Int = 0, count: Int = 0, perPage: Int = 0, currentPage: Int = 0, totalPages: Int = 0) {
        self.total = total
        self.count = count
        self.perPage = perPage
        self.currentPage = currentPage
        self.totalPages = totalPages
    }

    public var hasMore: Bool {
        return currentPage < totalPages
    }
}

public enum TRPPagination {

    // Pages have shown yet. Value contains pagination info
    case continues(TRPPaginationInfo)
    // request is completed. Pages were showed.
    case completed
}

extension TRPPagination: Hashable {

    public static func == (lhs: TRPPagination, rhs: TRPPagination) -> Bool {
        switch (lhs, rhs) {
        case (.completed, .completed):
            return true
        case (.continues, .continues):
            return true
        default:
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .completed:
            hasher.combine("completed")
        case .continues(let info):
            hasher.combine("continues")
            hasher.combine(info.currentPage)
        }
    }
}
