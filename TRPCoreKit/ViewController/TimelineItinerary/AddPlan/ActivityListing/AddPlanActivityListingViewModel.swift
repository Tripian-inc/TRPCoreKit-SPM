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

    public var selectedCategoryIndices: Set<Int> = [0] // 0 = "All", multiple selection allowed except "All"
    public var searchText: String = ""
    public var selectedSortOption: SortOption = .popularity

    private var allTours: [TRPTourProduct] = []
    private var filteredTours: [TRPTourProduct] = []

    private var tourUseCases: TRPTourUseCases?
    private var searchWorkItem: DispatchWorkItem?
    private var currentPagination: TRPTourPagination?
    private var isLoadingMore: Bool = false
    private var searchRetryCount: Int = 0
    private let maxRetryCount: Int = 1

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
            // "All" category
            return "ic_all_categories"
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
        if index == 0 {
            // "All" selected - clear others and select only "All"
            selectedCategoryIndices = [0]
        } else {
            // Other category selected
            // Remove "All" from selection
            selectedCategoryIndices.remove(0)

            // Toggle the selected category
            if selectedCategoryIndices.contains(index) {
                selectedCategoryIndices.remove(index)
            } else {
                selectedCategoryIndices.insert(index)
            }

            // If no categories selected, select "All"
            if selectedCategoryIndices.isEmpty {
                selectedCategoryIndices = [0]
            }
        }
        performSearch()
    }

    public func isCategorySelected(at index: Int) -> Bool {
        return selectedCategoryIndices.contains(index)
    }

    public func updateSearchText(_ text: String) {
        searchText = text
        performSearchWithDebounce()
    }

    public func updateSortOption(_ option: SortOption) {
        selectedSortOption = option
        performSearch()
    }
    
    /// Returns the selected category IDs. Returns nil if "All" is selected (index 0).
    public func getSelectedCategoryIds() -> [String]? {
        // If "All" is selected, return nil
        if selectedCategoryIndices.contains(0) {
            return nil
        }

        let categories = PlanCategory.allCategories()
        var ids: [String] = []

        for index in selectedCategoryIndices {
            let categoryIndex = index - 1 // Subtract 1 because "All" is at index 0
            if categoryIndex >= 0 && categoryIndex < categories.count {
                ids.append(categories[categoryIndex].id)
            }
        }

        return ids.isEmpty ? nil : ids
    }

    /// Returns the selected category names combined. Returns nil if "All" is selected (index 0).
    private func getSelectedCategoryNames() -> [String]? {
        // If "All" is selected, return nil
        if selectedCategoryIndices.contains(0) {
            return nil
        }

        let categories = PlanCategory.allCategories()
        var names: [String] = []

        for index in selectedCategoryIndices.sorted() {
            let categoryIndex = index - 1 // Subtract 1 because "All" is at index 0
            if categoryIndex >= 0 && categoryIndex < categories.count {
                names.append(categories[categoryIndex].name.replacingOccurrences(of: "\n", with: " "))
            }
        }

        return names.isEmpty ? nil : names
    }

    /// Combines search text and category names for keywords parameter
    private func buildKeywords() -> String {
        var keywords: [String] = []

        // Add search text if not empty
        if !searchText.isEmpty {
            keywords.append(searchText)
        }

        // Add category names if specific categories are selected
        if let categoryNames = getSelectedCategoryNames() {
            keywords.append(contentsOf: categoryNames)
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

        // Reset retry count for new search
        searchRetryCount = 0
        executeSearch()
    }

    private func executeSearch() {
        delegate?.showLoading(true)

        // Build keywords combining search text and category name
        let keywords = buildKeywords()

        // Format selected date as "yyyy-MM-dd"
        var dateString: String?
        if let selectedDay = planData.selectedDay {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateString = dateFormatter.string(from: selectedDay)
        }

        // Build parameters with sorting
        var params = TourParameters(search: keywords.isEmpty ? nil : keywords)
        params.date = dateString

        // Apply sorting parameters
        let sortParams = selectedSortOption.apiParameters
        params.sortingBy = sortParams.sortingBy
        params.sortingType = sortParams.sortingType

        // Use repository directly to support sorting
        guard let cityId = planData.selectedCity?.id else { return }
        tourUseCases?.tourRepository.fetchTours(cityId: cityId, parameters: params) { [weak self] result in
            self?.handleSearchResult(result: result.0, pagination: result.1)
        }
    }

    private func handleSearchResult(result: Result<[TRPTourProduct], Error>, pagination: TRPTourPagination?) {
        isLoadingMore = false

        switch result {
        case .success(let tours):
            delegate?.showLoading(false)
            allTours = tours
            currentPagination = pagination
            filterTours()
            delegate?.activitiesDidLoad()
        case .failure(let error):
            // Check for 504 Gateway Timeout and retry once
            if is504Error(error) && searchRetryCount < maxRetryCount {
                searchRetryCount += 1
                executeSearch()
                return
            }
            delegate?.showLoading(false)
            delegate?.activitiesDidFail(error: error)
        }
    }

    private func is504Error(_ error: Error) -> Bool {
        // Check if error contains 504 status code
        if let nsError = error as NSError? {
            if nsError.code == 504 {
                return true
            }
            // Check userInfo for status code
            if let statusCode = nsError.userInfo["statusCode"] as? Int, statusCode == 504 {
                return true
            }
        }
        // Check error description for 504
        let errorDescription = error.localizedDescription.lowercased()
        if errorDescription.contains("504") || errorDescription.contains("gateway timeout") {
            return true
        }
        return false
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
        var params = TourParameters(search: keywords.isEmpty ? nil : keywords)
        params.tourCategories = nil // Don't send tagIds, only use keywords
        params.limit = pagination.limit
        params.offset = nextOffset

        // Apply sorting parameters (same as initial search)
        let sortParams = selectedSortOption.apiParameters
        params.sortingBy = sortParams.sortingBy
        params.sortingType = sortParams.sortingType

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
        // API already filters by category (via keywords), so no need to filter client-side
        // Only apply text search filter if needed
        filteredTours = allTours

        if !searchText.isEmpty {
            filteredTours = filteredTours.filter { tour in
                tour.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

