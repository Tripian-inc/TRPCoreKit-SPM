//
//  AddPlanPOIListingViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 30.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

public enum POIListingCategoryType: String {
    case placesOfInterest = "places_of_interest"
    case eatAndDrink = "eat_and_drink"
}

public protocol AddPlanPOIListingViewModelDelegate: ViewModelDelegate {
    func poisDidLoad()
    func segmentCreatedSuccessfully()
}

public class AddPlanPOIListingViewModel {

    // MARK: - Properties
    public let planData: AddPlanData
    public let categoryType: POIListingCategoryType
    public weak var delegate: AddPlanPOIListingViewModelDelegate?

    public var searchText: String = ""

    private var allPois: [TRPPoi] = []
    private var filteredPois: [TRPPoi] = []
    private var categoryIds: [Int] = []

    private var poiUseCases: TRPPoiUseCases
    private var timelineRepository: TRPTimelineRepository
    private var searchWorkItem: DispatchWorkItem?
    private var isLoadingMore: Bool = false
    private var currentPage: Int = 1
    private var totalPages: Int = 1

    // MARK: - Initialization
    public init(planData: AddPlanData, categoryType: POIListingCategoryType) {
        self.planData = planData
        self.categoryType = categoryType
        self.poiUseCases = TRPPoiUseCases()
        self.timelineRepository = TRPTimelineRepository()

        // Set city ID from planData
        if let cityId = planData.selectedCity?.id {
            self.poiUseCases.cityId = cityId
        }
    }

    // MARK: - Public Methods
    public func getTitle() -> String {
        switch categoryType {
        case .placesOfInterest:
            return AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.categoryPlacesOfInterest)
                .replacingOccurrences(of: "\n", with: " ")
        case .eatAndDrink:
            return AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.categoryEatAndDrink)
                .replacingOccurrences(of: "\n", with: " ")
        }
    }

    // MARK: - Plan Data Accessors
    public func getSelectedDay() -> Date? {
        return planData.selectedDay
    }

    public func getSelectedCity() -> TRPCity? {
        return planData.selectedCity
    }

    public func getPois() -> [TRPPoi] {
        return filteredPois
    }

    public func getPoiAt(index: Int) -> TRPPoi? {
        guard index >= 0 && index < filteredPois.count else { return nil }
        return filteredPois[index]
    }

    public func getPoiCount() -> Int {
        return filteredPois.count
    }

    public func updateSearchText(_ text: String) {
        searchText = text
        performSearchWithDebounce()
    }

    // MARK: - Data Fetching
    public func performInitialFetch() {
        fetchCategoriesAndPois()
    }

    private func fetchCategoriesAndPois() {
        // Reset pagination
        currentPage = 1
        totalPages = 1

        delegate?.viewModel(showPreloader: true)

        // First fetch categories to get the appropriate category IDs
        poiUseCases.executeFetchPoiCategories { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let categoryGroups):
                self.categoryIds = self.extractCategoryIds(from: categoryGroups)
                self.fetchPois()
            case .failure(let error):
                self.delegate?.viewModel(showPreloader: false)
                self.delegate?.viewModel(error: error)
            }
        }
    }

    private func extractCategoryIds(from groups: [TRPPoiCategoyGroup]) -> [Int] {
        // Category IDs that define Eat & Drink groups
        let eatAndDrinkCategoryIds: Set<Int> = [3, 4, 24]

        var ids: [Int] = []

        for group in groups {
            guard let categories = group.categories else { continue }

            let categoryIds = categories.getIds()

            // Check if this group contains any Eat & Drink category ID
            let isEatAndDrinkGroup = categoryIds.contains { eatAndDrinkCategoryIds.contains($0) }

            switch categoryType {
            case .placesOfInterest:
                // All groups that don't contain Eat & Drink category IDs (3, 4, 24)
                if !isEatAndDrinkGroup {
                    ids.append(contentsOf: categoryIds)
                }
            case .eatAndDrink:
                // Only groups that contain category ID 3, 4, or 24
                if isEatAndDrinkGroup {
                    ids.append(contentsOf: categoryIds)
                }
            }
        }

        return ids
    }

    private func fetchPois(page: Int = 1) {
        guard let cityId = planData.selectedCity?.id else {
            delegate?.viewModel(showPreloader: false)
            delegate?.viewModel(error: GeneralError.customMessage("City not selected"))
            return
        }

        poiUseCases.executeSearchPoi(
            text: searchText,
            categories: categoryIds,
            cityId: cityId,
            page: page
        ) { [weak self] result, pagination in
            self?.handleSearchResult(result: result, pagination: pagination, isLoadMore: page > 1)
        }
    }

    private func performSearchWithDebounce() {
        searchWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.performSearch()
        }

        searchWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500), execute: workItem)
    }

    private func performSearch() {
        guard let cityId = planData.selectedCity?.id else {
            delegate?.viewModel(error: GeneralError.customMessage("City not selected"))
            return
        }

        // Reset pagination for new search
        currentPage = 1
        totalPages = 1

        delegate?.viewModel(showPreloader: true)

        poiUseCases.executeSearchPoi(
            text: searchText,
            categories: categoryIds,
            cityId: cityId,
            page: 1
        ) { [weak self] result, pagination in
            self?.handleSearchResult(result: result, pagination: pagination, isLoadMore: false)
        }
    }

    private func handleSearchResult(result: Result<[TRPPoi], Error>, pagination: TRPPagination?, isLoadMore: Bool = false) {
        delegate?.viewModel(showPreloader: false)
        isLoadingMore = false

        switch result {
        case .success(let pois):
            if isLoadMore {
                // Append new POIs for load more
                allPois.append(contentsOf: pois)
            } else {
                // Replace POIs for initial load or new search
                allPois = pois
            }

            // Update pagination info from TRPPagination
            if let pagination = pagination {
                switch pagination {
                case .completed:
                    totalPages = currentPage
                case .continues:
                    // There are more pages
                    totalPages = currentPage + 1
                }
            }

            filterPois()
            delegate?.poisDidLoad()
        case .failure(let error):
            delegate?.viewModel(error: error)
        }
    }

    // MARK: - Pagination
    public func hasMorePois() -> Bool {
        return currentPage < totalPages
    }

    public func loadMorePois() {
        guard !isLoadingMore, hasMorePois() else { return }

        isLoadingMore = true
        currentPage += 1

        fetchPois(page: currentPage)
    }

    private func filterPois() {
        if searchText.isEmpty {
            filteredPois = allPois
        } else {
            filteredPois = allPois.filter { poi in
                poi.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    // MARK: - Segment Creation
    public func createManualPoiSegment(poi: TRPPoi, startTime: Date, endTime: Date) {
        guard let tripHash = planData.tripHash,
              let selectedDay = planData.selectedDay,
              let selectedCity = planData.selectedCity else {
            delegate?.viewModel(error: GeneralError.customMessage(
                AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.errorMissingData)
            ))
            return
        }

        delegate?.viewModel(showPreloader: true)

        // Create segment profile
        let segment = TRPCreateEditTimelineSegmentProfile(tripHash: tripHash)
        segment.segmentType = .manualPoi
        segment.available = false
        segment.title = poi.name
        segment.poiId = poi.id
        segment.city = selectedCity
        segment.coordinate = poi.coordinate

        // Add POI id to includePoiIds
        segment.includePoiIds = [poi.id]

        // Combine selectedDay date with the time from startTime/endTime
        let calendar = Calendar.current

        // Get date components from selectedDay (year, month, day)
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: selectedDay)

        // Get time components from startTime (hour, minute)
        let startTimeComponents = calendar.dateComponents([.hour, .minute], from: startTime)

        // Get time components from endTime (hour, minute)
        let endTimeComponents = calendar.dateComponents([.hour, .minute], from: endTime)

        // Combine date + start time
        var startDateComponents = DateComponents()
        startDateComponents.year = dayComponents.year
        startDateComponents.month = dayComponents.month
        startDateComponents.day = dayComponents.day
        startDateComponents.hour = startTimeComponents.hour
        startDateComponents.minute = startTimeComponents.minute

        // Combine date + end time
        var endDateComponents = DateComponents()
        endDateComponents.year = dayComponents.year
        endDateComponents.month = dayComponents.month
        endDateComponents.day = dayComponents.day
        endDateComponents.hour = endTimeComponents.hour
        endDateComponents.minute = endTimeComponents.minute

        let combinedStartDate = calendar.date(from: startDateComponents) ?? selectedDay
        let combinedEndDate = calendar.date(from: endDateComponents) ?? selectedDay

        // Format date as "yyyy-MM-dd HH:mm"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        segment.startDate = dateFormatter.string(from: combinedStartDate)
        segment.endDate = dateFormatter.string(from: combinedEndDate)

        // Call repository to create segment
        timelineRepository.createEditTimelineSegment(profile: segment) { [weak self] result in
            guard let self = self else { return }

            self.delegate?.viewModel(showPreloader: false)

            switch result {
            case .success:
                self.delegate?.segmentCreatedSuccessfully()
            case .failure(let error):
                self.delegate?.viewModel(error: error)
            }
        }
    }
}
