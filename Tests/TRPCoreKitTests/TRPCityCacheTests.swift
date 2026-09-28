//
//  TRPCityCacheTests.swift
//  TRPCoreKitTests
//
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import XCTest
import TRPFoundationKit
@testable import TRPCoreKit

final class TRPCityCacheTests: XCTestCase {

    private final class FakeCityRemoteApi: CityRemoteApi {
        private let lock = NSLock()
        private var _fetchCitiesCallCount = 0
        private var pendingCompletions: [(CityResultsValue) -> Void] = []

        var result: CityResultsValue?
        var onFetchCalled: (() -> Void)?

        var fetchCitiesCallCount: Int {
            lock.lock(); defer { lock.unlock() }
            return _fetchCitiesCallCount
        }

        func fetchCities(completion: @escaping (CityResultsValue) -> Void) {
            lock.lock()
            _fetchCitiesCallCount += 1
            let immediateResult = result
            if immediateResult == nil {
                pendingCompletions.append(completion)
            }
            lock.unlock()
            onFetchCalled?()
            if let immediateResult = immediateResult {
                completion(immediateResult)
            }
        }

        func completePendingFetch(with result: CityResultsValue) {
            lock.lock()
            let completions = pendingCompletions
            pendingCompletions = []
            lock.unlock()
            completions.forEach { $0(result) }
        }

        func fetchCity(cityId: Int, completion: @escaping (CityResultValue) -> Void) {
            fatalError("not used by TRPCityCache")
        }

        func fetchShorexCities(completion: @escaping (CityResultsValue) -> Void) {
            fatalError("not used by TRPCityCache")
        }

        func fetchCityInformation(cityId: Int, completion: @escaping (CityInformationResultValue) -> Void) {
            fatalError("not used by TRPCityCache")
        }

        func fetchCityByName(_ name: String, completion: @escaping (CityResultValue) -> Void) {
            fatalError("not used by TRPCityCache")
        }

        func resolveCities(coordinates: [TRPLocation], completion: @escaping (Result<[Int], Error>) -> Void) {
            fatalError("not used by TRPCityCache")
        }
    }

    private final class FakeCityStoring: TRPCityStoring {
        private let lock = NSLock()
        private var stored: (cities: [TRPCity], fetchedAt: Date)?

        private(set) var saveCallCount = 0
        private(set) var clearCallCount = 0
        var onSave: (() -> Void)?

        init(stored: (cities: [TRPCity], fetchedAt: Date)? = nil) {
            self.stored = stored
        }

        func load() -> (cities: [TRPCity], fetchedAt: Date)? {
            lock.lock(); defer { lock.unlock() }
            return stored
        }

        func save(_ cities: [TRPCity], at date: Date) {
            lock.lock()
            stored = (cities, date)
            saveCallCount += 1
            lock.unlock()
            onSave?()
        }

        func clear() {
            lock.lock()
            stored = nil
            clearCallCount += 1
            lock.unlock()
        }
    }

    private let barcelona = TRPCity(id: 109, name: "Barcelona", coordinate: TRPLocation(lat: 41.3850639, lon: 2.1734035))
    private let rome = TRPCity(id: 205, name: "Rome", coordinate: TRPLocation(lat: 41.9028, lon: 12.4964))
    private let unknownCityId = 999

    func testStoredListIsServedFromInitWithoutFetching() {
        let storage = FakeCityStoring(stored: (cities: [barcelona], fetchedAt: Date()))
        let remoteApi = FakeCityRemoteApi()
        let cache = TRPCityCache(cityRemoteApi: remoteApi, storage: storage)

        XCTAssertTrue(cache.isCacheReady())
        XCTAssertEqual(cache.getCity(byId: barcelona.id)?.name, barcelona.name)
        XCTAssertEqual(remoteApi.fetchCitiesCallCount, 0)
    }

    func testCityHitAnswersWithoutFetch() {
        let storage = FakeCityStoring(stored: (cities: [barcelona], fetchedAt: Date()))
        let remoteApi = FakeCityRemoteApi()
        let cache = TRPCityCache(cityRemoteApi: remoteApi, storage: storage)

        let expectation = expectation(description: "city")
        cache.city(withId: barcelona.id) { result in
            guard case .success(let city) = result else { return XCTFail("expected success") }
            XCTAssertEqual(city?.id, self.barcelona.id)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(remoteApi.fetchCitiesCallCount, 0)
    }

    func testCityMissFetchesOnceThenIsFound() {
        let storage = FakeCityStoring()
        let remoteApi = FakeCityRemoteApi()
        remoteApi.result = .success([barcelona])
        let cache = TRPCityCache(cityRemoteApi: remoteApi, storage: storage)

        let expectation = expectation(description: "city")
        cache.city(withId: barcelona.id) { result in
            guard case .success(let city) = result else { return XCTFail("expected success") }
            XCTAssertEqual(city?.id, self.barcelona.id)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(remoteApi.fetchCitiesCallCount, 1)
    }

    func testCityStillMissingAfterFetchReturnsNilAndSecondLookupSkipsFetch() {
        let storage = FakeCityStoring()
        let remoteApi = FakeCityRemoteApi()
        remoteApi.result = .success([barcelona])
        let cache = TRPCityCache(cityRemoteApi: remoteApi, storage: storage)

        let first = expectation(description: "first lookup")
        cache.city(withId: unknownCityId) { result in
            guard case .success(let city) = result else { return XCTFail("expected success") }
            XCTAssertNil(city)
            first.fulfill()
        }
        wait(for: [first], timeout: 1)
        XCTAssertEqual(remoteApi.fetchCitiesCallCount, 1)

        let second = expectation(description: "second lookup")
        cache.city(withId: unknownCityId) { result in
            guard case .success(let city) = result else { return XCTFail("expected success") }
            XCTAssertNil(city)
            second.fulfill()
        }
        wait(for: [second], timeout: 1)
        XCTAssertEqual(remoteApi.fetchCitiesCallCount, 1)
    }

    func testFetchFailureReturnsFailure() {
        let storage = FakeCityStoring()
        let remoteApi = FakeCityRemoteApi()
        remoteApi.result = .failure(GeneralError.customMessage("network down"))
        let cache = TRPCityCache(cityRemoteApi: remoteApi, storage: storage)

        let expectation = expectation(description: "city")
        cache.city(withId: barcelona.id) { result in
            guard case .failure = result else { return XCTFail("expected failure") }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testConcurrentLookupsWhileAFetchIsInFlightMakeExactlyOneRemoteCall() {
        let storage = FakeCityStoring()
        let remoteApi = FakeCityRemoteApi()
        let cache = TRPCityCache(cityRemoteApi: remoteApi, storage: storage)

        let remoteCalled = expectation(description: "remote called")
        remoteApi.onFetchCalled = { remoteCalled.fulfill() }

        let first = expectation(description: "first lookup")
        cache.city(withId: barcelona.id) { result in
            guard case .success(let city) = result else { return XCTFail("expected success") }
            XCTAssertEqual(city?.id, self.barcelona.id)
            first.fulfill()
        }

        wait(for: [remoteCalled], timeout: 1)

        let second = expectation(description: "second lookup")
        cache.city(withId: rome.id) { result in
            guard case .success(let city) = result else { return XCTFail("expected success") }
            XCTAssertEqual(city?.id, self.rome.id)
            second.fulfill()
        }

        remoteApi.completePendingFetch(with: .success([barcelona, rome]))

        wait(for: [first, second], timeout: 1)
        XCTAssertEqual(remoteApi.fetchCitiesCallCount, 1)
    }

    func testConcurrentFetchCitiesIfNeededCallsMakeExactlyOneRemoteCall() {
        let storage = FakeCityStoring()
        let remoteApi = FakeCityRemoteApi()
        let cache = TRPCityCache(cityRemoteApi: remoteApi, storage: storage)

        let remoteCalled = expectation(description: "remote called")
        remoteApi.onFetchCalled = { remoteCalled.fulfill() }

        let first = expectation(description: "first fetch")
        cache.fetchCitiesIfNeeded { success in
            XCTAssertTrue(success)
            first.fulfill()
        }

        wait(for: [remoteCalled], timeout: 1)

        let second = expectation(description: "second fetch")
        cache.fetchCitiesIfNeeded { success in
            XCTAssertTrue(success)
            second.fulfill()
        }

        remoteApi.completePendingFetch(with: .success([barcelona]))

        wait(for: [first, second], timeout: 1)
        XCTAssertEqual(remoteApi.fetchCitiesCallCount, 1)
    }

    func testCityCompletionRunsOnMainThreadEvenWhenCalledFromABackgroundThread() {
        let storage = FakeCityStoring(stored: (cities: [barcelona], fetchedAt: Date()))
        let remoteApi = FakeCityRemoteApi()
        let cache = TRPCityCache(cityRemoteApi: remoteApi, storage: storage)

        let expectation = expectation(description: "city")
        DispatchQueue.global().async {
            cache.city(withId: self.barcelona.id) { _ in
                XCTAssertTrue(Thread.isMainThread)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1)
    }

    func testGetCityCalledInsideCityCompletionDoesNotDeadlock() {
        let storage = FakeCityStoring()
        let remoteApi = FakeCityRemoteApi()
        remoteApi.result = .success([barcelona])
        let cache = TRPCityCache(cityRemoteApi: remoteApi, storage: storage)

        let expectation = expectation(description: "city")
        cache.city(withId: barcelona.id) { _ in
            XCTAssertEqual(cache.getCity(byId: self.barcelona.id)?.id, self.barcelona.id)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testFetchCitiesIfNeededSkipsFetchWhenStoredListIsFresh() {
        let storage = FakeCityStoring(stored: (cities: [barcelona], fetchedAt: Date()))
        let remoteApi = FakeCityRemoteApi()
        let cache = TRPCityCache(cityRemoteApi: remoteApi, storage: storage)

        let expectation = expectation(description: "fresh")
        cache.fetchCitiesIfNeeded { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(remoteApi.fetchCitiesCallCount, 0)
    }

    func testFetchCitiesIfNeededTriggersFetchWhenStoredListIsStale() {
        let staleDate = Date().addingTimeInterval(-8 * 24 * 60 * 60)
        let storage = FakeCityStoring(stored: (cities: [barcelona], fetchedAt: staleDate))
        let remoteApi = FakeCityRemoteApi()
        remoteApi.result = .success([barcelona, rome])
        let cache = TRPCityCache(cityRemoteApi: remoteApi, storage: storage)

        let expectation = expectation(description: "refresh")
        cache.fetchCitiesIfNeeded { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(remoteApi.fetchCitiesCallCount, 1)
        XCTAssertEqual(Set(cache.getAllCities().map(\.id)), Set([barcelona.id, rome.id]))
    }

    func testSuccessfulFetchSavesTheListToStorage() {
        let storage = FakeCityStoring()
        let remoteApi = FakeCityRemoteApi()
        remoteApi.result = .success([barcelona])
        let cache = TRPCityCache(cityRemoteApi: remoteApi, storage: storage)

        let saved = expectation(description: "saved")
        storage.onSave = { saved.fulfill() }

        cache.fetchCitiesIfNeeded()

        wait(for: [saved], timeout: 1)
        XCTAssertEqual(storage.saveCallCount, 1)
    }

    func testClearCacheClearsMemoryAndStorage() {
        let storage = FakeCityStoring(stored: (cities: [barcelona], fetchedAt: Date()))
        let remoteApi = FakeCityRemoteApi()
        let cache = TRPCityCache(cityRemoteApi: remoteApi, storage: storage)

        cache.clearCache()

        XCTAssertTrue(cache.getAllCities().isEmpty)
        XCTAssertEqual(storage.clearCallCount, 1)
    }
}
