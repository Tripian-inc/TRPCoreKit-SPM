//
//  AddPlanActivityListingViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

public protocol AddPlanActivityListingViewModelDelegate: AnyObject {
    func activitiesDidLoad()
    func activitiesDidFail(error: Error)
    func showLoading(_ show: Bool)
}

public class AddPlanActivityListingViewModel {

    // MARK: - Properties
    public let planData: AddPlanData
    public weak var delegate: AddPlanActivityListingViewModelDelegate?

    public var selectedCategoryIndex: Int = 0 // 0 = "All"
    public var searchText: String = ""

    private var allTours: [TRPTourProduct] = []
    private var filteredTours: [TRPTourProduct] = []

    private var tourUseCases: TRPTourUseCases?
    private var searchWorkItem: DispatchWorkItem?
    private var currentPagination: TRPTourPagination?
    private var isLoadingMore: Bool = false

    // MARK: - Initialization
    public init(planData: AddPlanData, tourUseCases: TRPTourUseCases? = nil) {
        self.planData = planData
        self.tourUseCases = tourUseCases ?? TRPTourUseCases()

        // Set city ID from planData
        if let cityId = planData.selectedCity?.id {
            self.tourUseCases?.cityId = cityId
        }
    }
    
    // MARK: - Public Methods
    public func getCategories() -> [PlanCategory] {
        return PlanCategory.allCategories()
    }
    
    public func getCategoryNames() -> [String] {
        // Add "All" at the beginning
        var names = [AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.categoryAll)]
        names.append(contentsOf: PlanCategory.getCategoryNamesForFilter())
        return names
    }
    
    public func getCategoryIconName(at index: Int) -> String? {
        if index == 0 {
            // "All" category - use grid icon (matching Figma design)
            return "square.grid.2x2"
        }
        let categories = PlanCategory.allCategories()
        let categoryIndex = index - 1 // Subtract 1 because "All" is at index 0
        if categoryIndex >= 0 && categoryIndex < categories.count {
            return categories[categoryIndex].iconName
        }
        return nil
    }
    
    // MARK: - Plan Data Accessors
    public func getSelectedDay() -> Date? {
        return planData.selectedDay
    }
    
    public func getSelectedCity() -> TRPCity? {
        return planData.selectedCity
    }
    
    public func getSelectedCategories() -> [String] {
        return planData.selectedCategories
    }
    
    public func getStartTime() -> Date? {
        return planData.startTime
    }
    
    public func getEndTime() -> Date? {
        return planData.endTime
    }
    
    public func getTravelers() -> Int {
        return planData.travelers
    }
    
    public func getStartingPointLocation() -> TRPLocation? {
        return planData.startingPointLocation
    }
    
    public func getStartingPointName() -> String? {
        return planData.startingPointName
    }
    
    public func selectCategory(at index: Int) {
        selectedCategoryIndex = index
        performSearch()
    }

    public func updateSearchText(_ text: String) {
        searchText = text
        performSearchWithDebounce()
    }
    
    /// Returns the selected category ID. Returns nil if "All" is selected (index 0).
    public func getSelectedCategoryId() -> String? {
        guard selectedCategoryIndex > 0 else {
            return nil // "All" selected
        }
        let categories = PlanCategory.allCategories()
        let categoryIndex = selectedCategoryIndex - 1 // Subtract 1 because "All" is at index 0
        if categoryIndex >= 0 && categoryIndex < categories.count {
            return categories[categoryIndex].id
        }
        return nil
    }

    /// Returns the selected category name. Returns nil if "All" is selected (index 0).
    private func getSelectedCategoryName() -> String? {
        guard selectedCategoryIndex > 0 else {
            return nil // "All" selected
        }
        let categories = PlanCategory.allCategories()
        let categoryIndex = selectedCategoryIndex - 1 // Subtract 1 because "All" is at index 0
        if categoryIndex >= 0 && categoryIndex < categories.count {
            return categories[categoryIndex].name.replacingOccurrences(of: "\n", with: " ")
        }
        return nil
    }

    /// Combines search text and category name for keywords parameter
    private func buildKeywords() -> String {
        var keywords: [String] = []

        // Add search text if not empty
        if !searchText.isEmpty {
            keywords.append(searchText)
        }

        // Add category name if a specific category is selected
        if let categoryName = getSelectedCategoryName() {
            keywords.append(categoryName)
        }

        return keywords.joined(separator: " ")
    }
    
    // MARK: - Activity Fetching
    public func getActivities() -> [TRPTourProduct] {
        return filteredTours
    }

    public func getTourAt(index: Int) -> TRPTourProduct? {
        guard index >= 0 && index < filteredTours.count else { return nil }
        return filteredTours[index]
    }

    public func getActivityCount() -> Int {
        return filteredTours.count
    }

    // MARK: - Search Logic
    public func performInitialSearch() {
        performSearch()
    }

    private func performSearchWithDebounce() {
        searchWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.performSearch()
        }

        searchWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(650), execute: workItem)
    }

    private func performSearch() {
        guard let city = planData.selectedCity else {
            delegate?.activitiesDidFail(error: GeneralError.customMessage("City not selected"))
            return
        }

        delegate?.showLoading(true)

        // Build keywords combining search text and category name
        let keywords = buildKeywords()

        // Use user location if available
        if let userLocation = planData.startingPointLocation {
            tourUseCases?.executeSearchTour(text: keywords, categories: [], userLocation: userLocation) { [weak self] result, pagination in
                self?.handleSearchResult(result: result, pagination: pagination)
            }
        } else {
            // Use city-based search
            tourUseCases?.executeSearchTour(text: keywords, categories: []) { [weak self] result, pagination in
                self?.handleSearchResult(result: result, pagination: pagination)
            }
        }
    }

    private func handleSearchResult(result: Result<[TRPTourProduct], Error>, pagination: TRPTourPagination?) {
        delegate?.showLoading(false)
        isLoadingMore = false

        switch result {
        case .success(let tours):
            allTours = tours
            currentPagination = pagination
            filterTours()
            delegate?.activitiesDidLoad()
        case .failure(let error):
            delegate?.activitiesDidFail(error: error)
        }
    }

    // MARK: - Pagination
    public func hasMoreTours() -> Bool {
        return currentPagination?.hasMore ?? false
    }

    public func loadMoreTours() {
        guard !isLoadingMore,
              let pagination = currentPagination,
              let nextOffset = pagination.nextOffset else {
            return
        }

        isLoadingMore = true

        // Build keywords combining search text and category name
        let keywords = buildKeywords()

        // Create parameters with next offset
        var params = TourParameters(search: keywords)
        params.tourCategories = nil // Don't send tagIds, only use keywords
        params.limit = pagination.limit
        params.offset = nextOffset

        // Use repository directly for pagination
        if let cityId = planData.selectedCity?.id {
            tourUseCases?.tourRepository.fetchTours(cityId: cityId, parameters: params) { [weak self] result in
                self?.handleLoadMoreResult(result: result.0, pagination: result.1)
            }
        }
    }

    private func handleLoadMoreResult(result: Result<[TRPTourProduct], Error>, pagination: TRPTourPagination?) {
        isLoadingMore = false

        switch result {
        case .success(let newTours):
            allTours.append(contentsOf: newTours)
            currentPagination = pagination
            filterTours()
            delegate?.activitiesDidLoad()
        case .failure(let error):
            delegate?.activitiesDidFail(error: error)
        }
    }

    private func filterTours() {
        filteredTours = allTours

        // Apply category filter if needed
        if let categoryId = getSelectedCategoryId() {
            filteredTours = filteredTours.getToursWithCategories([categoryId])
        }

        // Apply text search filter if needed
        if !searchText.isEmpty {
            filteredTours = filteredTours.filter { tour in
                tour.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

