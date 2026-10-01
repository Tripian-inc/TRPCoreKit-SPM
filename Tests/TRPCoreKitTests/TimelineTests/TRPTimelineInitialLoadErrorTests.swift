import XCTest
import UIKit
import TRPRestKit
@testable import TRPCoreKit

/// A failed first load must leave a retryable error screen, never an empty timeline with an empty banner.
final class TRPTimelineInitialLoadErrorTests: XCTestCase {

    // MARK: - Spies

    private final class InitialLoadSpy: TRPTimelineItineraryViewModelDelegate {
        var lottieStates: [Bool] = []
        var failedErrors: [Error] = []
        func timelineItineraryViewModel(didUpdateTimeline: Bool) {}
        func timelineItineraryViewModel(noCitiesAvailable: Bool) {}
        func timelineItineraryViewModel(someCitiesUnavailable cityNames: [String]) {}
        func timelineItineraryViewModel(showLottieLoading: Bool, textMode: LottieLoadingTextMode) { lottieStates.append(showLottieLoading) }
        func timelineItineraryViewModel(didFailInitialLoad error: Error) { failedErrors.append(error) }
    }

    private final class LegacyDelegateSpy: TRPTimelineItineraryViewModelDelegate {
        var bannerErrors: [Error] = []
        func timelineItineraryViewModel(didUpdateTimeline: Bool) {}
        func timelineItineraryViewModel(noCitiesAvailable: Bool) {}
        func timelineItineraryViewModel(someCitiesUnavailable cityNames: [String]) {}
        func viewModel(error: Error) { bannerErrors.append(error) }
    }

    private let loadError = TRPErrors.httpResult(code: 500, des: "", info: [:])

    private func drainMainQueue() {
        let drained = expectation(description: "main queue drained")
        DispatchQueue.main.async { drained.fulfill() }
        wait(for: [drained], timeout: 1)
    }

    // MARK: - ViewModel

    func testInitialLoadFailureHidesTheLoaderAndReportsTheError() {
        let viewModel = TRPTimelineItineraryViewModel(tripHash: "hash")
        let spy = InitialLoadSpy()
        viewModel.delegate = spy

        viewModel.reportInitialLoadFailure(loadError) {}
        drainMainQueue()

        XCTAssertEqual(spy.lottieStates, [false])
        XCTAssertEqual(spy.failedErrors.count, 1)
    }

    func testRetryRunsTheFailedRequestOnlyOnce() {
        let viewModel = TRPTimelineItineraryViewModel(tripHash: "hash")
        var retries = 0
        viewModel.reportInitialLoadFailure(loadError) { retries += 1 }
        drainMainQueue()

        viewModel.retryInitialLoad()
        viewModel.retryInitialLoad()

        XCTAssertEqual(retries, 1)
    }

    func testRetryWithoutAFailedLoadDoesNothing() {
        let viewModel = TRPTimelineItineraryViewModel(tripHash: "hash")
        let spy = InitialLoadSpy()
        viewModel.delegate = spy

        viewModel.retryInitialLoad()

        XCTAssertTrue(spy.lottieStates.isEmpty)
        XCTAssertTrue(spy.failedErrors.isEmpty)
    }

    func testDelegateWithoutAnErrorScreenStillGetsTheError() {
        let viewModel = TRPTimelineItineraryViewModel(tripHash: "hash")
        let spy = LegacyDelegateSpy()
        viewModel.delegate = spy

        viewModel.reportInitialLoadFailure(loadError) {}
        drainMainQueue()

        XCTAssertEqual(spy.bannerErrors.count, 1)
    }

    // MARK: - Screen

    private func loadedViewController() -> TRPTimelineItineraryVC {
        let viewController = TRPTimelineItineraryVC(viewModel: TRPTimelineItineraryViewModel(timeline: nil))
        viewController.loadViewIfNeeded()
        return viewController
    }

    func testInitialLoadFailureCoversTheEmptyTimelineWithTheRetryScreen() {
        let viewController = loadedViewController()
        XCTAssertTrue(viewController.initialLoadErrorView.isHidden)

        viewController.timelineItineraryViewModel(didFailInitialLoad: loadError)

        XCTAssertFalse(viewController.initialLoadErrorView.isHidden)
        XCTAssertTrue(viewController.view.subviews.last === viewController.initialLoadErrorView)
    }

    func testTryAgainHidesTheErrorScreenAndRetries() {
        let viewController = loadedViewController()
        var retried = false
        viewController.timelineItineraryViewModel(didFailInitialLoad: loadError)
        viewController.viewModel.initialLoadRetry = { retried = true }

        viewController.noCityViewDidTapButton(viewController.initialLoadErrorView)

        XCTAssertTrue(retried)
        XCTAssertTrue(viewController.initialLoadErrorView.isHidden)
    }

    func testExpiredSessionDoesNotOfferARetry() {
        let viewController = loadedViewController()

        viewController.timelineItineraryViewModel(didFailInitialLoad: TRPErrors.refreshTokenError)

        XCTAssertTrue(viewController.initialLoadErrorView.isHidden)
    }
}
