//
//  AddPlanCategorySelectionViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation

public struct PlanCategory {
    public let id: String
    public let name: String
    public let iconName: String
    public var isSelected: Bool = false
    
    public static func allCategories() -> [PlanCategory] {
        return [
            PlanCategory(id: "guided tours, free tours", name: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.categoryGuidedTours), iconName: "ic_activities"),
            PlanCategory(id: "tickets", name: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.categoryTickets), iconName: "ic_cat_tickets"),
            PlanCategory(id: "day trip", name: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.categoryExcursions), iconName: "ic_cat_excursions"),
            PlanCategory(id: "things to do", name: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.categoryPOI), iconName: "ic_cat_poi"),
            PlanCategory(id: "food, tasting tour", name: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.categoryFood), iconName: "ic_cat_food_drinks"),
            PlanCategory(id: "show", name: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.categoryShows), iconName: "ic_cat_shows"),
            // PlanCategory(id: "transfer service, transportation", name: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.categoryTransport), iconName: "ic_cat_transfers")
        ]
    }
    
    /// Category names for the filter list, in `allCategories()` order, line breaks stripped.
    public static func getCategoryNamesForFilter() -> [String] {
        return allCategories().map { $0.name.replacingOccurrences(of: "\n", with: " ") }
    }
    
    /// Category IDs for the filter list, in `allCategories()` order.
    public static func getCategoryIdsForFilter() -> [String] {
        return allCategories().map { $0.id }
    }
}

public class AddPlanCategorySelectionViewModel {
    
    // MARK: - Properties
    private weak var containerViewModel: AddPlanContainerViewModel?
    public var categories: [PlanCategory] = PlanCategory.allCategories()
    
    // MARK: - Initialization
    public init(containerViewModel: AddPlanContainerViewModel) {
        self.containerViewModel = containerViewModel

        let selectedIds = containerViewModel.planData.selectedCategories ?? []
        for (index, _) in categories.enumerated() {
            if selectedIds.contains(categories[index].id) {
                categories[index].isSelected = true
            }
        }
    }
    
    // MARK: - Public Methods
    public func toggleCategory(at index: Int) {
        guard index < categories.count else { return }
        categories[index].isSelected.toggle()
        updateContainerViewModel()
    }
    
    public func getSelectedCategories() -> [String] {
        return categories.filter { $0.isSelected }.map { $0.id }
    }
    
    public func hasSelection() -> Bool {
        return categories.contains(where: { $0.isSelected })
    }
    
    public func clearSelection() {
        for (index, _) in categories.enumerated() {
            categories[index].isSelected = false
        }
        updateContainerViewModel()
    }
    
    private func updateContainerViewModel() {
        containerViewModel?.planData.selectedCategories = getSelectedCategories()
    }
}
