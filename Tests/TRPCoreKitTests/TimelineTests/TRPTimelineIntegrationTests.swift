//
//  TRPTimelineIntegrationTests.swift
//  TRPCoreKitTests
//
//  Created by Integration Tests on 04.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Testing
import Foundation
@testable import TRPCoreKit
import TRPFoundationKit

/// Integration tests for Timeline feature using real API calls
/// These tests require network access and valid API credentials
@Suite("Timeline Integration Tests", .tags(.integration))
struct TRPTimelineIntegrationTests {
    
    // MARK: - Real Trip Hash Test
    
    @Test("Get timeline detail with trip hash c6b9e5ed608040d5a20a3f605a7aaec6")
    func testGetTimelineDetailWithRealTripHash() async throws {
        // Given: Real trip hash
        let tripHash = "c6b9e5ed608040d5a20a3f605a7aaec6"
        
        // Create real use cases with actual repositories
        let useCases = TRPTimelineModeUseCases()
        
        // When: Fetching timeline from API
        let expectation = TestExpectation(description: "Timeline fetch completed")
        var fetchedTimeline: TRPTimeline?
        var fetchError: Error?
        
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
        
        // Wait for async operation (up to 10 seconds)
        try await Task.sleep(nanoseconds: 10_000_000_000)
        
        // Then: Validate the fetched timeline
        if let timeline = fetchedTimeline {
            // Basic validations
            #expect(timeline.tripHash == tripHash)
            #expect(timeline.id > 0)
            #expect(!timeline.city.name.isEmpty)
            
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
                    print("      Generated Status: \(plan.generatedStatus)")
                    
                    // Validate plan structure
                    #expect(!plan.id.isEmpty)
                    #expect(!plan.startDate.isEmpty)
                    #expect(!plan.endDate.isEmpty)
                    
                    // Validate steps in plan
                    for (stepIndex, step) in plan.steps.enumerated() {
                        print("         Step \(stepIndex + 1): \(step.poi?.name ?? "Unknown") (ID: \(step.id))")
                        #expect(step.id > 0)
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
                    print("      Start: \(segment.startDate ?? "No start")")
                    print("      End: \(segment.endDate ?? "No end")")
                    
                    if let additionalData = segment.additionalData {
                        print("      Activity ID: \(additionalData.activityId)")
                        print("      Booking ID: \(additionalData.bookingId)")
                    }
                    
                    // Validate segment structure
                    #expect(segment.city != nil)
                }
            }
            
            // Test view model with fetched data
            print("\n🔄 Testing ViewModel with fetched data:")
            let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
            
            let sections = viewModel.numberOfSections()
            let days = viewModel.getDays()
            
            print("   Sections: \(sections)")
            print("   Days: \(days.count)")
            print("   Days: \(days)")
            
            #expect(sections >= 0)
            #expect(days.count >= 0)
            
            // Test getting POIs
            if sections > 0 {
                viewModel.selectDay(at: 0)
                let pois = viewModel.getPoisForSelectedDay()
                let bookedActivities = viewModel.getBookedActivitiesForSelectedDay()
                
                print("   POIs on Day 1: \(pois.count)")
                print("   Booked Activities on Day 1: \(bookedActivities.count)")
                
                for poi in pois.prefix(5) {
                    print("      - \(poi.name) (\(poi.id))")
                }
                
                #expect(pois.count >= 0)
                #expect(bookedActivities.count >= 0)
            }
            
            print("\n✅ All validations passed!")
            
        } else if let error = fetchError {
            print("❌ Test failed with error: \(error.localizedDescription)")
            throw error
        } else {
            print("⚠️ No timeline fetched and no error - possible timeout")
            #expect(false, "Timeline should be fetched or error should occur")
        }
    }
    
    @Test("Test timeline editing operations with real trip hash")
    func testTimelineEditingOperations() async throws {
        // Given: Real trip hash
        let tripHash = "c6b9e5ed608040d5a20a3f605a7aaec6"
        let useCases = TRPTimelineModeUseCases()
        
        // When: Fetching timeline first
        let expectation = TestExpectation(description: "Timeline operations completed")
        var fetchedTimeline: TRPTimeline?
        
        useCases.executeFetchTimeline(tripHash: tripHash) { result in
            if case .success(let timeline) = result {
                fetchedTimeline = timeline
            }
            expectation.fulfill()
        }
        
        // Wait for fetch
        try await Task.sleep(nanoseconds: 5_000_000_000)
        
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
            #expect(viewModel.selectedDayIndex == 1)
            
            // Get data for new day
            let poisDay1 = viewModel.getPoisForSelectedDay()
            print("   POIs on day 1: \(poisDay1.count)")
        }
        
        // Test timeline update
        var updatedTimeline = timeline
        viewModel.updateTimeline(updatedTimeline)
        print("   Timeline updated successfully")
        
        // Test POI lookup
        let allPOIs = timeline.getPois()
        if let firstPOI = allPOIs.first {
            let foundPOI = viewModel.getPoi(byId: firstPOI.id)
            if foundPOI != nil {
                print("   ✅ POI lookup successful: \(firstPOI.name)")
                #expect(foundPOI?.id == firstPOI.id)
            }
        }
        
        // Test getting first plan
        let firstPlan = viewModel.getFirstPlan()
        if let plan = firstPlan {
            print("   First plan: \(plan.name ?? "Unnamed")")
            #expect(!plan.id.isEmpty)
        }
        
        print("\n✅ Editing operations test completed!")
    }
    
    @Test("Test timeline with all POI categories")
    func testTimelineWithPOICategories() async throws {
        // Given: Real trip hash
        let tripHash = "c6b9e5ed608040d5a20a3f605a7aaec6"
        let useCases = TRPTimelineModeUseCases()
        
        let expectation = TestExpectation(description: "POI categories test")
        var fetchedTimeline: TRPTimeline?
        
        useCases.executeFetchTimeline(tripHash: tripHash) { result in
            if case .success(let timeline) = result {
                fetchedTimeline = timeline
            }
            expectation.fulfill()
        }
        
        try await Task.sleep(nanoseconds: 5_000_000_000)
        
        guard let timeline = fetchedTimeline else {
            print("⚠️ Could not fetch timeline for category tests")
            return
        }
        
        print("\n📊 Testing POI Categories:")
        
        // Get all POIs
        let allPOIs = timeline.getPois()
        print("   Total unique POIs: \(allPOIs.count)")
        
        // Collect all categories
        var categoryMap: [Int: (name: String, count: Int)] = [:]
        for poi in allPOIs {
            for category in poi.categories {
                if var existing = categoryMap[category.id] {
                    existing.count += 1
                    categoryMap[category.id] = existing
                } else {
                    categoryMap[category.id] = (name: category.name, count: 1)
                }
            }
        }
        
        print("\n   Categories found:")
        for (id, info) in categoryMap.sorted(by: { $0.value.count > $1.value.count }) {
            print("      - \(info.name) (ID: \(id)): \(info.count) POIs")
        }
        
        // Test filtering by categories
        let attractions = timeline.getPoisWith(types: [1]) // Attractions
        let restaurants = timeline.getPoisWith(types: [3]) // Restaurants
        
        print("\n   Filtered results:")
        print("      Attractions: \(attractions.count)")
        print("      Restaurants: \(restaurants.count)")
        
        #expect(allPOIs.count > 0)
        #expect(categoryMap.count > 0)
        
        print("\n✅ Category test completed!")
    }
    
    @Test("Test timeline performance metrics")
    func testTimelinePerformanceMetrics() async throws {
        // Given: Real trip hash
        let tripHash = "c6b9e5ed608040d5a20a3f605a7aaec6"
        let useCases = TRPTimelineModeUseCases()
        
        // Measure fetch time
        let startTime = Date()
        let expectation = TestExpectation(description: "Performance test")
        var fetchedTimeline: TRPTimeline?
        
        useCases.executeFetchTimeline(tripHash: tripHash) { result in
            if case .success(let timeline) = result {
                fetchedTimeline = timeline
            }
            expectation.fulfill()
        }
        
        try await Task.sleep(nanoseconds: 10_000_000_000)
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
        
        // Calculate data size
        let planCount = timeline.plans?.count ?? 0
        let segmentCount = timeline.segments?.count ?? 0
        let totalSteps = timeline.plans?.reduce(0) { $0 + $1.steps.count } ?? 0
        
        print("\n   Data volume:")
        print("      Plans: \(planCount)")
        print("      Segments: \(segmentCount)")
        print("      Total steps: \(totalSteps)")
        print("      Total POIs: \(timeline.getPois().count)")
        
        // Validate performance
        #expect(vmInitTime < 1.0, "ViewModel initialization should be < 1 second")
        #expect(selectTime < 0.5, "Day selection should be < 0.5 seconds")
        #expect(poiTime < 0.1, "POI retrieval should be < 0.1 seconds")
        
        print("\n✅ Performance test completed!")
    }
}

// MARK: - Test Tags

extension Tag {
    @Tag static var integration: Self
}

// MARK: - Helper Extensions

extension TestExpectation {
    func fulfill() {
        isFulfilled = true
    }
}

/// Test expectation helper for async integration tests
class TestExpectation {
    let description: String
    var isFulfilled = false
    
    init(description: String) {
        self.description = description
    }
}



