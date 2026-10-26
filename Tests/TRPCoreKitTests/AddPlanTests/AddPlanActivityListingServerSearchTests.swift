import XCTest
import TRPFoundationKit
@testable import TRPCoreKit

/// Captures every `fetchTours(cityId:parameters:completion:)` call so a test can inspect the
/// request and resolve it on its own schedule.
private final class FakeTourRepository: TourRepository {
    struct Call {
        let cityId: Int
        let parameters: TourParameters
        let completion: (TourResultsValue) -> Void
    }

    var tours: [TRPTourProduct] = []
    var toursWithParameters: [TourParameters: [TRPTourProduct]] = [:]
    var capturedCalls: [Call] = []

    func fetchTours(cityId: Int, parameters: TourParameters, completion: @escaping (TourResultsValue) -> Void) {
        capturedCalls.append(Call(cityId: cityId, parameters: parameters, completion: completion))
    }

    func fetchTours(coordinate: TRPLocation, parameters: TourParameters, completion: @escaping (TourResultsValue) -> Void) {
        completion(.success(TRPTourSearchOutcome(products: [], facets: nil)))
    }

    func addTours(contentsOf: [TRPTourProduct]) {}

    func getTourSchedule(productId: String, date: String, to: String?, currency: String, lang: String, completion: @escaping (Result<TRPTourSchedule, Error>) -> Void) {}

    func lookupTourProduct(providerId: Int, productId: String, completion: @escaping (TourResultValue) -> Void) {}

    func getTourScheduleAvailability(items: [String], date: String, currency: String?, lang: String?, completion: @escaping (Result<[TRPTourScheduleAvailability], Error>) -> Void) {}
}

/// Remote API whose searches are resolved by the test, so a real `TRPTourRepository` cache
/// sits between it and the view model.
private final class CapturingTourRemoteApi: TourRemoteApi {
    struct Call {
        let parameters: TourParameters
        let completion: (TourResultsValue) -> Void
    }

    var capturedCalls: [Call] = []

    func fetchTours(cityId: Int, parameters: TourParameters, completion: @escaping (TourResultsValue) -> Void) {
        capturedCalls.append(Call(parameters: parameters, completion: completion))
    }

    func fetchTours(coordinate: TRPLocation, parameters: TourParameters, completion: @escaping (TourResultsValue) -> Void) {}

    func getTourSchedule(productId: String, date: String, to: String?, currency: String, lang: String, completion: @escaping (Result<TRPTourSchedule, Error>) -> Void) {}

    func lookupTourProduct(providerId: Int, productId: String, completion: @escaping (TourResultValue) -> Void) {}

    func getTourScheduleAvailability(items: [String], date: String, currency: String?, lang: String?, completion: @escaping (Result<[TRPTourScheduleAvailability], Error>) -> Void) {}
}

private final class FakeAddPlanActivityListingDelegate: AddPlanActivityListingViewModelDelegate {
    var loadCount = 0
    var failures: [Error] = []
    var facetsDidLoadCount = 0

    func activitiesDidLoad() { loadCount += 1 }
    func activitiesDidFail(error: Error) { failures.append(error) }
    func showLoading(_ show: Bool) {}
    func facetsDidLoad() { facetsDidLoadCount += 1 }
    func tourLoadingStateDidChange() {}
    func searchTextDidReset() {}
}

/// Pins the server-side search/filter/sort contract of `AddPlanActivityListingViewModel`:
/// every change re-fetches page 0 from the API, and stale responses from a superseded
/// search generation are dropped.
final class AddPlanActivityListingServerSearchTests: XCTestCase {

    private let city = TRPCity(id: 1, name: "Barcelona", coordinate: TRPLocation(lat: 41.38, lon: 2.17))
    private let selectedDay = Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 10))!

    private func makeProducts(count: Int, prefix: String = "p") -> [TRPTourProduct] {
        (0..<count).map { index in
            TRPTourProduct(
                id: "\(prefix)_\(index)", productId: "\(prefix)_\(index)", cityId: 1, name: "Tour \(index)",
                image: nil, gallery: nil, duration: nil, price: nil, rating: nil,
                ratingCount: nil, description: nil, webUrl: nil, phone: nil, hours: nil,
                address: nil, icon: "", coordinate: nil, categories: [], tags: [],
                distance: nil, status: true, offers: [], additionalData: nil
            )
        }
    }

    private func makeViewModel(repository: TourRepository, delegate: FakeAddPlanActivityListingDelegate) -> AddPlanActivityListingViewModel {
        var planData = AddPlanData()
        planData.selectedCity = city
        planData.selectedDay = selectedDay
        planData.travelers = 2

        let viewModel = AddPlanActivityListingViewModel(
            planData: planData,
            tourUseCases: TRPTourUseCases(repository: repository)
        )
        viewModel.delegate = delegate
        return viewModel
    }

    private func success(
        count: Int,
        total: Int,
        prefix: String = "p",
        facets: TRPTourFacets? = nil
    ) -> TourResultsValue {
        .success(TRPTourSearchOutcome(
            products: makeProducts(count: count, prefix: prefix),
            facets: facets,
            pagination: TRPTourPagination(total: total, limit: 10, offset: 0)
        ))
    }

    private func success(
        count: Int,
        total: Int,
        prefix: String = "p",
        categories: [TRPTourCategoryFacet],
        priceRange: TRPTourPriceRangeFacet? = nil,
        durationRange: TRPTourDurationRangeFacet? = nil
    ) -> TourResultsValue {
        success(
            count: count,
            total: total,
            prefix: prefix,
            facets: TRPTourFacets(categories: categories, priceRange: priceRange, durationRange: durationRange)
        )
    }

    private func categoryFacet(_ id: String, label: String? = nil) -> TRPTourCategoryFacet {
        TRPTourCategoryFacet(id: id, key: id, label: label ?? id.capitalized, count: 1)
    }

    // MARK: - Base query

    func testInitialSearchSendsUnnarrowedBaseQuery() {
        let repository = FakeTourRepository()
        let delegate = FakeAddPlanActivityListingDelegate()
        let viewModel = makeViewModel(repository: repository, delegate: delegate)

        viewModel.performInitialSearch()

        XCTAssertEqual(repository.capturedCalls.count, 1)
        let params = repository.capturedCalls[0].parameters
        XCTAssertNil(params.search)
        XCTAssertEqual(params.minPrice, 1)
        XCTAssertNil(params.maxPrice)
        XCTAssertNil(params.minDuration)
        XCTAssertNil(params.maxDuration)
        XCTAssertEqual(params.sortingBy, SortOption.popularity.apiParameters.sortingBy)
        XCTAssertEqual(params.sortingType, SortOption.popularity.apiParameters.sortingType)
        XCTAssertEqual(params.offset, 0)
        XCTAssertEqual(params.limit, 10)
    }

    // MARK: - Search text

    func testNonEmptySearchTextTriggersNewFetchWithSearchAndOffsetZero() {
        let repository = FakeTourRepository()
        let delegate = FakeAddPlanActivityListingDelegate()
        let viewModel = makeViewModel(repository: repository, delegate: delegate)

        viewModel.performInitialSearch()
        repository.capturedCalls[0].completion(success(count: 3, total: 3))

        viewModel.updateSearchText("museum")

        XCTAssertEqual(repository.capturedCalls.count, 2)
        let params = repository.capturedCalls[1].parameters
        XCTAssertEqual(params.search, "museum")
        XCTAssertEqual(params.offset, 0)
    }

    func testClearingSearchTextSendsBaseQueryAgain() {
        let repository = FakeTourRepository()
        let delegate = FakeAddPlanActivityListingDelegate()
        let viewModel = makeViewModel(repository: repository, delegate: delegate)

        viewModel.performInitialSearch()
        repository.capturedCalls[0].completion(success(count: 3, total: 3))

        viewModel.updateSearchText("museum")
        repository.capturedCalls[1].completion(success(count: 1, total: 1))

        viewModel.updateSearchText("")

        XCTAssertEqual(repository.capturedCalls.count, 3)
        let clearedParams = repository.capturedCalls[2].parameters
        let baseParams = repository.capturedCalls[0].parameters
        XCTAssertNil(clearedParams.search)
        XCTAssertEqual(clearedParams.minPrice, baseParams.minPrice)
        XCTAssertEqual(clearedParams.sortingBy, baseParams.sortingBy)
        XCTAssertEqual(clearedParams.sortingType, baseParams.sortingType)
        XCTAssertEqual(clearedParams.date, baseParams.date)
        XCTAssertEqual(clearedParams.offset, baseParams.offset)
    }

    func testRepeatingSameSearchTextTriggersOnlyOneFetch() {
        let repository = FakeTourRepository()
        let delegate = FakeAddPlanActivityListingDelegate()
        let viewModel = makeViewModel(repository: repository, delegate: delegate)

        viewModel.performInitialSearch()
        repository.capturedCalls[0].completion(success(count: 3, total: 3))

        viewModel.updateSearchText("museum")
        XCTAssertEqual(repository.capturedCalls.count, 2)

        viewModel.updateSearchText("museum")
        XCTAssertEqual(repository.capturedCalls.count, 2)
    }

    func testSearchTextIsTrimmedBeforeSending() {
        let repository = FakeTourRepository()
        let delegate = FakeAddPlanActivityListingDelegate()
        let viewModel = makeViewModel(repository: repository, delegate: delegate)

        viewModel.performInitialSearch()
        repository.capturedCalls[0].completion(success(count: 3, total: 3))

        viewModel.updateSearchText("  museum \n")

        XCTAssertEqual(repository.capturedCalls.count, 2)
        XCTAssertEqual(repository.capturedCalls[1].parameters.search, "museum")
    }

    func testWhitespaceOnlySearchTextSendsBaseQuery() {
        let repository = FakeTourRepository()
        let delegate = FakeAddPlanActivityListingDelegate()
        let viewModel = makeViewModel(repository: repository, delegate: delegate)

        viewModel.performInitialSearch()
        repository.capturedCalls[0].completion(success(count: 3, total: 3))

        viewModel.updateSearchText(" \n\t ")

        XCTAssertEqual(repository.capturedCalls.count, 2)
        XCTAssertNil(repository.capturedCalls[1].parameters.search)
        XCTAssertEqual(repository.capturedCalls[1].parameters, repository.capturedCalls[0].parameters)
    }

    func testClearingSearchServedFromCacheRebuildsBaseChipStrip() {
        let remote = CapturingTourRemoteApi()
        let delegate = FakeAddPlanActivityListingDelegate()
        let viewModel = makeViewModel(repository: TRPTourRepository(remoteApi: remote), delegate: delegate)

        viewModel.performInitialSearch()
        XCTAssertEqual(remote.capturedCalls.count, 1)
        remote.capturedCalls[0].completion(
            success(count: 3, total: 3, categories: [categoryFacet("a"), categoryFacet("b"), categoryFacet("c")])
        )
        XCTAssertEqual(viewModel.facetCategories.map { $0.id }, ["a", "b", "c"])

        viewModel.updateSearchText("x")
        XCTAssertEqual(remote.capturedCalls.count, 2)
        remote.capturedCalls[1].completion(success(count: 1, total: 1, prefix: "x", categories: [categoryFacet("a")]))
        XCTAssertEqual(viewModel.facetCategories.map { $0.id }, ["a"])
        delegate.facetsDidLoadCount = 0

        viewModel.updateSearchText("")

        XCTAssertEqual(remote.capturedCalls.count, 2)
        XCTAssertEqual(viewModel.facetCategories.map { $0.id }, ["a", "b", "c"])
        XCTAssertEqual(delegate.facetsDidLoadCount, 1)
        XCTAssertEqual(viewModel.getActivities().count, 3)
        XCTAssertEqual(viewModel.getActivityCount(), 3)
    }

    // MARK: - Filter and sort

    func testUpdateFilterDataTriggersFetchWithFilterBounds() {
        let repository = FakeTourRepository()
        let delegate = FakeAddPlanActivityListingDelegate()
        let viewModel = makeViewModel(repository: repository, delegate: delegate)

        viewModel.performInitialSearch()
        repository.capturedCalls[0].completion(success(count: 3, total: 3))

        viewModel.updateFilterData(FilterData(minPrice: 20, maxPrice: 80, minDuration: 30, maxDuration: 120))

        XCTAssertEqual(repository.capturedCalls.count, 2)
        let params = repository.capturedCalls[1].parameters
        XCTAssertEqual(params.minPrice, 20)
        XCTAssertEqual(params.maxPrice, 80)
        XCTAssertEqual(params.minDuration, 30)
        XCTAssertEqual(params.maxDuration, 120)
        XCTAssertEqual(params.offset, 0)
    }

    func testUpdateSortOptionTriggersFetchWithSortParams() {
        let repository = FakeTourRepository()
        let delegate = FakeAddPlanActivityListingDelegate()
        let viewModel = makeViewModel(repository: repository, delegate: delegate)

        viewModel.performInitialSearch()
        repository.capturedCalls[0].completion(success(count: 3, total: 3))

        viewModel.updateSortOption(.priceLowToHigh)

        XCTAssertEqual(repository.capturedCalls.count, 2)
        let params = repository.capturedCalls[1].parameters
        XCTAssertEqual(params.sortingBy, SortOption.priceLowToHigh.apiParameters.sortingBy)
        XCTAssertEqual(params.sortingType, SortOption.priceLowToHigh.apiParameters.sortingType)
        XCTAssertEqual(params.offset, 0)
    }

    // MARK: - Pagination and stale generations

    func testSearchAfterPaginationResetsOffsetAndDropsStaleResponse() {
        let repository = FakeTourRepository()
        let delegate = FakeAddPlanActivityListingDelegate()
        let viewModel = makeViewModel(repository: repository, delegate: delegate)

        viewModel.performInitialSearch()
        repository.capturedCalls[0].completion(success(count: 10, total: 25, prefix: "page0"))

        XCTAssertTrue(viewModel.loadMoreActivities())
        XCTAssertEqual(repository.capturedCalls.count, 2)
        XCTAssertEqual(repository.capturedCalls[1].parameters.offset, 10)
        let stalePageCompletion = repository.capturedCalls[1].completion

        viewModel.updateSearchText("castle")
        XCTAssertEqual(repository.capturedCalls.count, 3)
        XCTAssertEqual(repository.capturedCalls[2].parameters.offset, 0)
        XCTAssertEqual(repository.capturedCalls[2].parameters.search, "castle")

        stalePageCompletion(success(count: 10, total: 25, prefix: "stalepage"))
        XCTAssertEqual(viewModel.getActivities().count, 10)
        XCTAssertTrue(viewModel.getActivities().allSatisfy { $0.productId.hasPrefix("page0") })
        XCTAssertEqual(viewModel.getActivityCount(), 25)

        repository.capturedCalls[2].completion(success(count: 2, total: 2, prefix: "castle"))
        XCTAssertEqual(viewModel.getActivities().count, 2)
        XCTAssertTrue(viewModel.getActivities().allSatisfy { $0.productId.hasPrefix("castle") })
        XCTAssertEqual(viewModel.getActivityCount(), 2)
    }

    // MARK: - Facet category chip rebuilding

    func testLaterAllCategoriesFirstPageResponseReplacesChipStrip() {
        let repository = FakeTourRepository()
        let delegate = FakeAddPlanActivityListingDelegate()
        let viewModel = makeViewModel(repository: repository, delegate: delegate)

        viewModel.performInitialSearch()
        repository.capturedCalls[0].completion(success(count: 1, total: 1, categories: [categoryFacet("a"), categoryFacet("b")]))
        XCTAssertEqual(viewModel.facetCategories.map { $0.id }, ["a", "b"])
        XCTAssertEqual(delegate.facetsDidLoadCount, 1)

        viewModel.updateSortOption(.priceLowToHigh)
        repository.capturedCalls[1].completion(success(count: 1, total: 1, categories: [categoryFacet("c")]))
        XCTAssertEqual(viewModel.facetCategories.map { $0.id }, ["c"])
        XCTAssertEqual(delegate.facetsDidLoadCount, 2)

        viewModel.updateSearchText("castle")
        repository.capturedCalls[2].completion(success(count: 1, total: 1, categories: [categoryFacet("a"), categoryFacet("c")]))
        XCTAssertEqual(viewModel.facetCategories.map { $0.id }, ["a", "c"])
        XCTAssertEqual(delegate.facetsDidLoadCount, 3)
    }

    func testSelectedCategoryIdsAreSentSorted() {
        let repository = FakeTourRepository()
        let delegate = FakeAddPlanActivityListingDelegate()
        let viewModel = makeViewModel(repository: repository, delegate: delegate)

        viewModel.selectedFacetCategoryIds = ["zoo", "art", "museum", "boat"]
        viewModel.performInitialSearch()
        viewModel.updateSortOption(.priceLowToHigh)
        viewModel.updateSortOption(.popularity)

        XCTAssertEqual(repository.capturedCalls.count, 3)
        repository.capturedCalls.forEach { call in
            XCTAssertEqual(call.parameters.categoryIds, ["art", "boat", "museum", "zoo"])
        }
        XCTAssertEqual(repository.capturedCalls[2].parameters, repository.capturedCalls[0].parameters)
    }

    func testResponseToCategoryFilteredRequestDoesNotChangeChipStrip() {
        let repository = FakeTourRepository()
        let delegate = FakeAddPlanActivityListingDelegate()
        let viewModel = makeViewModel(repository: repository, delegate: delegate)

        viewModel.performInitialSearch()
        repository.capturedCalls[0].completion(success(count: 1, total: 1, categories: [categoryFacet("a"), categoryFacet("b")]))
        XCTAssertEqual(viewModel.facetCategories.map { $0.id }, ["a", "b"])
        delegate.facetsDidLoadCount = 0

        viewModel.toggleFacetCategory(id: "a")
        XCTAssertEqual(repository.capturedCalls.count, 2)
        XCTAssertEqual(repository.capturedCalls[1].parameters.categoryIds, ["a"])

        viewModel.selectedFacetCategoryIds = []
        repository.capturedCalls[1].completion(success(count: 1, total: 1, categories: [categoryFacet("x"), categoryFacet("y")]))

        XCTAssertEqual(viewModel.facetCategories.map { $0.id }, ["a", "b"])
        XCTAssertEqual(viewModel.selectedFacetCategoryIds, [])
        XCTAssertEqual(delegate.facetsDidLoadCount, 0)
    }

    func testStaleAllCategoriesResponseAfterFilteredRequestDoesNotRebuildChipStrip() {
        let repository = FakeTourRepository()
        let delegate = FakeAddPlanActivityListingDelegate()
        let viewModel = makeViewModel(repository: repository, delegate: delegate)

        viewModel.performInitialSearch()
        repository.capturedCalls[0].completion(success(count: 1, total: 1, categories: [categoryFacet("a"), categoryFacet("b")]))
        delegate.facetsDidLoadCount = 0

        viewModel.updateSortOption(.priceLowToHigh)
        XCTAssertNil(repository.capturedCalls[1].parameters.categoryIds)
        viewModel.toggleFacetCategory(id: "a")
        XCTAssertEqual(repository.capturedCalls.count, 3)
        XCTAssertEqual(repository.capturedCalls[2].parameters.categoryIds, ["a"])

        repository.capturedCalls[1].completion(success(count: 1, total: 1, categories: [categoryFacet("c")]))
        XCTAssertEqual(viewModel.facetCategories.map { $0.id }, ["a", "b"])
        XCTAssertEqual(viewModel.selectedFacetCategoryIds, ["a"])

        repository.capturedCalls[2].completion(success(count: 1, total: 1, categories: [categoryFacet("a")]))
        XCTAssertEqual(viewModel.facetCategories.map { $0.id }, ["a", "b"])
        XCTAssertEqual(viewModel.selectedFacetCategoryIds, ["a"])
        XCTAssertEqual(delegate.facetsDidLoadCount, 0)
    }

    func testFirstResponseWithPresetSelectionSeedsChipStripWithoutDroppingSelection() {
        let repository = FakeTourRepository()
        let delegate = FakeAddPlanActivityListingDelegate()
        let viewModel = makeViewModel(repository: repository, delegate: delegate)

        viewModel.selectedFacetCategoryIds = ["a", "z"]
        viewModel.performInitialSearch()
        XCTAssertEqual(Set(repository.capturedCalls[0].parameters.categoryIds ?? []), ["a", "z"])

        repository.capturedCalls[0].completion(success(count: 1, total: 1, categories: [categoryFacet("a"), categoryFacet("b")]))

        XCTAssertEqual(viewModel.facetCategories.map { $0.id }, ["a", "b"])
        XCTAssertEqual(viewModel.selectedFacetCategoryIds, ["a", "z"])
        XCTAssertFalse(viewModel.isFacetsLoading())
        XCTAssertEqual(delegate.facetsDidLoadCount, 1)

        viewModel.updateSortOption(.priceLowToHigh)
        repository.capturedCalls[1].completion(success(count: 1, total: 1, categories: [categoryFacet("c")]))
        XCTAssertEqual(viewModel.facetCategories.map { $0.id }, ["a", "b"])
        XCTAssertEqual(delegate.facetsDidLoadCount, 1)
    }

    func testEmptyCategoriesAndNilFacetsKeepPreviousChipStrip() {
        let repository = FakeTourRepository()
        let delegate = FakeAddPlanActivityListingDelegate()
        let viewModel = makeViewModel(repository: repository, delegate: delegate)

        viewModel.performInitialSearch()
        repository.capturedCalls[0].completion(success(count: 1, total: 1, categories: [categoryFacet("a"), categoryFacet("b")]))
        XCTAssertEqual(viewModel.facetCategories.map { $0.id }, ["a", "b"])
        delegate.facetsDidLoadCount = 0

        viewModel.updateSortOption(.priceLowToHigh)
        repository.capturedCalls[1].completion(success(count: 1, total: 1, categories: []))
        XCTAssertEqual(viewModel.facetCategories.map { $0.id }, ["a", "b"])

        viewModel.updateSearchText("castle")
        repository.capturedCalls[2].completion(success(count: 1, total: 1))
        XCTAssertEqual(viewModel.facetCategories.map { $0.id }, ["a", "b"])
        XCTAssertEqual(delegate.facetsDidLoadCount, 0)
    }

    func testPaginationResponseNeverRebuildsChipStrip() {
        let repository = FakeTourRepository()
        let delegate = FakeAddPlanActivityListingDelegate()
        let viewModel = makeViewModel(repository: repository, delegate: delegate)

        viewModel.performInitialSearch()
        repository.capturedCalls[0].completion(success(count: 10, total: 25, categories: [categoryFacet("a"), categoryFacet("b")]))
        XCTAssertEqual(viewModel.facetCategories.map { $0.id }, ["a", "b"])
        delegate.facetsDidLoadCount = 0

        XCTAssertTrue(viewModel.loadMoreActivities())
        repository.capturedCalls[1].completion(success(count: 10, total: 25, prefix: "page2", categories: [categoryFacet("c"), categoryFacet("d")]))

        XCTAssertEqual(viewModel.facetCategories.map { $0.id }, ["a", "b"])
        XCTAssertEqual(delegate.facetsDidLoadCount, 0)
    }

    func testSelectedCategoriesAreIntersectedWithRebuiltChips() {
        let repository = FakeTourRepository()
        let delegate = FakeAddPlanActivityListingDelegate()
        let viewModel = makeViewModel(repository: repository, delegate: delegate)

        viewModel.performInitialSearch()
        viewModel.selectedFacetCategoryIds = ["a", "gone"]

        repository.capturedCalls[0].completion(success(count: 1, total: 1, categories: [categoryFacet("a"), categoryFacet("b")]))

        XCTAssertEqual(viewModel.selectedFacetCategoryIds, ["a"])
        XCTAssertFalse(viewModel.isCategoryChipSelected(at: 0))
    }

    func testSelectedCategoriesBecomeEmptyWhenAllVanish() {
        let repository = FakeTourRepository()
        let delegate = FakeAddPlanActivityListingDelegate()
        let viewModel = makeViewModel(repository: repository, delegate: delegate)

        viewModel.performInitialSearch()
        viewModel.selectedFacetCategoryIds = ["gone1", "gone2"]

        repository.capturedCalls[0].completion(success(count: 1, total: 1, categories: [categoryFacet("a"), categoryFacet("b")]))

        XCTAssertTrue(viewModel.selectedFacetCategoryIds.isEmpty)
        XCTAssertTrue(viewModel.isCategoryChipSelected(at: 0))
    }

    func testPriceAndDurationFacetsStayFromFirstResponseAcrossLaterResponses() {
        let repository = FakeTourRepository()
        let delegate = FakeAddPlanActivityListingDelegate()
        let viewModel = makeViewModel(repository: repository, delegate: delegate)

        let firstPrice = TRPTourPriceRangeFacet(minAmount: 10, maxAmount: 100, currency: "EUR")
        let firstDuration = TRPTourDurationRangeFacet(minMinutes: 30, maxMinutes: 180)

        viewModel.performInitialSearch()
        repository.capturedCalls[0].completion(
            success(count: 1, total: 1, categories: [categoryFacet("a")], priceRange: firstPrice, durationRange: firstDuration)
        )
        XCTAssertEqual(viewModel.priceRangeFacet, firstPrice)
        XCTAssertEqual(viewModel.durationRangeFacet, firstDuration)

        let secondPrice = TRPTourPriceRangeFacet(minAmount: 5, maxAmount: 50, currency: "USD")
        let secondDuration = TRPTourDurationRangeFacet(minMinutes: 10, maxMinutes: 20)

        viewModel.updateSortOption(.priceLowToHigh)
        repository.capturedCalls[1].completion(
            success(count: 1, total: 1, categories: [categoryFacet("b")], priceRange: secondPrice, durationRange: secondDuration)
        )

        XCTAssertEqual(viewModel.priceRangeFacet, firstPrice)
        XCTAssertEqual(viewModel.durationRangeFacet, firstDuration)
    }
}
