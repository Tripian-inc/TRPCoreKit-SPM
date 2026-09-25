//
//  AddPlanPOIFilterViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Caygoz on 26.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

// MARK: - AddPlanPOIFilterViewModel
public class AddPlanPOIFilterViewModel {

    // MARK: - Properties
    private let categoryType: POIListingCategoryType
    private var filterData: POIFilterData
    private var categories: [TRPPoiCategory] = []

    // MARK: - Initialization
    public init(categoryType: POIListingCategoryType, filterData: POIFilterData = POIFilterData()) {
        self.categoryType = categoryType
        self.filterData = filterData
        loadCategories()
    }

    // MARK: - Category Loading
    private func loadCategories() {
        let allGroups = TRPPoiUseCases.getCategoryGroups()

        var filteredCategories: [TRPPoiCategory] = []

        for group in allGroups {
            guard let groupCategories = group.categories else { continue }

            let categoryIds = groupCategories.getIds()
            let isEatAndDrinkGroup = categoryIds.contains { TRPPoiCategoyGroup.eatAndDrinkGroupIds.contains($0) }

            if categoryType == .eatAndDrink && isEatAndDrinkGroup {
                filteredCategories.append(contentsOf: groupCategories)
            } else if categoryType == .placesOfInterest && !isEatAndDrinkGroup {
                filteredCategories.append(contentsOf: groupCategories)
            }
        }

        var uniqueCategories: [Int: TRPPoiCategory] = [:]
        for category in filteredCategories {
            uniqueCategories[category.id] = category
        }

        categories = Array(uniqueCategories.values).sorted { ($0.name ?? "") < ($1.name ?? "") }
    }

    // MARK: - Public Methods

    public func getCategoryCount() -> Int {
        return categories.count
    }

    public func getCategory(at index: Int) -> TRPPoiCategory? {
        guard index >= 0 && index < categories.count else { return nil }
        return categories[index]
    }

    public func getCategoryName(at index: Int) -> String {
        return categories[index].name ?? ""
    }

    public func isCategorySelected(at index: Int) -> Bool {
        guard let category = getCategory(at: index) else { return false }
        return filterData.isSelected(category.id)
    }

    public func toggleCategory(at index: Int) {
        guard let category = getCategory(at: index) else { return }
        filterData.toggleCategory(category.id)
    }

    public func clearSelection() {
        filterData.clear()
    }

    public func getFilterData() -> POIFilterData {
        return filterData
    }

    public func hasSelection() -> Bool {
        return !filterData.isEmpty
    }
}
