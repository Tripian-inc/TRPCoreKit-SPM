//
//  TRPTimelineMockCoordinator.swift
//  TRPCoreKit
//
//  Created by Mock Data Generator on 02.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

/**
 A simple coordinator for testing TRPTimelineItineraryVC with mock data.
 This can be used for quick testing and development without needing real API calls.
 */
public class TRPTimelineMockCoordinator {
    
    // MARK: - Properties
    private weak var navigationController: UINavigationController?
    private var timelineViewController: TRPTimelineItineraryVC?
    
    // MARK: - Initialization
    public init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    // MARK: - Public Methods
    
    /// Start the timeline flow with mock data
    public func start() {
        let mockTimeline = TRPTimelineMockData.getMockTimeline()
        let viewModel = TRPTimelineItineraryViewModel(timeline: mockTimeline)
        let viewController = TRPTimelineItineraryVC(viewModel: viewModel)
        viewController.delegate = self
        
        self.timelineViewController = viewController
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    /// Present timeline modally with mock data
    public func presentModally(from presentingViewController: UIViewController) {
        let mockTimeline = TRPTimelineMockData.getMockTimeline()
        let viewModel = TRPTimelineItineraryViewModel(timeline: mockTimeline)
        let viewController = TRPTimelineItineraryVC(viewModel: viewModel)
        viewController.delegate = self
        
        let navController = UINavigationController(rootViewController: viewController)
        self.navigationController = navController
        self.timelineViewController = viewController
        
        presentingViewController.present(navController, animated: true)
    }
    
    /// Reload the timeline with fresh mock data
    public func reloadMockData() {
        timelineViewController?.reload()
    }
}

// MARK: - TRPTimelineItineraryVCDelegate
extension TRPTimelineMockCoordinator: TRPTimelineItineraryVCDelegate {
    public func timelineItineraryDidRequestActivityReservation(_ viewController: TRPTimelineItineraryVC, activityId: String) {
        
    }
    
    
    public func timelineItineraryFilterPressed(_ viewController: TRPTimelineItineraryVC) {
        // Show an alert for demo purposes
        let alert = UIAlertController(
            title: "Filter",
            message: "Filter functionality would be implemented here",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }
    
    public func timelineItineraryAddPlansPressed(_ viewController: TRPTimelineItineraryVC) {
        print("➕ [Mock Coordinator] Add plans button pressed")
        
        // Show an alert for demo purposes
        let alert = UIAlertController(
            title: "Add Plans",
            message: "Add plans functionality would be implemented here",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }
    
    public func timelineItineraryDidSelectStep(_ viewController: TRPTimelineItineraryVC, step: TRPTimelineStep) {
        guard let poi = step.poi else { return }
        
        print("📍 [Mock Coordinator] Selected POI: \(poi.name)")
        print("   Score: \(step.score ?? 0)")
        print("   Time: \(step.getStartTime() ?? "N/A") - \(step.getEndTime() ?? "N/A")")
        
        // Show POI details in alert for demo purposes
        let message = """
        Name: \(poi.name)
        Rating: \(poi.rating ?? 0) ⭐ (\(poi.ratingCount ?? 0) reviews)
        Address: \(poi.address ?? "N/A")
        Score: \(step.score ?? 0)
        Time: \(step.getStartTime() ?? "N/A") - \(step.getEndTime() ?? "N/A")
        """
        
        let alert = UIAlertController(
            title: "POI Details",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        alert.addAction(UIAlertAction(title: "View on Map", style: .default) { _ in
            print("🗺️ [Mock Coordinator] Open map for: \(poi.name)")
            // Here you would open the map view
        })
        viewController.present(alert, animated: true)
    }
    
    public func timelineItineraryDidSelectBookedActivity(_ viewController: TRPTimelineItineraryVC, segment: TRPTimelineSegment) {
        print("🎫 [Mock Coordinator] Selected booked activity: \(segment.title ?? "Unknown")")
        
        // Show activity details in alert for demo purposes
        let message = """
        Title: \(segment.title ?? "N/A")
        Description: \(segment.description ?? "N/A")
        Start: \(segment.startDate ?? "N/A")
        End: \(segment.endDate ?? "N/A")
        """
        
        let alert = UIAlertController(
            title: "Booked Activity",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }
    
    public func timelineItineraryAddButtonPressed(_ viewController: TRPTimelineItineraryVC, atSectionIndex: Int) {
        print("➕ [Mock Coordinator] Add button pressed at section: \(atSectionIndex)")
        
        // Show action sheet for demo purposes
        let alert = UIAlertController(
            title: "Add Item",
            message: "What would you like to add?",
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "Add Place", style: .default) { _ in
            print("🏛️ [Mock Coordinator] Add place selected")
        })
        
        alert.addAction(UIAlertAction(title: "Add Activity", style: .default) { _ in
            print("🎯 [Mock Coordinator] Add activity selected")
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad support
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = viewController.view
            popoverController.sourceRect = CGRect(x: viewController.view.bounds.midX,
                                                  y: viewController.view.bounds.midY,
                                                  width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        viewController.present(alert, animated: true)
    }
    
    public func timelineItineraryChangeTimePressed(_ viewController: TRPTimelineItineraryVC, step: TRPTimelineStep) {
        guard let poi = step.poi else { return }

        print("🕐 [Mock Coordinator] Change time for: \(poi.name)")

        // Show time picker for demo purposes
        let alert = UIAlertController(
            title: "Change Time",
            message: "Select new time for \(poi.name)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        viewController.present(alert, animated: true)

        // In real implementation, this would:
        // - Open time picker
        // - Update step time via API
        // - Refresh UI
    }

    public func timelineItineraryRemoveStepPressed(_ viewController: TRPTimelineItineraryVC, step: TRPTimelineStep) {
        guard let poi = step.poi else { return }

        print("🗑️ [Mock Coordinator] Remove step: \(poi.name)")

        // Show confirmation for demo purposes
        let alert = UIAlertController(
            title: "Remove Step",
            message: "Are you sure you want to remove \(poi.name) from your itinerary?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Remove", style: .destructive) { _ in
            print("🗑️ [Mock Coordinator] Confirmed removal of \(poi.name)")
            // In real implementation, remove the step via API
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        viewController.present(alert, animated: true)

        // In real implementation, this would:
        // - Send delete request to API
        // - Update local data
        // - Refresh UI
    }
}

// MARK: - Convenience Factory Methods
extension TRPTimelineMockCoordinator {
    
    /// Create and start a mock timeline coordinator
    public static func createAndStart(in navigationController: UINavigationController) -> TRPTimelineMockCoordinator {
        let coordinator = TRPTimelineMockCoordinator(navigationController: navigationController)
        coordinator.start()
        return coordinator
    }
    
    /// Create and present a mock timeline coordinator modally
    public static func createAndPresent(from viewController: UIViewController) -> TRPTimelineMockCoordinator {
        let coordinator = TRPTimelineMockCoordinator(navigationController: UINavigationController())
        coordinator.presentModally(from: viewController)
        return coordinator
    }
}

// MARK: - Quick Test Method (for development/testing)
#if DEBUG
extension TRPTimelineMockCoordinator {
    
    /// Quick test method to launch timeline from any view controller
    /// Usage: TRPTimelineMockCoordinator.quickTest(from: self)
    public static func quickTest(from viewController: UIViewController) {
        if let navController = viewController.navigationController {
            _ = TRPTimelineMockCoordinator.createAndStart(in: navController)
        } else if let navController = viewController as? UINavigationController {
            _ = TRPTimelineMockCoordinator.createAndStart(in: navController)
        } else {
            _ = TRPTimelineMockCoordinator.createAndPresent(from: viewController)
        }
    }
}
#endif

