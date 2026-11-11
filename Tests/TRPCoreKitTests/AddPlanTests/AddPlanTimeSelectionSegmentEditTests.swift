import XCTest
import TRPFoundationKit
@testable import TRPCoreKit

/// Tour repository stub satisfying the edit-mode initializer's dependency; no call is expected in these tests.
private final class FakeTourRepository: TourRepository {
    var tours: [TRPTourProduct] = []
    var toursWithParameters: [TourParameters: [TRPTourProduct]] = [:]

    func fetchTours(cityId: Int, parameters: TourParameters, completion: @escaping (TourResultsValue) -> Void) {}
    func fetchTours(coordinate: TRPLocation, parameters: TourParameters, completion: @escaping (TourResultsValue) -> Void) {}
    func addTours(contentsOf: [TRPTourProduct]) {}
    func getTourSchedule(productId: String, date: String, to: String?, currency: String, lang: String, completion: @escaping (Result<TRPTourSchedule, Error>) -> Void) {}
    func lookupTourProduct(providerId: Int, productId: String, completion: @escaping (TourResultValue) -> Void) {}
    func getTourScheduleAvailability(items: [String], date: String, currency: String?, lang: String?, completion: @escaping (Result<[TRPTourScheduleAvailability], Error>) -> Void) {}
}

/// Minimal delegate spy recording the outcome of `updateReservedActivitySegment()`.
private final class SegmentEditDelegateSpy: AddPlanTimeSelectionViewModelDelegate {
    private(set) var updateSucceededCount = 0
    private(set) var errors: [Error] = []

    func timeSlotsDidLoad() {}
    func segmentCreationDidSucceed() {}
    func segmentUpdateDidSucceed() { updateSucceededCount += 1 }
    func stepUpdateDidSucceed() {}

    func viewModel(dataLoaded: Bool) {}
    func viewModel(error: Error) { errors.append(error) }
    func viewModel(showPreloader: Bool) {}
    func viewModel(showMessage: String, type: EvrAlertLevel) {}
    func viewModel(showLottie presentation: LottieLoaderPresentation, textMode: LottieLoadingTextMode, completion: (() -> Void)?) {
        completion?()
    }
    func viewModel(hideLottie presentation: LottieLoaderPresentation, completion: (() -> Void)?) {
        completion?()
    }
}

/// Pins who supplies the committed segment index and when and how `finished` reports for the reserved-activity edit flow.
final class AddPlanTimeSelectionSegmentEditTests: XCTestCase {

    private let city = GenerationFixtures.barcelona

    private func makeSegment() -> TRPTimelineSegment {
        let segment = TRPTimelineSegment()
        segment.segmentType = .reservedActivity
        segment.title = "Reserved Activity"
        segment.startDate = "2025-12-09 10:00"
        segment.endDate = "2025-12-09 12:00"
        segment.city = city
        segment.cityId = city.id
        segment.additionalData = TRPSegmentActivityItem(
            activityId: "12345",
            bookingId: "booking-1",
            title: "Reserved Activity",
            imageUrl: nil,
            description: nil,
            startDatetime: "2025-12-09 10:00",
            endDatetime: "2025-12-09 12:00",
            coordinate: city.coordinate,
            cancellation: nil,
            adultCount: 2,
            childCount: 0
        )
        return segment
    }

    private func makeViewModel(segmentIndex: Int?, tripHash: String? = "generation-hash") -> (AddPlanTimeSelectionViewModel, ScriptedTimelineRepository) {
        var planData = AddPlanData()
        planData.tripHash = tripHash
        planData.availableDays = [stringToDate("2025-12-09")]
        planData.segmentIndex = segmentIndex

        let viewModel = AddPlanTimeSelectionViewModel(segment: makeSegment(), planData: planData, tourRepository: FakeTourRepository())
        viewModel.selectTimeSlot(DisplayTimeSlot(time: "11:00", price: nil, isDisabled: false))

        let repository = ScriptedTimelineRepository()
        viewModel.timelineRepository = repository
        return (viewModel, repository)
    }

    private func stringToDate(_ ymd: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: ymd)!
    }

    /// `submitSegmentUpdate` dispatches its outcome back to the main queue.
    private func drainMainQueue() {
        let drained = expectation(description: "main queue drained")
        DispatchQueue.main.async { drained.fulfill() }
        wait(for: [drained], timeout: 5)
    }

    func testUpdateWithAnInjectedRunnerCommitsTheRunnerProvidedIndexRatherThanThePlanDataIndex() {
        let (viewModel, repository) = makeViewModel(segmentIndex: 3)
        let spy = SegmentEditDelegateSpy()
        viewModel.delegate = spy

        var runnerReceivedSegment: TRPTimelineSegment?
        viewModel.segmentEditRunner = { segment, commit in
            runnerReceivedSegment = segment
            commit(7, { _ in })
        }

        viewModel.updateReservedActivitySegment()
        drainMainQueue()

        XCTAssertNotNil(runnerReceivedSegment)
        XCTAssertEqual(repository.createEditCalls.count, 1)
        XCTAssertEqual(repository.createEditCalls.first?.segmentIndex, 7)
        XCTAssertEqual(spy.updateSucceededCount, 1)
    }

    func testUpdateWithoutARunnerUsesThePlanDataSegmentIndex() {
        let (viewModel, repository) = makeViewModel(segmentIndex: 5)
        let spy = SegmentEditDelegateSpy()
        viewModel.delegate = spy

        viewModel.updateReservedActivitySegment()
        drainMainQueue()

        XCTAssertEqual(repository.createEditCalls.count, 1)
        XCTAssertEqual(repository.createEditCalls.first?.segmentIndex, 5)
        XCTAssertEqual(spy.updateSucceededCount, 1)
    }

    func testUpdateWithoutARunnerOrAPlanDataIndexReportsASegmentNotFoundErrorWithoutSendingAPut() {
        let (viewModel, repository) = makeViewModel(segmentIndex: nil)
        let spy = SegmentEditDelegateSpy()
        viewModel.delegate = spy

        viewModel.updateReservedActivitySegment()
        drainMainQueue()

        XCTAssertTrue(repository.createEditCalls.isEmpty)
        XCTAssertEqual(spy.errors.count, 1)
        XCTAssertEqual(spy.updateSucceededCount, 0)
    }

    func testRunnerCommitReportsAnAcceptedPutOnlyAfterItReturns() {
        let (viewModel, repository) = makeViewModel(segmentIndex: nil)
        let spy = SegmentEditDelegateSpy()
        viewModel.delegate = spy
        repository.createEditResult = .success(true)

        var reportedOutcomes: [Bool] = []
        viewModel.segmentEditRunner = { _, commit in
            commit(9, { reportedOutcomes.append($0) })
        }

        viewModel.updateReservedActivitySegment()
        XCTAssertTrue(reportedOutcomes.isEmpty, "the PUT response is dispatched to the main queue, not delivered synchronously")
        drainMainQueue()

        XCTAssertEqual(reportedOutcomes, [true])
        XCTAssertEqual(repository.createEditCalls.first?.segmentIndex, 9)
        XCTAssertEqual(spy.updateSucceededCount, 1)
    }

    func testRunnerCommitReportsARejectedOrFailedPutAsNotSucceeded() {
        for result: TimelineResultStatus in [.success(false), .failure(GeneralError.customMessage("offline"))] {
            let (viewModel, repository) = makeViewModel(segmentIndex: nil)
            let spy = SegmentEditDelegateSpy()
            viewModel.delegate = spy
            repository.createEditResult = result

            var reportedOutcomes: [Bool] = []
            viewModel.segmentEditRunner = { _, commit in
                commit(9, { reportedOutcomes.append($0) })
            }

            viewModel.updateReservedActivitySegment()
            drainMainQueue()

            XCTAssertEqual(reportedOutcomes, [false])
            XCTAssertEqual(spy.updateSucceededCount, 0)
            XCTAssertEqual(spy.errors.count, 1)
        }
    }

    func testRunnerThatNeverCommitsSendsNoPutAndReportsNoSuccess() {
        let (viewModel, repository) = makeViewModel(segmentIndex: nil)
        let spy = SegmentEditDelegateSpy()
        viewModel.delegate = spy

        viewModel.segmentEditRunner = { _, _ in }

        viewModel.updateReservedActivitySegment()
        drainMainQueue()

        XCTAssertTrue(repository.createEditCalls.isEmpty)
        XCTAssertEqual(spy.updateSucceededCount, 0)
        XCTAssertTrue(spy.errors.isEmpty, "the runner, not updateReservedActivitySegment, owns the segment-gone error")
    }
}
