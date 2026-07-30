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
    func searchTextDidReset()
}

public enum AddPlanLoadingStyle {
    case none
    case skeleton
    case lottie
    case bottomSheet
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
    private(set) public var loadingStyle: AddPlanLoadingStyle = .none

    private let localChangeAnimationDuration: TimeInterval = 0.7

    /// Untouched server response (popularity-sorted baseline); local sort + filter run on top.
    private var originalTours: [TRPTourProduct] = []
    private var filteredTours: [TRPTourProduct] = []

    private var tourUseCases: TRPTourUseCases?

    /// Bare product id → "yyyy-MM-dd" days the activity already occupies anywhere in the trip.
    private var addedActivityDays: [String: Set<String>]

    // MARK: - Initialization
    public init(planData: AddPlanData,
                addedActivityDays: [String: Set<String>] = [:],
                tourUseCases: TRPTourUseCases? = nil) {
        self.planData = planData
        self.addedActivityDays = addedActivityDays
        self.tourUseCases = tourUseCases ?? TRPTourUseCases()

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

    public func getCategoryChipCount() -> Int {
        return 1 + facetCategories.count
    }

    public func getCategoryChipLabel(at index: Int) -> String {
        if index == 0 {
            return AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.categoryAll)
        }
        let facetIndex = index - 1
        guard facetIndex >= 0, facetIndex < facetCategories.count else { return "" }
        return facetCategories[facetIndex].label
    }

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
        clearSearchTextOnCategoryChange()
        performSearch(style: .skeleton)
    }

    public func selectAllCategories() {
        guard !selectedFacetCategoryIds.isEmpty else { return }
        selectedFacetCategoryIds.removeAll()
        clearSearchTextOnCategoryChange()
        performSearch(style: .skeleton)
    }

    /// A persistent search query across category switches is rarely the intent and produces a confusing empty list.
    private func clearSearchTextOnCategoryChange() {
        guard !searchText.isEmpty else { return }
        searchText = ""
        delegate?.searchTextDidReset()
    }

    /// True until the first response has populated facets.
    public func isFacetsLoading() -> Bool {
        return !hasLoadedInitialFacets
    }

    public func updateSearchText(_ text: String) {
        searchText = text
        applyLocalSortAndFilter()
        delegate?.activitiesDidLoad()
    }

    public func updateSortOption(_ option: SortOption) {
        selectedSortOption = option
        applyLocalChangeWithSkeletonFlash {
            self.applyLocalSortAndFilter()
        }
    }

    public func updateFilterData(_ data: FilterData) {
        filterData = data
        applyLocalChangeWithSkeletonFlash {
            self.applyLocalSortAndFilter()
        }
    }

    private func applyLocalChangeWithSkeletonFlash(_ work: @escaping () -> Void) {
        loadingStyle = .skeleton
        isLoadingTours = true
        delegate?.tourLoadingStateDidChange()

        DispatchQueue.main.asyncAfter(deadline: .now() + localChangeAnimationDuration) { [weak self] in
            guard let self = self else { return }
            work()
            self.isLoadingTours = false
            self.loadingStyle = .none
            self.delegate?.activitiesDidLoad()
        }
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

    /// Days this activity already occupies; the time-selection sheet renders them unselectable.
    public func alreadyAddedDays(for tour: TRPTourProduct) -> Set<String> {
        return addedActivityDays[tour.productId.cleanedAsActivityId()] ?? []
    }

    /// Records a day just taken by `tour` so re-opening the sheet blocks it without a timeline round-trip.
    public func markActivityAdded(_ tour: TRPTourProduct, on day: Date?) {
        guard let day = day else { return }
        addedActivityDays[tour.productId.cleanedAsActivityId(), default: []]
            .insert(TRPDateHelper.formatDateString(day))
    }

    // MARK: - Search Logic
    public func performInitialSearch() {
        performSearch(style: .lottie)
    }

    private func performSearch(style: AddPlanLoadingStyle) {
        guard planData.selectedCity != nil else {
            delegate?.activitiesDidFail(error: GeneralError.customMessage("City not selected"))
            return
        }

        executeSearch(style: style)
    }

    private func buildSearchParameters() -> TourParameters {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // Both bounds collapse to the single picked day so the server only returns what's bookable then.
        let selectedDayString = planData.selectedDay.map { formatter.string(from: $0) }

        var params = TourParameters()
        params.date = selectedDayString
        params.dateTo = selectedDayString

        if !selectedFacetCategoryIds.isEmpty {
            params.categoryIds = Array(selectedFacetCategoryIds)
        }

        // Always request the popularity-sorted baseline; sort runs locally on top.
        params.sortingBy = "score"
        params.sortingType = "desc"

        // Server treats minPrice = 1 as "at least 1 unit", excluding free (0-priced) tours.
        params.minPrice = 1

        // Max-price and duration filters are applied locally — left nil here on purpose.

        params.currency = TRPClient.getCurrency()
        params.adults = planData.travelers > 0 ? planData.travelers : 1

        return params
    }

    private func executeSearch(style: AddPlanLoadingStyle) {
        loadingStyle = style
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
            loadingStyle = .none
            originalTours = outcome.products
            applyFirstResponseBaselines(facets: outcome.facets, products: outcome.products)
            applyLocalSortAndFilter()
            delegate?.activitiesDidLoad()
        case .failure(let error):
            // 504 retry is handled inside TRPTourSearchService; no client-side retry to avoid compounding.
            isLoadingTours = false
            loadingStyle = .none
            delegate?.activitiesDidFail(error: error)
        }
    }

    /// Only the first response populates chips and slider bounds, so the filter UI stays stable.
    private func applyFirstResponseBaselines(facets: TRPTourFacets?, products: [TRPTourProduct]) {
        guard !hasLoadedInitialFacets else { return }
        facetCategories = facets?.categories ?? []
        let bounds = computeBoundsFromProducts(products)
        priceRangeFacet = bounds.price
        durationRangeFacet = bounds.duration
        hasLoadedInitialFacets = true
        delegate?.facetsDidLoad()
    }

    /// Returns nil for either side when there's no meaningful range; the filter UI then uses hardcoded bounds.
    private func computeBoundsFromProducts(
        _ products: [TRPTourProduct]
    ) -> (price: TRPTourPriceRangeFacet?, duration: TRPTourDurationRangeFacet?) {
        let prices = products.compactMap { $0.price }
        let durations = products.compactMap { $0.duration }

        var priceRange: TRPTourPriceRangeFacet?
        if let minPrice = prices.min(), let maxPrice = prices.max(), minPrice < maxPrice {
            let currency = products.first(where: { $0.currency != nil })?.currency
                ?? TRPClient.getCurrency()
            priceRange = TRPTourPriceRangeFacet(
                minAmount: minPrice,
                maxAmount: maxPrice,
                currency: currency
            )
        }

        var durationRange: TRPTourDurationRangeFacet?
        if let minDuration = durations.min(),
           let maxDuration = durations.max(),
           minDuration < maxDuration {
            durationRange = TRPTourDurationRangeFacet(
                minMinutes: minDuration,
                maxMinutes: maxDuration
            )
        }

        return (priceRange, durationRange)
    }

    /// Sort + price/duration filter run fully locally on `originalTours`; category and search-text changes refetch.
    private func applyLocalSortAndFilter() {
        var working = originalTours

        if !searchText.isEmpty {
            working = working.filter { tour in
                tour.name.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Products without a price are excluded when a bound is active.
        if filterData.minPrice != nil || filterData.maxPrice != nil {
            working = working.filter { tour in
                guard let price = tour.price else { return false }
                if let lo = filterData.minPrice, price < lo { return false }
                if let hi = filterData.maxPrice, price > hi { return false }
                return true
            }
        }

        if filterData.minDuration != nil || filterData.maxDuration != nil {
            working = working.filter { tour in
                guard let duration = tour.duration else { return false }
                if let lo = filterData.minDuration, duration < lo { return false }
                if let hi = filterData.maxDuration, duration > hi { return false }
                return true
            }
        }

        // `popularity` is preserved by leaving the server-supplied order alone.
        switch selectedSortOption {
        case .popularity:
            break
        case .rating:
            working.sort { (Double($0.rating ?? -.greatestFiniteMagnitude)) > (Double($1.rating ?? -.greatestFiniteMagnitude)) }
        case .priceLowToHigh:
            // Push price-less tours to the end (Double has no `.max`).
            working.sort { ($0.price ?? .greatestFiniteMagnitude) < ($1.price ?? .greatestFiniteMagnitude) }
        case .durationShortToLong:
            working.sort { ($0.duration ?? .max) < ($1.duration ?? .max) }
        case .durationLongToShort:
            working.sort { ($0.duration ?? .min) > ($1.duration ?? .min) }
        }

        filteredTours = working
    }
}
