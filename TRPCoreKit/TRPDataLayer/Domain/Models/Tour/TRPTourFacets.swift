//
//  TRPTourFacets.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 04.05.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import Foundation

public struct TRPTourFacets: Hashable {
    public let categories: [TRPTourCategoryFacet]
    public let priceRange: TRPTourPriceRangeFacet?
    public let durationRange: TRPTourDurationRangeFacet?

    public init(categories: [TRPTourCategoryFacet],
                priceRange: TRPTourPriceRangeFacet?,
                durationRange: TRPTourDurationRangeFacet?) {
        self.categories = categories
        self.priceRange = priceRange
        self.durationRange = durationRange
    }
}

public struct TRPTourCategoryFacet: Hashable {
    public let id: String
    public let key: String?
    public let label: String
    public let count: Int

    public init(id: String, key: String?, label: String, count: Int) {
        self.id = id
        self.key = key
        self.label = label
        self.count = count
    }
}

public struct TRPTourPriceRangeFacet: Hashable {
    public let minAmount: Double
    public let maxAmount: Double
    public let currency: String

    public init(minAmount: Double, maxAmount: Double, currency: String) {
        self.minAmount = minAmount
        self.maxAmount = maxAmount
        self.currency = currency
    }
}

public struct TRPTourDurationRangeFacet: Hashable {
    public let minMinutes: Int
    public let maxMinutes: Int

    public init(minMinutes: Int, maxMinutes: Int) {
        self.minMinutes = minMinutes
        self.maxMinutes = maxMinutes
    }
}

public struct TRPTourSearchOutcome {
    public let products: [TRPTourProduct]
    public let facets: TRPTourFacets?

    public init(products: [TRPTourProduct], facets: TRPTourFacets?) {
        self.products = products
        self.facets = facets
    }
}
