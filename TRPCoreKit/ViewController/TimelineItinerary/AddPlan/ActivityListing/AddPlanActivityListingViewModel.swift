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
    /// Fires when the VM has reset the active search text (e.g. on a category change),
    /// so the VC can clear the search bar UI to mirror the underlying state.
    func searchTextDidReset()
}

/// Drives which loading UI the listing screen should render while a tour fetch or local
/// recompute is in flight.
public enum AddPlanLoadingStyle {
    case none
    /// Inline table skeleton — used for sort/filter local recompute and search-text refresh.
    case skeleton
    /// Window-attached Lottie overlay — used for the initial open, where the user is
    /// waiting on a fresh server fetch and a full-screen indicator is warranted.
    case lottie
    /// Bottom-sheet Lottie loader — used for category chip changes, where a partial
    /// indicator over the listing fits the UX better than a full-window blocker.
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

    /// Duration of the deliberate skeleton flash for local sort/filter changes — gives
    /// the user clear visual feedback even though the actual recompute is instant.
    private let localChangeAnimationDuration: TimeInterval = 0.7

    /// Untouched server response (popularity-sorted baseline). Local sort + filter run on top.
    private var originalTours: [TRPTourProduct] = []
    private var filteredTours: [TRPTourProduct] = []

    private var tourUseCases: TRPTourUseCases?

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
        clearSearchTextOnCategoryChange()
        // Category change → bottom-sheet Lottie. Full-screen overlay is reserved for the
        // initial open; subsequent refetches use a less intrusive indicator.
        performSearch(style: .bottomSheet)
    }

    public func selectAllCategories() {
        guard !selectedFacetCategoryIds.isEmpty else { return }
        selectedFacetCategoryIds.removeAll()
        clearSearchTextOnCategoryChange()
        performSearch(style: .bottomSheet)
    }

    /// Reset the local search text whenever the user changes their category selection.
    /// A persistent search query across category switches is rarely the intent and easily
    /// produces a confusing empty list. Notifies the delegate so the VC can clear the
    /// search bar UI to match.
    private func clearSearchTextOnCategoryChange() {
        guard !searchText.isEmpty else { return }
        searchText = ""
        delegate?.searchTextDidReset()
    }

    /// True until the first response has populated facets — VC uses this to render skeletons.
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

    /// Show the inline skeleton briefly while a local recompute "happens", giving
    /// the user a clear visual signal that their sort/filter selection took effect.
    /// Matches the UX of a short server roundtrip without actually hitting the network.
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

        // Scope the request to the day picked in AddPlan — both bounds collapse
        // to that single day so the server returns only what's bookable then,
        // instead of the full trip span.
        let selectedDayString = planData.selectedDay.map { formatter.string(from: $0) }

        // Search text is filtered locally — never sent to the server.
        var params = TourParameters()
        params.date = selectedDayString
        params.dateTo = selectedDayString

        if !selectedFacetCategoryIds.isEmpty {
            params.categoryIds = Array(selectedFacetCategoryIds)
        }

        // Always request the popularity-sorted baseline. Sort is now applied locally
        // (see `applyLocalSortAndFilter`); leaving this constant means category and
        // search-text refetches return a stable baseline that local sort runs on top of.
        params.sortingBy = "score"
        params.sortingType = "desc"

        // Exclude free tours from the listing. The server treats `minPrice = 1` as
        // "at least 1 unit of currency", which filters out anything priced at 0.
        // The local price-range filter still runs on top of this baseline.
        params.minPrice = 1

        // Max-price and duration filters are applied locally — do NOT send them to
        // the server. (Leaving them nil so server returns the unfiltered baseline.)

        // Set currency and adults
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
            // 504 retry is handled inside TRPTourSearchService (single attempt) — no
            // additional client-side retry, otherwise we'd compound to two retries.
            isLoadingTours = false
            loadingStyle = .none
            delegate?.activitiesDidFail(error: error)
        }
    }

    /// Freeze: only the first response populates the chip list and slider bounds.
    /// Subsequent (filtered) responses are ignored so the filter UI stays stable.
    ///
    /// Categories come from the facet payload (server-curated taxonomy + counts), but
    /// the price/duration slider bounds are derived from the actual product set —
    /// gives an accurate, dataset-aware range without depending on the server's facet
    /// numbers.
    private func applyFirstResponseBaselines(facets: TRPTourFacets?, products: [TRPTourProduct]) {
        guard !hasLoadedInitialFacets else { return }
        facetCategories = facets?.categories ?? []
        let bounds = computeBoundsFromProducts(products)
        priceRangeFacet = bounds.price
        durationRangeFacet = bounds.duration
        hasLoadedInitialFacets = true
        delegate?.facetsDidLoad()
    }

    /// Walk the product set and produce the price + duration min/max in domain types.
    /// Returns nil for either side when there isn't a meaningful range (no priced items
    /// or all products share a single value) — the filter UI then falls back to its
    /// hardcoded bounds.
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

    /// Apply price + duration filter and sort on top of `originalTours` (the server baseline).
    /// Sort and filter are now fully local — no service request is dispatched on changes.
    /// Category and search-text changes still go through the server (they trigger
    /// `executeSearch()` which repopulates `originalTours` and re-runs this pipeline).
    private func applyLocalSortAndFilter() {
        var working = originalTours

        // Free-text search — local case-insensitive contains match on product name.
        if !searchText.isEmpty {
            working = working.filter { tour in
                tour.name.localizedCaseInsensitiveContains(searchText)
            }
        }

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
            // Push price-less tours to the end with `.greatestFiniteMagnitude`
            // (Double has no `.max`).
            working.sort { ($0.price ?? .greatestFiniteMagnitude) < ($1.price ?? .greatestFiniteMagnitude) }
        case .durationShortToLong:
            working.sort { ($0.duration ?? .max) < ($1.duration ?? .max) }
        case .durationLongToShort:
            working.sort { ($0.duration ?? .min) > ($1.duration ?? .min) }
        }

        filteredTours = working
    }
}
