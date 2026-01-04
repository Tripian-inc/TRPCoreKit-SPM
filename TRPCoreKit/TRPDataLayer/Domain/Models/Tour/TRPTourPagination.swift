//
//  TRPTourPagination.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 27.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation

public struct TRPTourPagination: Hashable {
    /// Total number of results
    public let total: Int
    /// Limit per page
    public let limit: Int
    /// Current offset
    public let offset: Int

    public init(total: Int, limit: Int, offset: Int) {
        self.total = total
        self.limit = limit
        self.offset = offset
    }

    /// Check if there are more results to load
    public var hasMore: Bool {
        return limit <= total
    }

    /// Get next offset for pagination
    public var nextOffset: Int? {
        guard hasMore else { return nil }
        return offset + limit
    }
}
