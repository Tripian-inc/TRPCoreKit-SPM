//
//  AddPlanPOIListingViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 30.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

// POIListingCategoryType is defined in TRPPoiUseCases

public protocol AddPlanPOIListingViewModelDelegate: ViewModelDelegate {
    func poisDidLoad()
    func segmentCreatedSuccessfully()
    /// Fired whenever `loadingStyle` changes so the VC can swap between full-screen
    /// Lottie / inline skeleton / no-loader UIs without a full reload pass.
    func poiLoadingStateDidChange()
}

// Default implementation so existing conformers don't have to add the method until they
// adopt the new loading-style UI.
public extension AddPlanPOIListingViewModelDelegate {
    func poiLoadingStateDidChange() {}
}

public class AddPlanPOIListingViewModel {

    // MARK: - Properties
    public let planData: AddPlanData
    public let categoryType: POIListingCategoryType
    public weak var delegate: AddPlanPOIListingViewModelDelegate?

    public var searchText: String = ""
    public var selectedSortOption: SortOption = .popularity
    public var filterData: POIFilterData = POIFilterData()

    private var allPois: [TRPPoi] = []
    private var filteredPois: [TRPPoi] = []
    private var categoryIds: [Int] = []
    private var allCategoryIds: [Int] = [] // Store all category IDs for reset

    private var poiUseCases: TRPPoiUseCases
    private var timelineRepository: TRPTimelineRepository
    private var searchWorkItem: DispatchWorkItem?
    private var isLoadingMore: Bool = false
    private var currentPage: Int = 1
    private var totalPages: Int = 1
    private var totalPoiCount: Int = 0
    private var hasMorePages: Bool = false

    /// Drives which loading UI the listing screen renders. Mirrors `AddPlanLoadingStyle`
    /// in Activity Listing — `.lottie` for first open + heavy refetches (filter / search /
    /// sort / category change), `.skeleton` for inline refetches, `.none` when idle. The
    /// VC observes this via `poiLoadingStateDidChange()`.
    private(set) public var loadingStyle: AddPlanLoadingStyle = .none

    /// Strong reference held during the post-add timeline-regeneration poll. Cleared once
    /// `allSegmentGenerated` fires so it doesn't leak across adds.
    private var checkAllPlanUseCase: TRPTimelineCheckAllPlanUseCases?

    // MARK: - Initialization
    public init(planData: AddPlanData, categoryType: POIListingCategoryType) {
        self.planData = planData
        self.categoryType = categoryType
        self.poiUseCases = TRPPoiUseCases.shared
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

    /// Returns whether there are more POIs available to load
    public func hasMorePoisAvailable() -> Bool {
        return hasMorePages
    }

    /// Returns the total POI count from API
    public func getTotalPoiCount() -> Int {
        return totalPoiCount
    }

    /// Returns formatted string for POI count display
    /// Shows total count from API pagination info
    public func getPoiCountDisplayString() -> String {
        let count = totalPoiCount > 0 ? totalPoiCount : filteredPois.count
        let placeText = count == 1
            ? AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.place)
            : AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.places)

        return "\(count) \(placeText)"
    }

    public func updateSearchText(_ text: String) {
        searchText = text
        performSearchWithDebounce()
    }

    public func updateSortOption(_ option: SortOption) {
        selectedSortOption = option

        // Sort is server-side — pagination breaks if we only re-sort the loaded subset,
        // so reset pagination and refetch from page 1 with the new sort.
        currentPage = 1
        totalPages = 1
        totalPoiCount = 0
        hasMorePages = false
        allPois = []
        filteredPois = []

        loadingStyle = .skeleton
        delegate?.poiLoadingStateDidChange()
        delegate?.poisDidLoad()
        fetchPois()
    }

    public func updateFilterData(_ newFilterData: POIFilterData) {
        filterData = newFilterData

        // If filter has selected categories, use them; otherwise use all categories
        if filterData.selectedCategoryIds.isEmpty {
            categoryIds = allCategoryIds
        } else {
            categoryIds = Array(filterData.selectedCategoryIds)
        }

        // Re-fetch POIs with new category filter — skeleton mode while fetch is in flight.
        currentPage = 1
        totalPages = 1
        totalPoiCount = 0
        hasMorePages = false
        allPois = []
        filteredPois = []

        loadingStyle = .skeleton
        delegate?.poiLoadingStateDidChange()
        delegate?.poisDidLoad()
        fetchPois()
    }

    // MARK: - Data Fetching
    public func performInitialFetch() {
        fetchCategoriesAndPois()
    }

    private func fetchCategoriesAndPois() {
        // Reset pagination
        currentPage = 1
        totalPages = 1
        totalPoiCount = 0
        hasMorePages = false

        // Initial fetch → full-screen Lottie ("Getting Places"). The VC handles the
        // window-attached overlay based on `loadingStyle == .lottie`.
        loadingStyle = .lottie
        delegate?.poiLoadingStateDidChange()

        // Use cached categories if available, otherwise fetch
        poiUseCases.fetchCategoryIdsIfNeeded(type: categoryType) { [weak self] ids in
            guard let self = self else { return }
            self.allCategoryIds = ids // Store all categories for filter reset
            self.categoryIds = ids
            self.fetchPois()
        }
    }

    private func fetchPois(page: Int = 1) {
        guard let cityId = planData.selectedCity?.id else {
            // Tear down whatever loading style was set so we don't strand the UI in a
            // skeleton/lottie state when there's no city to fetch for.
            loadingStyle = .none
            delegate?.poiLoadingStateDidChange()
            delegate?.viewModel(error: GeneralError.customMessage("City not selected"))
            return
        }

        poiUseCases.executeSearchPoi(
            text: searchText,
            categories: categoryIds,
            cityId: cityId,
            page: page,
            sort: selectedSortOption.poiSortQuery
        ) { [weak self] result, pagination in
            self?.handleSearchResult(result: result, pagination: pagination, isLoadMore: page > 1, requestedPage: page)
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
        totalPoiCount = 0
        hasMorePages = false
        filteredPois = []

        // Search debounce → skeleton mode while server roundtrips.
        loadingStyle = .skeleton
        delegate?.poiLoadingStateDidChange()
        delegate?.poisDidLoad()

        poiUseCases.executeSearchPoi(
            text: searchText,
            categories: categoryIds,
            cityId: cityId,
            page: 1,
            sort: selectedSortOption.poiSortQuery
        ) { [weak self] result, pagination in
            self?.handleSearchResult(result: result, pagination: pagination, isLoadMore: false, requestedPage: 1)
        }
    }

    private func handleSearchResult(result: Result<[TRPPoi], Error>, pagination: TRPPagination?, isLoadMore: Bool = false, requestedPage: Int = 1) {
        // Drop the active loading style (lottie / skeleton) — load-more pagination keeps
        // `.none` since it has its own footer indicator.
        loadingStyle = .none
        delegate?.poiLoadingStateDidChange()
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

            // Update currentPage only for initial fetch (loadMore already increments it)
            if !isLoadMore {
                currentPage = requestedPage
            }

            // Update pagination info from TRPPagination
            if let pagination = pagination {
                switch pagination {
                case .completed:
                    totalPages = currentPage
                    hasMorePages = false
                    // When completed, total count is the loaded count
                    if !isLoadMore {
                        totalPoiCount = pois.count
                    }
                case .continues(let paginationInfo):
                    // Extract pagination info from API response
                    totalPages = paginationInfo.totalPages
                    totalPoiCount = paginationInfo.total
                    hasMorePages = paginationInfo.hasMore
                }
            } else {
                hasMorePages = false
                totalPoiCount = pois.count
            }

            filterPois()
            delegate?.poisDidLoad()
        case .failure(let error):
            // Reload so the table flips out of skeleton mode (loadingStyle is already
            // `.none` above) and renders the empty/previous state behind the alert.
            delegate?.poisDidLoad()
            delegate?.viewModel(error: error)
        }
    }

    // MARK: - Pagination
    public func hasMorePois() -> Bool {
        return hasMorePages
    }

    public func loadMorePois() {
        guard !isLoadingMore, hasMorePois() else { return }

        isLoadingMore = true
        currentPage += 1  // Increment immediately before request

        fetchPois(page: currentPage)
    }

    private func filterPois() {
        // Server returns POIs already in the requested sort order — we only apply the
        // local search-text filter on top of the loaded page set.
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

        // Loader is owned by the VC (bottom-sheet Lottie shown before this call). VM no
        // longer drives `showPreloader` — it just runs the create + polling cycle and
        // signals completion via `segmentCreatedSuccessfully`.

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

        // Call repository to create segment, then wait for timeline regeneration before
        // signaling success. VC keeps its bottom-sheet Lottie loader visible through both
        // phases so the user sees one continuous "Adding…" state.
        timelineRepository.createEditTimelineSegment(profile: segment) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.waitForTimelineRefreshAfterCreation(tripHash: tripHash)
                case .failure(let error):
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }

    /// Poll for segment-generation completion after a successful manual-POI create.
    /// Mirrors `AddPlanTimeSelectionViewModel.waitForTimelineRefreshAfterCreation` so the
    /// host's `TRPTimelineRefreshState` observer drives a silent timeline refresh.
    private func waitForTimelineRefreshAfterCreation(tripHash: String) {
        TRPTimelineRefreshState.shared.setRefreshing()

        let timelineRepo = TRPTimelineRepository()
        let modelRepo = TRPTimelineModelRepository()
        checkAllPlanUseCase = TRPTimelineCheckAllPlanUseCases(
            timelineRepository: timelineRepo,
            timelineModelRepository: modelRepo
        )

        checkAllPlanUseCase?.allSegmentGenerated.addObserver(self) { [weak self] isGenerated in
            guard let self = self, isGenerated else { return }
            DispatchQueue.main.async {
                TRPTimelineRefreshState.shared.setCompleted()
                self.checkAllPlanUseCase = nil
                self.delegate?.segmentCreatedSuccessfully()
            }
        }

        checkAllPlanUseCase?.executeFetchTimelineCheckAllPlanGenerate(tripHash: tripHash) { [weak self] result in
            guard let self = self else { return }
            if case .failure(let error) = result {
                DispatchQueue.main.async {
                    TRPTimelineRefreshState.shared.setFailed(error)
                    self.checkAllPlanUseCase = nil
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }
}
