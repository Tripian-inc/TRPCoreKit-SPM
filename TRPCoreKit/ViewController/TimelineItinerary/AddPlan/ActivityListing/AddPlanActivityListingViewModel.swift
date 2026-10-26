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

    /// Pages loaded so far for the current query, in server order.
    private var loadedTours: [TRPTourProduct] = []

    /// Backend returns at most this many tours per call.
    private let pageLimit = 10
    /// Total result count reported by the API for the current query.
    private var apiTotal = 0
    private var nextOffset = 0
    private var hasMorePages = false
    /// True while a further page is being appended; drives the table's loading footer.
    private(set) public var isLoadingMore = false
    /// Bumped on every fresh search so a late page of a previous query is dropped.
    private var searchGeneration = 0

    private var tourUseCases: TRPTourUseCases?

    /// "yyyy-MM-dd" → activity ids that day already holds; forwarded to the time-selection sheet.
    private var activityIdsByDay: [String: [String]]

    // MARK: - Initialization
    public init(planData: AddPlanData,
                activityIdsByDay: [String: [String]] = [:],
                tourUseCases: TRPTourUseCases? = nil) {
        self.planData = planData
        self.activityIdsByDay = activityIdsByDay
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

    /// Re-queries the API from the first page whenever the text changes; an empty text
    /// fetches the unnarrowed list. The search bar debounces typing.
    public func updateSearchText(_ text: String) {
        guard text != searchText else { return }
        searchText = text
        performSearch(style: .skeleton)
    }

    public func updateSortOption(_ option: SortOption) {
        selectedSortOption = option
        performSearch(style: .skeleton)
    }

    public func updateFilterData(_ data: FilterData) {
        filterData = data
        performSearch(style: .skeleton)
    }

    private var hasServerNarrowing: Bool {
        return !searchText.isEmpty || !filterData.isEmpty || selectedSortOption != .popularity
    }

    public func hasActiveFilters() -> Bool {
        return !filterData.isEmpty
    }

    // MARK: - Activity Fetching
    public func getActivities() -> [TRPTourProduct] {
        return loadedTours
    }

    public func getTourAt(index: Int) -> TRPTourProduct? {
        guard index >= 0 && index < loadedTours.count else { return nil }
        return loadedTours[index]
    }

    /// API total for the current query.
    public func getActivityCount() -> Int {
        return apiTotal
    }

    /// What each day already holds; the time-selection sheet blocks matching days and sends the
    /// picked day's ids as `excludedActivityIds`.
    public func plannedActivityIdsByDay() -> [String: [String]] {
        return activityIdsByDay
    }

    /// Records a day just taken by `tour` so re-opening the sheet reflects it without a timeline round-trip.
    public func markActivityAdded(_ tour: TRPTourProduct, on day: Date?) {
        guard let day = day else { return }

        let id = TRPActivityIdFormat.make(
            tour.productId,
            providerId: tour.productId.trp_parsedProviderId() ?? TRPActivityIdFormat.defaultProviderId,
            cityId: tour.cityId > 0 ? tour.cityId : nil
        )
        let dayKey = TRPDateHelper.formatDateString(day)

        guard !(activityIdsByDay[dayKey]?.contains(id) ?? false) else { return }
        activityIdsByDay[dayKey, default: []].append(id)
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

        // Server treats minPrice = 1 as "at least 1 unit", excluding free (0-priced) tours.
        params.minPrice = 1
        params.sortingBy = SortOption.popularity.apiParameters.sortingBy
        params.sortingType = SortOption.popularity.apiParameters.sortingType

        if hasServerNarrowing {
            params.search = searchText.isEmpty ? nil : searchText
            params.minPrice = max(1, filterData.minPrice.map { Int($0) } ?? 1)
            params.maxPrice = filterData.maxPrice.map { Int($0) }
            params.minDuration = filterData.minDuration
            params.maxDuration = filterData.maxDuration
            params.sortingBy = selectedSortOption.apiParameters.sortingBy
            params.sortingType = selectedSortOption.apiParameters.sortingType
        }

        params.currency = TRPClient.getCurrency()
        params.adults = planData.travelers > 0 ? planData.travelers : 1

        return params
    }

    /// Fetches the first page for the current query and resets pagination. Search, filter and
    /// sort go to the API whenever any of them is active at fetch time.
    private func executeSearch(style: AddPlanLoadingStyle) {
        searchGeneration += 1
        isLoadingMore = false
        loadingStyle = style
        isLoadingTours = true
        delegate?.tourLoadingStateDidChange()

        fetchPage(offset: 0, isPagination: false, generation: searchGeneration)
    }

    /// Appends the next page when the API reports more products than are loaded.
    /// - Returns: true when a page request was started.
    @discardableResult
    public func loadMoreActivities() -> Bool {
        guard hasMorePages, !isLoadingMore, !isLoadingTours else { return false }
        isLoadingMore = true
        fetchPage(offset: nextOffset, isPagination: true, generation: searchGeneration)
        return true
    }

    private func fetchPage(offset: Int, isPagination: Bool, generation: Int) {
        guard let cityId = planData.selectedCity?.id else { return }

        var params = buildSearchParameters()
        params.limit = pageLimit
        params.offset = offset
        let requestedAllCategories = params.categoryIds?.isEmpty ?? true

        tourUseCases?.tourRepository.fetchTours(cityId: cityId, parameters: params) { [weak self] result in
            guard let self = self, generation == self.searchGeneration else { return }
            self.handlePageResult(result,
                                  offset: offset,
                                  isPagination: isPagination,
                                  requestedAllCategories: requestedAllCategories)
        }
    }

    /// - Parameter requestedAllCategories: whether the request that produced `result` carried no category selection.
    private func handlePageResult(_ result: TourResultsValue,
                                  offset: Int,
                                  isPagination: Bool,
                                  requestedAllCategories: Bool) {
        isLoadingMore = false
        if !isPagination {
            isLoadingTours = false
            loadingStyle = .none
        }

        switch result {
        case .success(let outcome):
            if !isPagination { loadedTours = [] }
            var loadedIds = Set(loadedTours.map { $0.productId })
            let newProducts = outcome.products.filter { loadedIds.insert($0.productId).inserted }
            loadedTours.append(contentsOf: newProducts)
            apiTotal = outcome.pagination?.total ?? loadedTours.count
            nextOffset = offset + outcome.products.count
            hasMorePages = !newProducts.isEmpty && loadedTours.count < apiTotal
            let isFirstPage = !isPagination && offset == 0
            let shouldRebuildCategories = isFirstPage && (requestedAllCategories || !hasLoadedInitialFacets)
            let didRebuildCategories = shouldRebuildCategories
                && rebuildFacetCategories(from: outcome.facets, reconcileSelection: requestedAllCategories)
            let didApplyBaselines = applyFirstResponseBaselines(facets: outcome.facets, products: outcome.products)
            if didRebuildCategories || didApplyBaselines {
                delegate?.facetsDidLoad()
            }
            delegate?.activitiesDidLoad()
        case .failure(let error):
            // 504 retry is handled inside TRPTourSearchService; no client-side retry to avoid compounding.
            guard !isPagination else {
                delegate?.activitiesDidLoad()
                return
            }
            delegate?.activitiesDidFail(error: error)
        }
    }

    /// Replaces the chip strip with the categories of a page-0 response requested without a category
    /// selection, or of the first response whatever its selection.
    /// - Parameter reconcileSelection: drops selected ids the new strip no longer offers.
    /// - Returns: false when the response has no categories, leaving the current strip in place.
    private func rebuildFacetCategories(from facets: TRPTourFacets?, reconcileSelection: Bool) -> Bool {
        guard let categories = facets?.categories, !categories.isEmpty else { return false }
        facetCategories = categories
        if reconcileSelection {
            selectedFacetCategoryIds.formIntersection(categories.map { $0.id })
        }
        return true
    }

    /// Only the first response populates slider bounds, so the filter UI stays stable.
    /// Bounds come from the facets (whole result set); the first page's products are the fallback.
    /// - Returns: true when this call applied the baselines.
    private func applyFirstResponseBaselines(facets: TRPTourFacets?, products: [TRPTourProduct]) -> Bool {
        guard !hasLoadedInitialFacets else { return false }
        let bounds = computeBoundsFromProducts(products)
        priceRangeFacet = facets?.priceRange ?? bounds.price
        durationRangeFacet = facets?.durationRange ?? bounds.duration
        hasLoadedInitialFacets = true
        return true
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
}
