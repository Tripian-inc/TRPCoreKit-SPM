//
//  AddPlanPOIListingViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 30.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

public protocol AddPlanPOIListingViewModelDelegate: ViewModelDelegate {
    func poisDidLoad()
    func segmentCreatedSuccessfully()
    /// Fired when `loadingStyle` changes so the VC can swap loading UIs without a full reload.
    func poiLoadingStateDidChange()
}

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
    private var allCategoryIds: [Int] = []

    private var poiUseCases: TRPPoiUseCases
    private var timelineRepository: TRPTimelineRepository
    private var isLoadingMore: Bool = false
    private var currentPage: Int = 1
    private var totalPages: Int = 1
    private var totalPoiCount: Int = 0
    private var hasMorePages: Bool = false

    /// Drives the listing's loading UI: `.lottie` for first open / heavy refetches, `.skeleton` for inline refetches, `.none` when idle.
    private(set) public var loadingStyle: AddPlanLoadingStyle = .none

    /// Held during the post-add regeneration poll; cleared when `allSegmentGenerated` fires so it doesn't leak across adds.
    private var checkAllPlanUseCase: TRPTimelineCheckAllPlanUseCases?

    /// "yyyy-MM-dd" → POI ids that day already holds. Seeded from the timeline this screen was
    /// opened with and kept up to date locally as places are added.
    public var poiIdsByDay: [String: [String]] = [:]

    // MARK: - Initialization
    public init(planData: AddPlanData, categoryType: POIListingCategoryType) {
        self.planData = planData
        self.categoryType = categoryType
        self.poiUseCases = TRPPoiUseCases.shared
        self.timelineRepository = TRPTimelineRepository()

        if let cityId = planData.selectedCity?.id {
            self.poiUseCases.cityId = cityId
        }
    }

    // MARK: - Public Methods

    /// True when the chosen day already holds `poi`, so it must not be added again.
    public func isPlannedOnSelectedDay(_ poi: TRPPoi) -> Bool {
        guard let day = selectedDayKey() else { return false }
        return poiIdsByDay[day]?.contains(poi.id) ?? false
    }

    private func selectedDayKey() -> String? {
        guard let day = planData.selectedDay else { return nil }
        return TRPDateHelper.formatDateString(day)
    }

    private func markPoiAdded(_ poi: TRPPoi) {
        guard let day = selectedDayKey() else { return }
        guard !(poiIdsByDay[day]?.contains(poi.id) ?? false) else { return }
        poiIdsByDay[day, default: []].append(poi.id)
    }

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

    public func hasMorePoisAvailable() -> Bool {
        return hasMorePages
    }

    public func getTotalPoiCount() -> Int {
        return totalPoiCount
    }

    public func getPoiCountDisplayString() -> String {
        let count = totalPoiCount > 0 ? totalPoiCount : filteredPois.count
        let placeText = count == 1
            ? AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.place)
            : AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.places)

        return "\(count) \(placeText)"
    }

    /// The search bar debounces typing; an empty query reloads the full list.
    public func updateSearchText(_ text: String) {
        searchText = text
        performSearch()
    }

    public func updateSortOption(_ option: SortOption) {
        selectedSortOption = option

        // Sort is server-side: reset pagination and refetch from page 1 (re-sorting the loaded subset would break pagination).
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

        if filterData.selectedCategoryIds.isEmpty {
            categoryIds = allCategoryIds
        } else {
            categoryIds = Array(filterData.selectedCategoryIds)
        }

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
        currentPage = 1
        totalPages = 1
        totalPoiCount = 0
        hasMorePages = false

        loadingStyle = .lottie
        delegate?.poiLoadingStateDidChange()

        poiUseCases.fetchCategoryIdsIfNeeded(type: categoryType) { [weak self] ids in
            guard let self = self else { return }
            self.allCategoryIds = ids
            self.categoryIds = ids
            self.fetchPois()
        }
    }

    private func fetchPois(page: Int = 1) {
        guard let cityId = planData.selectedCity?.id else {
            // No city to fetch for — clear the loading style so the UI isn't stranded in skeleton/lottie.
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

    private func performSearch() {
        guard let cityId = planData.selectedCity?.id else {
            delegate?.viewModel(error: GeneralError.customMessage("City not selected"))
            return
        }

        currentPage = 1
        totalPages = 1
        totalPoiCount = 0
        hasMorePages = false
        filteredPois = []

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
        loadingStyle = .none
        delegate?.poiLoadingStateDidChange()
        isLoadingMore = false

        switch result {
        case .success(let pois):
            if isLoadMore {
                allPois.append(contentsOf: pois)
            } else {
                allPois = pois
            }

            // loadMore already increments currentPage.
            if !isLoadMore {
                currentPage = requestedPage
            }

            if let pagination = pagination {
                switch pagination {
                case .completed:
                    totalPages = currentPage
                    hasMorePages = false
                    if !isLoadMore {
                        totalPoiCount = pois.count
                    }
                case .continues(let paginationInfo):
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
            // Reload so the table flips out of skeleton mode and renders the previous state behind the alert.
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
        currentPage += 1

        fetchPois(page: currentPage)
    }

    private func filterPois() {
//        if searchText.isEmpty {
            filteredPois = allPois
//        } else {
//            filteredPois = allPois.filter { poi in
//                poi.name.localizedCaseInsensitiveContains(searchText)
//            }
//        }
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

        let segment = TRPCreateEditTimelineSegmentProfile(tripHash: tripHash)
        segment.segmentType = .manualPoi
        segment.available = false
        segment.title = poi.name
        segment.poiId = poi.id
        segment.city = selectedCity

        // Prefer the POI coordinate; fall back to the city's via `resolvedCoordinate()` (which consults TRPCityCache, since the in-memory city coord can be a (0,0) placeholder).
        if let poiCoordinate = poi.coordinate, !poiCoordinate.isMissingOrZero {
            segment.coordinate = poiCoordinate
        } else if let cityCoordinate = selectedCity.resolvedCoordinate() {
            segment.coordinate = cityCoordinate
        } else {
            segment.coordinate = poi.coordinate
        }

        segment.includePoiIds = [poi.id]

        let calendar = Calendar.current

        let dayComponents = calendar.dateComponents([.year, .month, .day], from: selectedDay)
        let startTimeComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endTimeComponents = calendar.dateComponents([.hour, .minute], from: endTime)

        var startDateComponents = DateComponents()
        startDateComponents.year = dayComponents.year
        startDateComponents.month = dayComponents.month
        startDateComponents.day = dayComponents.day
        startDateComponents.hour = startTimeComponents.hour
        startDateComponents.minute = startTimeComponents.minute

        var endDateComponents = DateComponents()
        endDateComponents.year = dayComponents.year
        endDateComponents.month = dayComponents.month
        endDateComponents.day = dayComponents.day
        endDateComponents.hour = endTimeComponents.hour
        endDateComponents.minute = endTimeComponents.minute

        let combinedStartDate = calendar.date(from: startDateComponents) ?? selectedDay
        let combinedEndDate = calendar.date(from: endDateComponents) ?? selectedDay

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        segment.startDate = dateFormatter.string(from: combinedStartDate)
        segment.endDate = dateFormatter.string(from: combinedEndDate)

        // Create, then poll for regeneration before signaling success (VC keeps its loader up through both phases).
        timelineRepository.createEditTimelineSegment(profile: segment) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.markPoiAdded(poi)
                    self.waitForTimelineRefreshAfterCreation(tripHash: tripHash)
                case .failure(let error):
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }

    /// Polls for segment-generation completion so the host's `TRPTimelineRefreshState` observer drives a silent refresh.
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
