//
//  TRPTimelineCoordinatorUsageExample.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 27.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
import TRPFoundationKit

/**
 Usage examples for TRPTimelineCoordinator

 This file demonstrates how to use the TRPTimelineCoordinator for both:
 1. Creating a new timeline (no trip hash)
 2. Fetching an existing timeline (with trip hash)
 */

#if DEBUG

// MARK: - Example 1: Create New Timeline (No Trip Hash)

class ExampleCreateTimelineViewController: UIViewController {

    var timelineCoordinator: TRPTimelineCoordinator?

    func startTimelineCreationFlow() {
        // 1. Create timeline profile with trip details
        let profile = TRPTimelineProfile(cityId: 109) // Barcelona

        // Set travelers
        profile.adults = 2
        profile.children = 0
        profile.pets = 0

        // Optional: Set user preferences (answer IDs from questions)
        profile.answerIds = [1, 5, 12, 18] // Example answer IDs

        // IMPORTANT: Timeline profiles don't have arrivalDatetime/departureDatetime
        // Dates are defined in segments only

        // Create segments with booked activities
        let startDate = Date().addDay(7) ?? Date() // 7 days from now

        // Example: Add a booked activity segment
        let segment = TRPTimelineSegment()
        segment.segmentType = .bookedActivity
        segment.distinctPlan = true
        segment.available = false
        segment.title = "Sagrada Familia Tour"
        segment.description = "Guided tour"
        segment.startDate = startDate.toString(format: "yyyy-MM-dd 14:00")
        segment.endDate = startDate.toString(format: "yyyy-MM-dd 16:00")
        segment.coordinate = TRPLocation(lat: 41.4036, lon: 2.1744)
        segment.adults = 2
        segment.children = 0
        segment.pets = 0

        profile.segments = [segment]

        // 2. Create coordinator
        guard let navigationController = self.navigationController else { return }
        timelineCoordinator = TRPTimelineCoordinator(navigationController: navigationController)
        timelineCoordinator?.delegate = self

        // 3. Start the creation flow
        // This will:
        //   - Create timeline via API
        //   - Monitor generation status via observer pattern
        //   - Wait for ALL segments to be generated
        //   - Open TRPTimelineItineraryVC when ready
        timelineCoordinator?.start(with: profile)
    }
}

// MARK: - Example 2: Fetch Existing Timeline (With Trip Hash)

class ExampleFetchTimelineViewController: UIViewController {

    var timelineCoordinator: TRPTimelineCoordinator?

    func startTimelineFetchFlow(tripHash: String) {
        // 1. Create coordinator
        guard let navigationController = self.navigationController else { return }
        timelineCoordinator = TRPTimelineCoordinator(navigationController: navigationController)
        timelineCoordinator?.delegate = self

        // 2. Start the fetch flow with trip hash
        // This will:
        //   - Fetch timeline from API
        //   - Open TRPTimelineItineraryVC immediately
        timelineCoordinator?.start(tripHash: tripHash)
    }
}

// MARK: - Example 3: Usage from Parent Coordinator

class ExampleParentCoordinator: CoordinatorProtocol {
    var navigationController: UINavigationController?
    var childCoordinators: [any CoordinatorProtocol] = []

    private var timelineCoordinator: TRPTimelineCoordinator?

    func start() {
        // Not implemented
    }

    /// Example: User wants to create a new trip
    func createNewTrip() {
        let profile = TRPTimelineProfile(cityId: 109)
        profile.adults = 2
        profile.children = 0
        profile.pets = 0
        profile.answerIds = []

        // Create booked activity segment with dates
        let segment = TRPTimelineSegment()
        segment.segmentType = .bookedActivity
        segment.distinctPlan = true
        segment.available = false
        segment.title = "Barcelona Day Tour"
        segment.description = "Guided city tour"
        segment.startDate = "2025-01-10 09:00"
        segment.endDate = "2025-01-10 18:00"
        segment.coordinate = TRPLocation(lat: 41.3851, lon: 2.1734)
        segment.adults = 2
        segment.children = 0
        segment.pets = 0

        profile.segments = [segment]

        openTimelineFlow(with: profile)
    }

    /// Example: User wants to view existing trip
    func viewExistingTrip(tripHash: String) {
        openTimelineFlow(tripHash: tripHash)
    }

    private func openTimelineFlow(with profile: TRPTimelineProfile) {
        let coordinator = TRPTimelineCoordinator(navigationController: navigationController)
        coordinator.delegate = self
        childCoordinators.append(coordinator)
        timelineCoordinator = coordinator

        coordinator.start(with: profile)
    }

    private func openTimelineFlow(tripHash: String) {
        let coordinator = TRPTimelineCoordinator(navigationController: navigationController)
        coordinator.delegate = self
        childCoordinators.append(coordinator)
        timelineCoordinator = coordinator

        coordinator.start(tripHash: tripHash)
    }
}

// MARK: - TRPTimelineCoordinatorDelegate Implementation

extension ExampleCreateTimelineViewController: TRPTimelineCoordinatorDelegate {

    func timelineCoordinatorShowCitySelection(_ coordinator: TRPTimelineCoordinator, from viewController: UIViewController) {
        print("Show city selection UI")
        // TODO: Implement city selection
    }

    func timelineCoordinatorShowDateRangeSelection(_ coordinator: TRPTimelineCoordinator, from viewController: UIViewController, preselected: (Date, Date)?, maxDays: Int) {
        print("Show date range selection UI")
        // TODO: Implement date range selection
    }

    func timelineCoordinatorShowTravelersSelection(_ coordinator: TRPTimelineCoordinator, from viewController: UIViewController, preselected: (adults: Int, children: Int, pets: Int)) {
        print("Show travelers selection UI")
        // TODO: Implement travelers selection
    }

    func timelineCoordinatorDidClose(_ coordinator: TRPTimelineCoordinator) {
        print("Timeline coordinator closed")
        // Cleanup
        timelineCoordinator = nil
    }
}

extension ExampleFetchTimelineViewController: TRPTimelineCoordinatorDelegate {

    func timelineCoordinatorShowCitySelection(_ coordinator: TRPTimelineCoordinator, from viewController: UIViewController) {
        print("Show city selection UI")
    }

    func timelineCoordinatorShowDateRangeSelection(_ coordinator: TRPTimelineCoordinator, from viewController: UIViewController, preselected: (Date, Date)?, maxDays: Int) {
        print("Show date range selection UI")
    }

    func timelineCoordinatorShowTravelersSelection(_ coordinator: TRPTimelineCoordinator, from viewController: UIViewController, preselected: (adults: Int, children: Int, pets: Int)) {
        print("Show travelers selection UI")
    }

    func timelineCoordinatorDidClose(_ coordinator: TRPTimelineCoordinator) {
        print("Timeline coordinator closed")
        timelineCoordinator = nil
    }
}

extension ExampleParentCoordinator: TRPTimelineCoordinatorDelegate {

    func timelineCoordinatorShowCitySelection(_ coordinator: TRPTimelineCoordinator, from viewController: UIViewController) {
        // Implement city selection from parent coordinator
    }

    func timelineCoordinatorShowDateRangeSelection(_ coordinator: TRPTimelineCoordinator, from viewController: UIViewController, preselected: (Date, Date)?, maxDays: Int) {
        // Implement date range selection from parent coordinator
    }

    func timelineCoordinatorShowTravelersSelection(_ coordinator: TRPTimelineCoordinator, from viewController: UIViewController, preselected: (adults: Int, children: Int, pets: Int)) {
        // Implement travelers selection from parent coordinator
    }

    func timelineCoordinatorDidClose(_ coordinator: TRPTimelineCoordinator) {
        // Remove from child coordinators
        if let index = childCoordinators.firstIndex(where: { $0 as? TRPTimelineCoordinator === coordinator }) {
            childCoordinators.remove(at: index)
        }
        timelineCoordinator = nil
    }
}

// MARK: - Quick Testing Helper

extension TRPTimelineCoordinator {

    /// Quick test helper for creating a timeline with default values
    /// Usage: TRPTimelineCoordinator.quickTestCreate(in: navigationController)
    public static func quickTestCreate(in navigationController: UINavigationController) {
        let profile = TRPTimelineProfile(cityId: 109) // Barcelona
        profile.adults = 2
        profile.children = 0
        profile.pets = 0
        profile.answerIds = []

        // Create a quick test segment
        let startDate = Date().addDay(1) ?? Date()
        let segment = TRPTimelineSegment()
        segment.segmentType = .bookedActivity
        segment.distinctPlan = true
        segment.available = false
        segment.title = "Test Activity"
        segment.description = "Quick test activity"
        segment.startDate = startDate.toString(format: "yyyy-MM-dd 14:00")
        segment.endDate = startDate.toString(format: "yyyy-MM-dd 16:00")
        segment.coordinate = TRPLocation(lat: 41.3851, lon: 2.1734)
        segment.adults = 2
        segment.children = 0
        segment.pets = 0

        profile.segments = [segment]

        let coordinator = TRPTimelineCoordinator(navigationController: navigationController)
        coordinator.start(with: profile)
    }

    /// Quick test helper for fetching a timeline
    /// Usage: TRPTimelineCoordinator.quickTestFetch(in: navigationController, tripHash: "abc123")
    public static func quickTestFetch(in navigationController: UINavigationController, tripHash: String) {
        let coordinator = TRPTimelineCoordinator(navigationController: navigationController)
        coordinator.start(tripHash: tripHash)
    }
}

#endif
