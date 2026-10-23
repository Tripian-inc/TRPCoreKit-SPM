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

private final class FakeAddPlanActivityListingDelegate: AddPlanActivityListingViewModelDelegate {
    var loadCount = 0
    var failures: [Error] = []

    func activitiesDidLoad() { loadCount += 1 }
    func activitiesDidFail(error: Error) { failures.append(error) }
    func showLoading(_ show: Bool) {}
    func facetsDidLoad() {}
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

    private func makeViewModel(repository: FakeTourRepository, delegate: FakeAddPlanActivityListingDelegate) -> AddPlanActivityListingViewModel {
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

    private func success(count: Int, total: Int, prefix: String = "p") -> TourResultsValue {
        .success(TRPTourSearchOutcome(
            products: makeProducts(count: count, prefix: prefix),
            facets: nil,
            pagination: TRPTourPagination(total: total, limit: 10, offset: 0)
        ))
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
}
