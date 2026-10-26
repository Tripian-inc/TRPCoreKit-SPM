import XCTest
import TRPFoundationKit
@testable import TRPCoreKit

/// Counts every remote search and answers it with a preset outcome.
private final class FakeTourRemoteApi: TourRemoteApi {
    var outcome = TRPTourSearchOutcome(products: [], facets: nil)
    private(set) var cityCalls: [TourParameters] = []
    private(set) var coordinateCalls: [TourParameters] = []

    func fetchTours(cityId: Int, parameters: TourParameters, completion: @escaping (TourResultsValue) -> Void) {
        cityCalls.append(parameters)
        completion(.success(outcome))
    }

    func fetchTours(coordinate: TRPLocation, parameters: TourParameters, completion: @escaping (TourResultsValue) -> Void) {
        coordinateCalls.append(parameters)
        completion(.success(outcome))
    }

    func getTourSchedule(productId: String, date: String, to: String?, currency: String, lang: String, completion: @escaping (Result<TRPTourSchedule, Error>) -> Void) {}

    func lookupTourProduct(providerId: Int, productId: String, completion: @escaping (TourResultValue) -> Void) {}

    func getTourScheduleAvailability(items: [String], date: String, currency: String?, lang: String?, completion: @escaping (Result<[TRPTourScheduleAvailability], Error>) -> Void) {}
}

/// Pins that a `TRPTourRepository` cache hit replays the full network response shape.
final class TRPTourRepositoryCacheTests: XCTestCase {

    private let facets = TRPTourFacets(
        categories: [
            TRPTourCategoryFacet(id: "a", key: "a", label: "A", count: 3),
            TRPTourCategoryFacet(id: "b", key: "b", label: "B", count: 1)
        ],
        priceRange: TRPTourPriceRangeFacet(minAmount: 10, maxAmount: 90, currency: "EUR"),
        durationRange: TRPTourDurationRangeFacet(minMinutes: 30, maxMinutes: 240)
    )
    private let pagination = TRPTourPagination(total: 42, limit: 10, offset: 0)

    private func makeProducts(count: Int) -> [TRPTourProduct] {
        (0..<count).map { index in
            TRPTourProduct(
                id: "p_\(index)", productId: "p_\(index)", cityId: 1, name: "Tour \(index)",
                image: nil, gallery: nil, duration: nil, price: nil, rating: nil,
                ratingCount: nil, description: nil, webUrl: nil, phone: nil, hours: nil,
                address: nil, icon: "", coordinate: nil, categories: [], tags: [],
                distance: nil, status: true, offers: [], additionalData: nil
            )
        }
    }

    private func makeParameters() -> TourParameters {
        var params = TourParameters()
        params.date = "2026-03-10"
        params.dateTo = "2026-03-10"
        params.minPrice = 1
        params.limit = 10
        params.offset = 0
        return params
    }

    private func fetch(_ repository: TRPTourRepository, cityId: Int, parameters: TourParameters) -> TRPTourSearchOutcome? {
        var received: TRPTourSearchOutcome?
        repository.fetchTours(cityId: cityId, parameters: parameters) { result in
            if case .success(let outcome) = result { received = outcome }
        }
        return received
    }

    private func fetch(_ repository: TRPTourRepository, coordinate: TRPLocation, parameters: TourParameters) -> TRPTourSearchOutcome? {
        var received: TRPTourSearchOutcome?
        repository.fetchTours(coordinate: coordinate, parameters: parameters) { result in
            if case .success(let outcome) = result { received = outcome }
        }
        return received
    }

    func testSecondIdenticalCitySearchIsServedFromCacheWithSameFacetsAndPagination() {
        let remote = FakeTourRemoteApi()
        remote.outcome = TRPTourSearchOutcome(products: makeProducts(count: 3), facets: facets, pagination: pagination)
        let repository = TRPTourRepository(remoteApi: remote)

        let first = fetch(repository, cityId: 1, parameters: makeParameters())
        let second = fetch(repository, cityId: 1, parameters: makeParameters())

        XCTAssertEqual(remote.cityCalls.count, 1)
        XCTAssertEqual(first?.facets, facets)
        XCTAssertEqual(second?.facets, first?.facets)
        XCTAssertEqual(second?.pagination, pagination)
        XCTAssertEqual(second?.products.map { $0.productId }, first?.products.map { $0.productId })
    }

    func testDifferentParametersMissTheCache() {
        let remote = FakeTourRemoteApi()
        remote.outcome = TRPTourSearchOutcome(products: makeProducts(count: 3), facets: facets, pagination: pagination)
        let repository = TRPTourRepository(remoteApi: remote)

        var searchParams = makeParameters()
        searchParams.search = "x"

        _ = fetch(repository, cityId: 1, parameters: makeParameters())
        _ = fetch(repository, cityId: 1, parameters: searchParams)

        XCTAssertEqual(remote.cityCalls.count, 2)
    }

    func testCacheHitKeepsFacetsOfItsOwnEntry() {
        let remote = FakeTourRemoteApi()
        let repository = TRPTourRepository(remoteApi: remote)
        let narrowedFacets = TRPTourFacets(
            categories: [TRPTourCategoryFacet(id: "a", key: "a", label: "A", count: 1)],
            priceRange: nil,
            durationRange: nil
        )
        var searchParams = makeParameters()
        searchParams.search = "x"

        remote.outcome = TRPTourSearchOutcome(products: makeProducts(count: 3), facets: facets, pagination: pagination)
        _ = fetch(repository, cityId: 1, parameters: makeParameters())
        remote.outcome = TRPTourSearchOutcome(products: makeProducts(count: 1), facets: narrowedFacets, pagination: nil)
        _ = fetch(repository, cityId: 1, parameters: searchParams)

        let cachedBase = fetch(repository, cityId: 1, parameters: makeParameters())
        let cachedSearch = fetch(repository, cityId: 1, parameters: searchParams)

        XCTAssertEqual(remote.cityCalls.count, 2)
        XCTAssertEqual(cachedBase?.facets, facets)
        XCTAssertEqual(cachedSearch?.facets, narrowedFacets)
        XCTAssertNil(cachedSearch?.pagination)
    }

    func testSecondIdenticalCoordinateSearchIsServedFromCacheWithSameFacets() {
        let remote = FakeTourRemoteApi()
        remote.outcome = TRPTourSearchOutcome(products: makeProducts(count: 2), facets: facets, pagination: pagination)
        let repository = TRPTourRepository(remoteApi: remote)
        let location = TRPLocation(lat: 41.38, lon: 2.17)

        let first = fetch(repository, coordinate: location, parameters: makeParameters())
        let second = fetch(repository, coordinate: location, parameters: makeParameters())

        XCTAssertEqual(remote.coordinateCalls.count, 1)
        XCTAssertEqual(first?.facets, facets)
        XCTAssertEqual(second?.facets, facets)
        XCTAssertEqual(second?.pagination, first?.pagination)
    }
}
