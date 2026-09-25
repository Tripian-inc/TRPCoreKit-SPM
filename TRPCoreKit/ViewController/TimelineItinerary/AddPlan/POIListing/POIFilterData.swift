//
//  POIFilterData.swift
//  TRPCoreKit
//
//  Created by Cem Caygoz on 26.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import Foundation

// MARK: - POI Filter Data Model
public struct POIFilterData {
    public var selectedCategoryIds: Set<Int>

    public init(selectedCategoryIds: Set<Int> = []) {
        self.selectedCategoryIds = selectedCategoryIds
    }

    public var isEmpty: Bool {
        return selectedCategoryIds.isEmpty
    }

    public var activeFilterCount: Int {
        return selectedCategoryIds.count
    }

    public mutating func toggleCategory(_ categoryId: Int) {
        if selectedCategoryIds.contains(categoryId) {
            selectedCategoryIds.remove(categoryId)
        } else {
            selectedCategoryIds.insert(categoryId)
        }
    }

    public mutating func clear() {
        selectedCategoryIds.removeAll()
    }

    public func isSelected(_ categoryId: Int) -> Bool {
        return selectedCategoryIds.contains(categoryId)
    }
}
