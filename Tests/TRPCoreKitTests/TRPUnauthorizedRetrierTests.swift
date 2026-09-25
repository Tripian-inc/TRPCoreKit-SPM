//
//  TRPUnauthorizedRetrierTests.swift
//  TRPCoreKitTests
//
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import XCTest
@testable import TRPCoreKit

final class TRPUnauthorizedRetrierTests: XCTestCase {

    private final class RefresherSpy: TRPTokenRefreshing {
        var calls = 0
        var error: Error?
        var pending: [(Error?) -> Void] = []
        var answersImmediately = true

        func refreshToken(completion: @escaping (Error?) -> Void) {
            calls += 1
            if answersImmediately {
                completion(error)
            } else {
                pending.append(completion)
            }
        }
    }

    private let unauthorized = NSError(domain: "test", code: 401)
    private let serverError = NSError(domain: "test", code: 500)

    private func call(answering results: [Result<Int, Error>], sent: @escaping () -> Void = {}) -> (@escaping (Result<Int, Error>) -> Void) -> Void {
        var remaining = results
        return { completion in
            sent()
            completion(remaining.removeFirst())
        }
    }

    func testWithoutRefresherA401IsReturnedUntouched() {
        let retrier = TRPUnauthorizedRetrier()
        var sends = 0
        var received: Result<Int, Error>?

        retrier.send(call(answering: [.failure(unauthorized)], sent: { sends += 1 })) { received = $0 }

        XCTAssertEqual(sends, 1)
        XCTAssertEqual((received?.error as NSError?)?.code, 401)
    }

    func testA401IsRefreshedAndSentOnceMore() {
        let refresher = RefresherSpy()
        let retrier = TRPUnauthorizedRetrier(refresher: refresher)
        var sends = 0
        var received: Result<Int, Error>?

        retrier.send(call(answering: [.failure(unauthorized), .success(7)], sent: { sends += 1 })) { received = $0 }

        XCTAssertEqual(refresher.calls, 1)
        XCTAssertEqual(sends, 2)
        XCTAssertEqual(try? received?.get(), 7)
    }

    func testASecond401IsReturnedWithoutAnotherRefresh() {
        let refresher = RefresherSpy()
        let retrier = TRPUnauthorizedRetrier(refresher: refresher)
        var received: Result<Int, Error>?

        retrier.send(call(answering: [.failure(unauthorized), .failure(unauthorized)])) { received = $0 }

        XCTAssertEqual(refresher.calls, 1)
        XCTAssertEqual((received?.error as NSError?)?.code, 401)
    }

    func testAFailedRefreshIsReturnedAndTheCallIsNotSentAgain() {
        let refresher = RefresherSpy()
        refresher.error = serverError
        let retrier = TRPUnauthorizedRetrier(refresher: refresher)
        var sends = 0
        var received: Result<Int, Error>?

        retrier.send(call(answering: [.failure(unauthorized)], sent: { sends += 1 })) { received = $0 }

        XCTAssertEqual(sends, 1)
        XCTAssertEqual((received?.error as NSError?)?.code, 500)
    }

    func testOtherErrorsAreNotRetried() {
        let refresher = RefresherSpy()
        let retrier = TRPUnauthorizedRetrier(refresher: refresher)
        var received: Result<Int, Error>?

        retrier.send(call(answering: [.failure(serverError)])) { received = $0 }

        XCTAssertEqual(refresher.calls, 0)
        XCTAssertEqual((received?.error as NSError?)?.code, 500)
    }

    func testCallsThatOptOutAreNotRetried() {
        let refresher = RefresherSpy()
        let retrier = TRPUnauthorizedRetrier(refresher: refresher)
        var received: Result<Int, Error>?

        retrier.send(retriesOnUnauthorized: false, call(answering: [.failure(unauthorized)])) { received = $0 }

        XCTAssertEqual(refresher.calls, 0)
        XCTAssertEqual((received?.error as NSError?)?.code, 401)
    }

    func testCallsFailingTogetherShareOneRefresh() {
        let refresher = RefresherSpy()
        refresher.answersImmediately = false
        let retrier = TRPUnauthorizedRetrier(refresher: refresher)
        var results: [Int] = []

        retrier.send(call(answering: [.failure(unauthorized), .success(1)])) { results.append((try? $0.get()) ?? -1) }
        retrier.send(call(answering: [.failure(unauthorized), .success(2)])) { results.append((try? $0.get()) ?? -1) }
        XCTAssertEqual(refresher.calls, 1)

        refresher.pending.forEach { $0(nil) }

        XCTAssertEqual(results.sorted(), [1, 2])
    }
}

private extension Result {
    var error: Failure? {
        if case .failure(let error) = self { return error }
        return nil
    }
}
