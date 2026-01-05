//
//  TRPTimelineCreateFlowMockCoordinator.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 27.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
import TRPFoundationKit

/**
 Mock coordinator for testing timeline creation flow

 Simulates:
 - Timeline creation API call
 - Generation polling with delays
 - Observer pattern notifications
 - Loading states
 */
public class TRPTimelineCreateFlowMockCoordinator {

    // MARK: - Properties
    private weak var navigationController: UINavigationController?
    private var timelineCoordinator: TRPTimelineCoordinator?

    // MARK: - Initialization
    public init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    // MARK: - Public Methods

    /// Test Flow 1: Create new timeline with mock data
    /// This simulates the complete creation → generation → display flow
    public func testCreateFlow() {
        print("🧪 [Mock Create Flow] Starting create timeline test")

        // Get mock profile
        let profile = TRPTimelineCreateFlowMockData.getMockTimelineProfile()

        // Create coordinator with mock repositories
        let mockTimelineRepo = MockTimelineRepository()
        let mockTimelineModelRepo = MockTimelineModelRepository()

        guard let nav = navigationController else {
            print("❌ [Mock Create Flow] No navigation controller")
            return
        }

        timelineCoordinator = TRPTimelineCoordinator(
            navigationController: nav,
            timelineRepository: mockTimelineRepo,
            timelineModelRepository: mockTimelineModelRepo
        )

        timelineCoordinator?.delegate = self

        // Start creation flow
        timelineCoordinator?.start(with: profile)

        print("✅ [Mock Create Flow] Timeline creation initiated")
    }

    /// Test Flow 2: Fetch existing timeline with mock data
    public func testFetchFlow() {
        print("🧪 [Mock Fetch Flow] Starting fetch timeline test")

        let mockTimelineRepo = MockTimelineRepository()
        let mockTimelineModelRepo = MockTimelineModelRepository()

        guard let nav = navigationController else {
            print("❌ [Mock Fetch Flow] No navigation controller")
            return
        }

        timelineCoordinator = TRPTimelineCoordinator(
            navigationController: nav,
            timelineRepository: mockTimelineRepo,
            timelineModelRepository: mockTimelineModelRepo
        )

        timelineCoordinator?.delegate = self

        // Start fetch flow with mock hash
        timelineCoordinator?.start(tripHash: "mock_create_flow_hash_123")

        print("✅ [Mock Fetch Flow] Timeline fetch initiated")
    }
}

// MARK: - TRPTimelineCoordinatorDelegate
extension TRPTimelineCreateFlowMockCoordinator: TRPTimelineCoordinatorDelegate {

    public func timelineCoordinatorShowCitySelection(_ coordinator: TRPTimelineCoordinator, from viewController: UIViewController) {
        print("🏙️ [Mock Create Flow] Show city selection requested")
    }

    public func timelineCoordinatorShowDateRangeSelection(_ coordinator: TRPTimelineCoordinator, from viewController: UIViewController, preselected: (Date, Date)?, maxDays: Int) {
        print("📅 [Mock Create Flow] Show date range selection requested")
    }

    public func timelineCoordinatorShowTravelersSelection(_ coordinator: TRPTimelineCoordinator, from viewController: UIViewController, preselected: (adults: Int, children: Int, pets: Int)) {
        print("👥 [Mock Create Flow] Show travelers selection requested")
    }

    public func timelineCoordinatorDidClose(_ coordinator: TRPTimelineCoordinator) {
        print("✅ [Mock Create Flow] Timeline coordinator closed")
        timelineCoordinator = nil
    }
}

// MARK: - Mock Repository

/// Mock repository that simulates timeline creation and generation
class MockTimelineRepository: TimelineRepository {

    private var pollingCount = 0
    private let maxPollingBeforeGeneration = 3 // Simulate 3 polling cycles before generation completes

    func fetchTimeline(tripHash: String, completion: @escaping (TimelineResultValue) -> Void) {
        print("🔄 [Mock Repo] Fetching timeline (polling count: \(pollingCount))")

        // Simulate network delay
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }

            self.pollingCount += 1

            if self.pollingCount < self.maxPollingBeforeGeneration {
                // Still generating - return timeline without plans
                print("⏳ [Mock Repo] Timeline still generating...")
                let timeline = TRPTimelineCreateFlowMockData.getMockTimeline(withPlans: false)
                completion(.success(timeline))
            } else {
                // Generation complete - return timeline with plans
                print("✅ [Mock Repo] Timeline generation complete!")
                let timeline = TRPTimelineCreateFlowMockData.getMockTimeline(withPlans: true)
                completion(.success(timeline))

                // Reset for next test
                self.pollingCount = 0
            }
        }
    }

    func createTimeline(profile: TRPTimelineProfile, completion: @escaping (TimelineResultValue) -> Void) {
        print("📝 [Mock Repo] Creating timeline...")

        // Simulate network delay
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            print("✅ [Mock Repo] Timeline created successfully")

            // Reset polling count for new timeline
            self.pollingCount = 0

            // Return created timeline (without plans yet - still generating)
            let timeline = TRPTimelineCreateFlowMockData.getMockTimeline(withPlans: false)
            completion(.success(timeline))
        }
    }

    func createEditTimelineSegment(profile: TRPCreateEditTimelineSegmentProfile, completion: @escaping (TimelineResultStatus) -> Void) {
        completion(.success(true))
    }

    func deleteTimeline(tripHash: String, completion: @escaping (TimelineResultStatus) -> Void) {
        completion(.success(true))
    }

    func deleteTimelineSegment(tripHash: String, segmentIndex: Int, completion: @escaping (TimelineResultStatus) -> Void) {
        completion(.success(true))
    }

    func fetchLocalTimeline(tripHash: String, completion: @escaping (TimelineResultValue) -> Void) {
        completion(.failure(GeneralError.customMessage("No local timeline")))
    }

    func saveTimeline(tripHash: String, data: TRPTimeline) {
        print("💾 [Mock Repo] Saved timeline locally")
    }
}

/// Mock timeline model repository
class MockTimelineModelRepository: TimelineModelRepository {
    var dailySegment: ValueObserver<TRPTimelinePlan> = ValueObserver(TRPTimelinePlan(id: "", startDate: "", endDate: "", steps: [], generatedStatus: 1))
    

    var timeline: ValueObserver<TRPTimeline> = ValueObserver(TRPTimeline(id: 0, tripHash: "", tripProfile: nil, city: TRPCity(id: 104, name: "Barcelona", coordinate: TRPLocation(lat: 0, lon: 0))))
    var allSegmentGenerated: ValueObserver<Bool> = ValueObserver(false)
    var generationError: ValueObserver<Error?> = ValueObserver(nil)

    func saveTimeline(timeline: TRPTimeline) {
        print("💾 [Mock Model Repo] Saved timeline to model")
        self.timeline.value = timeline
    }

    func getTimeline(hash: String) -> TRPTimeline? {
        return timeline.value?.tripHash == hash ? timeline.value : nil
    }

    func clearTimeline() {
        let emptyCity = TRPCity(id: 0, name: "", coordinate: TRPLocation(lat: 0, lon: 0))
        timeline.value = TRPTimeline(id: 0, tripHash: "", tripProfile: nil, city: emptyCity, plans: nil)
        allSegmentGenerated.value = false
        generationError.value = nil
    }
}

// MARK: - Quick Test Helpers

#if DEBUG
extension TRPTimelineCreateFlowMockCoordinator {

    /// Quick test method to launch timeline creation flow from any view controller
    /// Usage: TRPTimelineCreateFlowMockCoordinator.quickTestCreate(from: self)
    public static func quickTestCreate(from viewController: UIViewController) {
        if let navController = viewController.navigationController {
            let coordinator = TRPTimelineCreateFlowMockCoordinator(navigationController: navController)
            coordinator.testCreateFlow()
        } else if let navController = viewController as? UINavigationController {
            let coordinator = TRPTimelineCreateFlowMockCoordinator(navigationController: navController)
            coordinator.testCreateFlow()
        } else {
            print("❌ No navigation controller available")
        }
    }

    /// Quick test method to launch timeline fetch flow from any view controller
    /// Usage: TRPTimelineCreateFlowMockCoordinator.quickTestFetch(from: self)
    public static func quickTestFetch(from viewController: UIViewController) {
        if let navController = viewController.navigationController {
            let coordinator = TRPTimelineCreateFlowMockCoordinator(navigationController: navController)
            coordinator.testFetchFlow()
        } else if let navController = viewController as? UINavigationController {
            let coordinator = TRPTimelineCreateFlowMockCoordinator(navigationController: navController)
            coordinator.testFetchFlow()
        } else {
            print("❌ No navigation controller available")
        }
    }
}
#endif
