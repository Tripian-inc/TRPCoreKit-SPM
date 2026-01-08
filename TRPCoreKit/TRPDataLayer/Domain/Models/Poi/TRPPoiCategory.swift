//
//  TRPPoiCategoy.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 26.02.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import Foundation

public struct TRPPoiCategory: Codable {
    public let id: Int
    public let name: String?
    public let isCustom: Bool?
}

public struct TRPPoiCategoyGroup {
    public let name: String?
    public let categories: [TRPPoiCategory]?

    // MARK: - Eat & Drink Category IDs

    /// Group IDs that define Eat & Drink category groups
    /// These are category IDs that indicate a GROUP belongs to Eat & Drink
    public static let eatAndDrinkGroupIds: Set<Int> = [3, 4, 24]

    /// Cached Eat & Drink individual category IDs (extracted from groups)
    /// Updated by TRPPoiUseCases.prefetchCategories() at app startup
    public static var cachedEatAndDrinkCategoryIds: Set<Int> = []
}

extension [TRPPoiCategory] {
    public func getIds() -> [Int] {
        return self.map(\.id)
    }
}
