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
            PlanCategory(id: "guided_tours", name: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.categoryGuidedTours), iconName: "person.2.fill"),
            PlanCategory(id: "tickets", name: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.categoryTickets), iconName: "ticket.fill"),
            PlanCategory(id: "excursions", name: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.categoryExcursions), iconName: "bus.fill"),
            PlanCategory(id: "poi", name: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.categoryPOI), iconName: "mappin.and.ellipse"),
            PlanCategory(id: "food", name: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.categoryFood), iconName: "fork.knife"),
            PlanCategory(id: "shows", name: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.categoryShows), iconName: "theatermasks.fill"),
            PlanCategory(id: "transport", name: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.categoryTransport), iconName: "airplane")
        ]
    }
}

public class AddPlanCategorySelectionViewModel {
    
    // MARK: - Properties
    private weak var containerViewModel: AddPlanContainerViewModel?
    public var categories: [PlanCategory] = PlanCategory.allCategories()
    
    // MARK: - Initialization
    public init(containerViewModel: AddPlanContainerViewModel) {
        self.containerViewModel = containerViewModel
        
        // Restore previously selected categories
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
