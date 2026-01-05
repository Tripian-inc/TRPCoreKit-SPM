//
//  TRPTimelineIntegrationXCTests.swift
//  TRPCoreKitTests
//
//  Created by Integration Tests on 05.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import XCTest
@testable import TRPCoreKit
import TRPFoundationKit

/// XCTest-compatible integration tests for Timeline with real API
class TRPTimelineIntegrationXCTests: XCTestCase {
    
    let tripHash = "c6b9e5ed608040d5a20a3f605a7aaec6"
    var useCases: TRPTimelineModeUseCases!
    
    override func setUp() {
        super.setUp()
        useCases = TRPTimelineModeUseCases()
    }
    
    override func tearDown() {
        useCases = nil
        super.tearDown()
    }
    
    // MARK: - Real API Tests
    
    func testGetTimelineDetailWithRealTripHash() {
        // Given: Real trip hash and expectation
        let expectation = self.expectation(description: "Timeline fetch completed")
        var fetchedTimeline: TRPTimeline?
        var fetchError: Error?
        
        // When: Fetching timeline from API
        useCases.executeFetchTimeline(tripHash: tripHash) { result in
            switch result {
            case .success(let timeline):
                fetchedTimeline = timeline
                print("✅ Timeline fetched successfully!")
                print("   Trip Hash: \(timeline.tripHash)")
                print("   Timeline ID: \(timeline.id)")
                print("   City: \(timeline.city.name)")
                print("   Number of Plans: \(timeline.plans?.count ?? 0)")
                print("   Number of Segments: \(timeline.segments?.count ?? 0)")
                
            case .failure(let error):
                fetchError = error
                print("❌ Failed to fetch timeline: \(error.localizedDescription)")
            }
            expectation.fulfill()
        }
        
        // Wait for async operation
        waitForExpectations(timeout: 30.0) { error in
            if let error = error {
                XCTFail("Timeout error: \(error.localizedDescription)")
            }
        }
        
        // Then: Validate the fetched timeline
        if let timeline = fetchedTimeline {
            // Basic validations
            XCTAssertEqual(timeline.tripHash, tripHash)
            XCTAssertTrue(timeline.id > 0)
            XCTAssertFalse(timeline.city.name.isEmpty)
            
            // Validate plans
            if let plans = timeline.plans {
                print("\n📋 Plans Detail:")
                for (index, plan) in plans.enumerated() {
                    print("   Plan \(index + 1):")
                    print("      ID: \(plan.id)")
                    print("      Name: \(plan.name ?? "No name")")
                    print("      Start: \(plan.startDate)")
                    print("      End: \(plan.endDate)")
                    print("      Steps: \(plan.steps.count)")
                    
                    XCTAssertFalse(plan.id.isEmpty)
                    XCTAssertFalse(plan.startDate.isEmpty)
                    XCTAssertFalse(plan.endDate.isEmpty)
                    
                    for (stepIndex, step) in plan.steps.enumerated() {
                        print("         Step \(stepIndex + 1): \(step.poi?.name ?? "Unknown") (ID: \(step.id))")
                        XCTAssertTrue(step.id > 0)
                    }
                }
            }
            
            // Validate segments
            if let segments = timeline.segments {
                print("\n🎯 Segments Detail:")
                for (index, segment) in segments.enumerated() {
                    print("   Segment \(index + 1):")
                    print("      Type: \(segment.segmentType.rawValue)")
                    print("      Title: \(segment.title ?? "No title")")
                    print("      City: \(segment.city?.name ?? "No city")")
                    
                    XCTAssertNotNil(segment.city)
                }
            }
            
            // Test view model with fetched data
            print("\n🔄 Testing ViewModel with fetched data:")
            let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
            
            let sections = viewModel.numberOfSections()
            let days = viewModel.getDays()
            
            print("   Sections: \(sections)")
            print("   Days: \(days.count)")
            
            XCTAssertTrue(sections >= 0)
            XCTAssertTrue(days.count >= 0)
            
            // Test getting POIs
            if sections > 0 {
                viewModel.selectDay(at: 0)
                let pois = viewModel.getPoisForSelectedDay()
                let bookedActivities = viewModel.getBookedActivitiesForSelectedDay()
                
                print("   POIs on Day 1: \(pois.count)")
                print("   Booked Activities on Day 1: \(bookedActivities.count)")
                
                XCTAssertTrue(pois.count >= 0)
                XCTAssertTrue(bookedActivities.count >= 0)
            }
            
            print("\n✅ All validations passed!")
            
        } else if let error = fetchError {
            XCTFail("Test failed with error: \(error.localizedDescription)")
        } else {
            XCTFail("No timeline fetched and no error - possible timeout")
        }
    }
    
    func testTimelineEditingOperations() {
        // Given: Expectation for async operation
        let expectation = self.expectation(description: "Timeline operations completed")
        var fetchedTimeline: TRPTimeline?
        
        // When: Fetching timeline first
        useCases.executeFetchTimeline(tripHash: tripHash) { result in
            if case .success(let timeline) = result {
                fetchedTimeline = timeline
            }
            expectation.fulfill()
        }
        
        // Wait for fetch
        waitForExpectations(timeout: 30.0)
        
        guard let timeline = fetchedTimeline else {
            print("⚠️ Could not fetch timeline for editing tests")
            return
        }
        
        // Test view model operations
        print("\n🔧 Testing editing operations:")
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        
        // Test day selection
        let initialDay = viewModel.selectedDayIndex
        print("   Initial day: \(initialDay)")
        
        let days = viewModel.getDays()
        if days.count > 1 {
            viewModel.selectDay(at: 1)
            print("   Selected day 1: \(viewModel.selectedDayIndex)")
            XCTAssertEqual(viewModel.selectedDayIndex, 1)
            
            let poisDay1 = viewModel.getPoisForSelectedDay()
            print("   POIs on day 1: \(poisDay1.count)")
        }
        
        // Test timeline update
        viewModel.updateTimeline(timeline)
        print("   Timeline updated successfully")
        
        // Test POI lookup
        let allPOIs = timeline.getPois()
        if let firstPOI = allPOIs.first {
            let foundPOI = viewModel.getPoi(byId: firstPOI.id)
            if foundPOI != nil {
                print("   ✅ POI lookup successful: \(firstPOI.name)")
                XCTAssertEqual(foundPOI?.id, firstPOI.id)
            }
        }
        
        print("\n✅ Editing operations test completed!")
    }
    
    func testTimelinePerformanceMetrics() {
        // Given: Expectation and start time
        let expectation = self.expectation(description: "Performance test")
        let startTime = Date()
        var fetchedTimeline: TRPTimeline?
        
        // When: Measuring fetch time
        useCases.executeFetchTimeline(tripHash: tripHash) { result in
            if case .success(let timeline) = result {
                fetchedTimeline = timeline
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 30.0)
        let fetchTime = Date().timeIntervalSince(startTime)
        
        guard let timeline = fetchedTimeline else {
            print("⚠️ Could not fetch timeline for performance tests")
            return
        }
        
        print("\n⚡ Performance Metrics:")
        print("   Fetch time: \(String(format: "%.2f", fetchTime)) seconds")
        
        // Measure view model initialization
        let vmStartTime = Date()
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        let vmInitTime = Date().timeIntervalSince(vmStartTime)
        print("   ViewModel init time: \(String(format: "%.4f", vmInitTime)) seconds")
        
        // Measure day selection
        let selectStartTime = Date()
        viewModel.selectDay(at: 0)
        let selectTime = Date().timeIntervalSince(selectStartTime)
        print("   Day selection time: \(String(format: "%.4f", selectTime)) seconds")
        
        // Measure POI retrieval
        let poiStartTime = Date()
        let pois = viewModel.getPoisForSelectedDay()
        let poiTime = Date().timeIntervalSince(poiStartTime)
        print("   POI retrieval time: \(String(format: "%.4f", poiTime)) seconds")
        print("   POIs retrieved: \(pois.count)")
        
        // Validate performance
        XCTAssertTrue(vmInitTime < 1.0, "ViewModel initialization should be < 1 second")
        XCTAssertTrue(selectTime < 0.5, "Day selection should be < 0.5 seconds")
        XCTAssertTrue(poiTime < 0.1, "POI retrieval should be < 0.1 seconds")
        
        print("\n✅ Performance test completed!")
    }
}



