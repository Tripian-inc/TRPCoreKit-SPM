//
//  TRPTimelineMockDataUsageExample.swift
//  TRPCoreKit
//
//  Created by Mock Data Generator on 02.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

/**
 Example usage of TRPTimelineMockData with TRPTimelineItineraryVC
 
 This file demonstrates how to use the mock timeline data to initialize
 and display the TRPTimelineItineraryVC.
 */

class TRPTimelineMockDataUsageExample {
    
    /// Example 1: Basic usage with mock data
    func example1_BasicUsage() -> TRPTimelineItineraryVC {
        // Get mock timeline data
        let mockTimeline = TRPTimelineMockData.getMockTimeline()
        
        // Create view model with mock data
        let viewModel = TRPTimelineItineraryViewModel(timeline: mockTimeline)
        
        // Create view controller
        let viewController = TRPTimelineItineraryVC(viewModel: viewModel)
        
        return viewController
    }
    
    /// Example 2: Usage with delegate
    func example2_WithDelegate(delegate: TRPTimelineItineraryVCDelegate) -> TRPTimelineItineraryVC {
        // Get mock timeline data
        let mockTimeline = TRPTimelineMockData.getMockTimeline()
        
        // Create view model with mock data
        let viewModel = TRPTimelineItineraryViewModel(timeline: mockTimeline)
        
        // Create view controller
        let viewController = TRPTimelineItineraryVC(viewModel: viewModel)
        viewController.delegate = delegate
        
        return viewController
    }
    
    /// Example 3: Present in navigation controller
    func example3_PresentInNavigationController(from presentingVC: UIViewController) {
        // Get mock timeline data
        let mockTimeline = TRPTimelineMockData.getMockTimeline()
        
        // Create view model with mock data
        let viewModel = TRPTimelineItineraryViewModel(timeline: mockTimeline)
        
        // Create view controller
        let viewController = TRPTimelineItineraryVC(viewModel: viewModel)
        
        // Wrap in navigation controller
        let navigationController = UINavigationController(rootViewController: viewController)
        
        // Present
        presentingVC.present(navigationController, animated: true, completion: nil)
    }
    
    /// Example 4: Push to existing navigation controller
    func example4_PushToNavigationController(navigationController: UINavigationController) {
        // Get mock timeline data
        let mockTimeline = TRPTimelineMockData.getMockTimeline()
        
        // Create view model with mock data
        let viewModel = TRPTimelineItineraryViewModel(timeline: mockTimeline)
        
        // Create view controller
        let viewController = TRPTimelineItineraryVC(viewModel: viewModel)
        
        // Push to navigation stack
        navigationController.pushViewController(viewController, animated: true)
    }
    
    /// Example 5: Accessing timeline data directly
    func example5_AccessTimelineData() {
        // Get mock timeline data
        let mockTimeline = TRPTimelineMockData.getMockTimeline()
        
        // Access timeline properties
        print("Timeline ID: \(mockTimeline.id)")
        print("Trip Hash: \(mockTimeline.tripHash)")
        print("City: \(mockTimeline.city.name)")
        
        // Access plans
        if let plans = mockTimeline.plans {
            print("Number of plans: \(plans.count)") // 6 plans
            
            for (index, plan) in plans.enumerated() {
                print("\nPlan \(index + 1):")
                print("  ID: \(plan.id)")
                print("  Name: \(plan.name ?? "N/A")")
                print("  Start: \(plan.startDate)")
                print("  End: \(plan.endDate)")
                print("  Steps count: \(plan.steps.count)")
                
                // Access steps
                for (stepIndex, step) in plan.steps.enumerated() {
                    print("\n  Step \(stepIndex + 1):")
                    print("    POI: \(step.poi?.name ?? "N/A")")
                    print("    Start time: \(step.startDateTimes ?? "N/A")")
                    print("    End time: \(step.endDateTimes ?? "N/A")")
                    print("    Score: \(step.score ?? 0)")
                }
            }
        }
        
        // Get all POIs in the timeline
        let allPois = mockTimeline.getPois()
        print("\nTotal unique POIs: \(allPois.count)")
    }
    
    /// Example 7: Working with Day 2's Alternative Plans
    func example7_Day2AlternativePlans() {
        let mockTimeline = TRPTimelineMockData.getMockTimeline()
        
        // Filter plans for Day 2 (December 8th)
        let day2Plans = mockTimeline.plans?.filter { plan in
            plan.getStartDate()?.toString(format: "yyyy-MM-dd") == "2025-12-08"
        }
        
        print("Day 2 has \(day2Plans?.count ?? 0) alternative plans")
        
        if let plans = day2Plans {
            for (index, plan) in plans.enumerated() {
                print("\n🗓️ Option \(index + 1):")
                print("   Plan ID: \(plan.id)")
                print("   Name: \(plan.name ?? "")")
                print("   Description: \(plan.description ?? "")")
                print("   Activities: \(plan.steps.count)")
                print("   POIs: \(plan.steps.compactMap { $0.poi?.name }.joined(separator: ", "))")
            }
        }
        
        // Compare the two plans
        if let planA = day2Plans?.first, let planB = day2Plans?.last {
            print("\n📊 Comparison:")
            print("   Plan A: \(planA.steps.count) activities")
            print("   Plan B: \(planB.steps.count) activities")
            
            let planAPOIs = Set(planA.steps.compactMap { $0.poi?.id })
            let planBPOIs = Set(planB.steps.compactMap { $0.poi?.id })
            let commonPOIs = planAPOIs.intersection(planBPOIs)
            
            print("   Common POIs: \(commonPOIs.count)")
            print("   Unique to Plan A: \(planAPOIs.subtracting(planBPOIs).count)")
            print("   Unique to Plan B: \(planBPOIs.subtracting(planAPOIs).count)")
        }
    }
    
    /// Example 8: Working with Booked Activity Segments
    func example8_BookedActivitySegments() {
        let mockTimeline = TRPTimelineMockData.getMockTimeline()
        
        guard let profile = mockTimeline.tripProfile else { return }
        
        // Separate segments by type
        let itinerarySegments = profile.segments.filter { $0.segmentType == .itinerary }
        let bookedActivities = profile.segments.filter { $0.segmentType == .bookedActivity }
        
        print("📊 Segment Summary:")
        print("   Itinerary segments: \(itinerarySegments.count)")
        print("   Booked activities: \(bookedActivities.count)")
        
        // Display booked activities
        for activity in bookedActivities {
            print("\n🎫 Booked Activity:")
            print("   Title: \(activity.title ?? "N/A")")
            print("   Date: \(activity.startDate ?? "") to \(activity.endDate ?? "")")
            print("   Available: \(activity.available)") // false - can't be modified
            print("   Day: \(activity.dayIds ?? [])")
            
            // Access additional booking data
            if let bookingData = activity.additionalData {
                print("\n   📋 Booking Information:")
                print("   Activity ID: \(bookingData.activityId ?? "N/A")")
                print("   Booking ID: \(bookingData.bookingId ?? "N/A")")
                print("   Title: \(bookingData.title ?? "N/A")")
                print("   Description: \(bookingData.description ?? "N/A")")
                print("   Participants: \(bookingData.adultCount) adults, \(bookingData.childCount) children")
                print("   Cancellation Policy: \(bookingData.cancellation ?? "N/A")")
                
//                let coord = bookingData.coordinate {
//                    print("   Location: \(coord.lat), \(coord.lon)")
//                }
            }
        }
        
        // Check if Day 3 has a booked activity
        let day3BookedActivities = bookedActivities.filter { $0.dayIds?.contains(25461) ?? false }
        if !day3BookedActivities.isEmpty {
            print("\n✅ Day 3 (December 9th) has \(day3BookedActivities.count) booked activities")
            print("   These activities will appear in the timeline but cannot be moved or removed")
        }
    }
    
    /// Example 10: Accessing Multi-City Segments
    func example10_MultiCitySegments() {
        let mockTimeline = TRPTimelineMockData.getMockTimeline()
        
        guard let profile = mockTimeline.tripProfile else { return }
        
        // Group segments by city
        var segmentsByCity: [String: [TRPTimelineSegment]] = [:]
        
        for segment in profile.segments {
            let cityName = segment.city?.name ?? "Unknown"
            if segmentsByCity[cityName] == nil {
                segmentsByCity[cityName] = []
            }
            segmentsByCity[cityName]?.append(segment)
        }
        
        print("🌍 Multi-City Trip Overview:")
        print("   Cities visited: \(segmentsByCity.keys.count)")
        
        for (city, segments) in segmentsByCity {
            print("\n📍 \(city):")
            print("   Segments: \(segments.count)")
            
            for segment in segments {
                print("\n   🎯 \(segment.title ?? "Unknown")")
                print("      Type: \(segment.segmentType)")
                print("      Available: \(segment.available)")
                print("      Duration: \(segment.startDate ?? "") - \(segment.endDate ?? "")")
                
                // Check if it's a different location trip
                if segment.differentEndLocation {
                    print("      ✈️ Different destination!")
                    if let start = segment.coordinate, let end = segment.destinationCoordinate {
                        print("      Start: \(start.lat), \(start.lon)")
                        print("      End: \(end.lat), \(end.lon)")
                    }
                }
                
                // Show booking details if available
                if let booking = segment.additionalData {
                    print("      🎫 Booking ID: \(booking.bookingId ?? "N/A")")
                }
            }
        }
        
        // Find segments with different locations
        let differentLocationSegments = profile.segments.filter { $0.differentEndLocation }
        if !differentLocationSegments.isEmpty {
            print("\n\n🚄 Segments with Different Locations: \(differentLocationSegments.count)")
            for segment in differentLocationSegments {
                print("   • \(segment.title ?? "Unknown") - From \(segment.city?.name ?? "?") to other location")
            }
        }
    }
    
    /// Example 9: Using with custom delegate implementation
    func example9_CustomDelegateImplementation() {
        // Create a custom delegate
        class TimelineDelegate: TRPTimelineItineraryVCDelegate {
            func timelineItineraryDidRequestActivityReservation(_ viewController: TRPTimelineItineraryVC, activityId: String) {
                
            }
            
            func timelineItineraryFilterPressed(_ viewController: TRPTimelineItineraryVC) {
                print("Filter button pressed")
            }
            
            func timelineItineraryAddPlansPressed(_ viewController: TRPTimelineItineraryVC) {
                print("Add plans button pressed")
            }
            
            func timelineItineraryDidSelectStep(_ viewController: TRPTimelineItineraryVC, step: TRPTimelineStep) {
                print("Selected step: \(step.poi?.name ?? "Unknown")")
            }
            
            func timelineItineraryDidSelectBookedActivity(_ viewController: TRPTimelineItineraryVC, segment: TRPTimelineSegment) {
                print("Selected booked activity: \(segment.title ?? "Unknown")")
            }
            
            func timelineItineraryAddButtonPressed(_ viewController: TRPTimelineItineraryVC, atSectionIndex: Int) {
                print("Add button pressed at section: \(atSectionIndex)")
            }
            
            func timelineItineraryThumbsUpPressed(_ viewController: TRPTimelineItineraryVC, step: TRPTimelineStep) {
                print("Thumbs up for: \(step.poi?.name ?? "Unknown")")
            }
            
            func timelineItineraryThumbsDownPressed(_ viewController: TRPTimelineItineraryVC, step: TRPTimelineStep) {
                print("Thumbs down for: \(step.poi?.name ?? "Unknown")")
            }
        }
        
        // Get mock timeline data
        let mockTimeline = TRPTimelineMockData.getMockTimeline()
        
        // Create view model
        let viewModel = TRPTimelineItineraryViewModel(timeline: mockTimeline)
        
        // Create view controller with delegate
        let viewController = TRPTimelineItineraryVC(viewModel: viewModel)
        viewController.delegate = TimelineDelegate()
        
        // Now viewController is ready to use
    }
}

// MARK: - Quick Access Functions
extension TRPTimelineMockDataUsageExample {
    
    /// Quick function to get a configured TRPTimelineItineraryVC with mock data
    static func getTimelineViewController(with delegate: TRPTimelineItineraryVCDelegate? = nil) -> TRPTimelineItineraryVC {
        let mockTimeline = TRPTimelineMockData.getMockTimeline()
        let viewModel = TRPTimelineItineraryViewModel(timeline: mockTimeline)
        let viewController = TRPTimelineItineraryVC(viewModel: viewModel)
        viewController.delegate = delegate
        return viewController
    }
    
    /// Quick function to get a navigation controller with TRPTimelineItineraryVC
    static func getTimelineNavigationController(with delegate: TRPTimelineItineraryVCDelegate? = nil) -> UINavigationController {
        let viewController = getTimelineViewController(with: delegate)
        return UINavigationController(rootViewController: viewController)
    }
}

// MARK: - SwiftUI Preview Helper (if needed)
#if DEBUG
@available(iOS 13.0, *)
struct TRPTimelineItineraryVC_Previews {
    static func makePreview() -> UIViewController {
        return TRPTimelineMockDataUsageExample.getTimelineNavigationController()
    }
}
#endif

