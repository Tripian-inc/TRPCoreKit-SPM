//
//  AddPlanActivityListingViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit
import TRPRestKit

public protocol AddPlanActivityListingViewModelDelegate: AnyObject {
    func activitiesDidLoad()
    func activitiesDidFail(error: Error)
    func showLoading(_ show: Bool)
    func facetsDidLoad()
    func tourLoadingStateDidChange()
}

public class AddPlanActivityListingViewModel {

    // MARK: - Properties
    public let planData: AddPlanData
    public weak var delegate: AddPlanActivityListingViewModelDelegate?

    public var searchText: String = ""
    public var selectedSortOption: SortOption = .popularity
    public var filterData: FilterData = FilterData()

    public var selectedFacetCategoryIds: Set<String> = []
    private(set) public var facetCategories: [TRPTourCategoryFacet] = []
    private(set) public var priceRangeFacet: TRPTourPriceRangeFacet?
    private(set) public var durationRangeFacet: TRPTourDurationRangeFacet?
    private var hasLoadedInitialFacets: Bool = false

    private(set) public var isLoadingTours: Bool = false

    /// Untouched server response (popularity-sorted baseline). Local sort + filter run on top.
    private var originalTours: [TRPTourProduct] = []
    private var filteredTours: [TRPTourProduct] = []

    private var tourUseCases: TRPTourUseCases?
    private var searchWorkItem: DispatchWorkItem?

    // MARK: - Initialization
    public init(planData: AddPlanData, tourUseCases: TRPTourUseCases? = nil) {
        self.planData = planData
        self.tourUseCases = tourUseCases ?? TRPTourUseCases()

        // Set city ID from planData
        if let cityId = planData.selectedCity?.id {
            self.tourUseCases?.cityId = cityId
        }
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

    // MARK: - Facet category UI helpers

    /// Number of chips to render: 1 ("All") + facet categories.
    public func getCategoryChipCount() -> Int {
        return 1 + facetCategories.count
    }

    /// Chip label at index. Index 0 = "All", index >= 1 maps to facetCategories[index-1].
    public func getCategoryChipLabel(at index: Int) -> String {
        if index == 0 {
            return AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.categoryAll)
        }
        let facetIndex = index - 1
        guard facetIndex >= 0, facetIndex < facetCategories.count else { return "" }
        return facetCategories[facetIndex].label
    }

    /// Icon asset name for chip at index.
    public func getCategoryChipIconName(at index: Int) -> String {
        if index == 0 {
            return TRPTourCategoryIconMapper.allCategoriesIconName
        }
        let facetIndex = index - 1
        guard facetIndex >= 0, facetIndex < facetCategories.count else {
            return TRPTourCategoryIconMapper.iconName(forKey: nil)
        }
        return TRPTourCategoryIconMapper.iconName(forKey: facetCategories[facetIndex].key)
    }

    public func isCategoryChipSelected(at index: Int) -> Bool {
        if index == 0 {
            return selectedFacetCategoryIds.isEmpty
        }
        let facetIndex = index - 1
        guard facetIndex >= 0, facetIndex < facetCategories.count else { return false }
        return selectedFacetCategoryIds.contains(facetCategories[facetIndex].id)
    }

    public func selectCategoryChip(at index: Int) {
        if index == 0 {
            selectAllCategories()
            return
        }
        let facetIndex = index - 1
        guard facetIndex >= 0, facetIndex < facetCategories.count else { return }
        toggleFacetCategory(id: facetCategories[facetIndex].id)
    }

    public func toggleFacetCategory(id: String) {
        if selectedFacetCategoryIds.contains(id) {
            selectedFacetCategoryIds.remove(id)
        } else {
            selectedFacetCategoryIds.insert(id)
        }
        performSearch()
    }

    public func selectAllCategories() {
        guard !selectedFacetCategoryIds.isEmpty else { return }
        selectedFacetCategoryIds.removeAll()
        performSearch()
    }

    /// True until the first response has populated facets — VC uses this to render skeletons.
    public func isFacetsLoading() -> Bool {
        return !hasLoadedInitialFacets
    }

    public func updateSearchText(_ text: String) {
        searchText = text
        performSearchWithDebounce()
    }

    public func updateSortOption(_ option: SortOption) {
        selectedSortOption = option
        applyLocalSortAndFilter()
        delegate?.activitiesDidLoad()
    }

    public func updateFilterData(_ data: FilterData) {
        filterData = data
        applyLocalSortAndFilter()
        delegate?.activitiesDidLoad()
    }

    public func hasActiveFilters() -> Bool {
        return !filterData.isEmpty
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
        guard planData.selectedCity != nil else {
            delegate?.activitiesDidFail(error: GeneralError.customMessage("City not selected"))
            return
        }

        executeSearch()
    }

    private func buildSearchParameters() -> TourParameters {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let sortedDays = planData.availableDays.sorted()
        let dateFromString = sortedDays.first.map { formatter.string(from: $0) }
        let dateToString = sortedDays.last.map { formatter.string(from: $0) }

        var params = TourParameters(search: searchText.isEmpty ? nil : searchText)
        params.date = dateFromString
        params.dateTo = dateToString

        if !selectedFacetCategoryIds.isEmpty {
            params.categoryIds = Array(selectedFacetCategoryIds)
        }

        // Always request the popularity-sorted baseline. Sort is now applied locally
        // (see `applyLocalSortAndFilter`); leaving this constant means category and
        // search-text refetches return a stable baseline that local sort runs on top of.
        params.sortingBy = "score"
        params.sortingType = "desc"

        // Price and duration filters are applied locally — do NOT send them to the server.
        // (Leaving them nil so server returns the unfiltered baseline.)

        // Set currency and adults
        params.currency = TRPClient.getCurrency()
        params.adults = planData.travelers > 0 ? planData.travelers : 1

        return params
    }

    private func executeSearch() {
        isLoadingTours = true
        delegate?.tourLoadingStateDidChange()

        let params = buildSearchParameters()

        guard let cityId = planData.selectedCity?.id else { return }
        tourUseCases?.tourRepository.fetchTours(cityId: cityId, parameters: params) { [weak self] result in
            self?.handleSearchResult(result: result)
        }
    }

    private func handleSearchResult(result: TourResultsValue) {
        switch result {
        case .success(let outcome):
            isLoadingTours = false
            originalTours = outcome.products
            applyFacetsIfNeeded(outcome.facets)
            applyLocalSortAndFilter()
            delegate?.activitiesDidLoad()
        case .failure(let error):
            // 504 retry is handled inside TRPTourSearchService (single attempt) — no
            // additional client-side retry, otherwise we'd compound to two retries.
            isLoadingTours = false
            delegate?.activitiesDidFail(error: error)
        }
    }

    /// Freeze: only the first response (filterless initial load) populates facets.
    /// Subsequent filtered responses are ignored so chips and slider bounds remain stable.
    private func applyFacetsIfNeeded(_ facets: TRPTourFacets?) {
        guard !hasLoadedInitialFacets, let facets = facets else { return }
        facetCategories = facets.categories
        priceRangeFacet = facets.priceRange
        durationRangeFacet = facets.durationRange
        hasLoadedInitialFacets = true
        delegate?.facetsDidLoad()
    }

    /// Apply price + duration filter and sort on top of `originalTours` (the server baseline).
    /// Sort and filter are now fully local — no service request is dispatched on changes.
    /// Category and search-text changes still go through the server (they trigger
    /// `executeSearch()` which repopulates `originalTours` and re-runs this pipeline).
    private func applyLocalSortAndFilter() {
        var working = originalTours

        // Price filter — products without a price are excluded when a bound is active.
        if filterData.minPrice != nil || filterData.maxPrice != nil {
            working = working.filter { tour in
                guard let price = tour.price else { return false }
                if let lo = filterData.minPrice, price < lo { return false }
                if let hi = filterData.maxPrice, price > hi { return false }
                return true
            }
        }

        // Duration filter — same exclusion semantics as price.
        if filterData.minDuration != nil || filterData.maxDuration != nil {
            working = working.filter { tour in
                guard let duration = tour.duration else { return false }
                if let lo = filterData.minDuration, duration < lo { return false }
                if let hi = filterData.maxDuration, duration > hi { return false }
                return true
            }
        }

        // Sort — `popularity` is preserved by leaving the server-supplied order alone.
        switch selectedSortOption {
        case .popularity:
            break
        case .rating:
            working.sort { (Double($0.rating ?? -.greatestFiniteMagnitude)) > (Double($1.rating ?? -.greatestFiniteMagnitude)) }
        case .priceLowToHigh:
            working.sort { ($0.price ?? .max) < ($1.price ?? .max) }
        case .durationShortToLong:
            working.sort { ($0.duration ?? .max) < ($1.duration ?? .max) }
        case .durationLongToShort:
            working.sort { ($0.duration ?? .min) > ($1.duration ?? .min) }
        }

        filteredTours = working
    }
}
