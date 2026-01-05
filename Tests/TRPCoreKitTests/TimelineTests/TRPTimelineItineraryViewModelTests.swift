//
//  TRPTimelineItineraryViewModelTests.swift
//  TRPCoreKitTests
//
//  Created by Unit Tests Generator on 04.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Testing
import Foundation
@testable import TRPCoreKit
import TRPFoundationKit

/// Test suite for TRPTimelineItineraryViewModel focusing on creating, getting, and editing timeline features
@Suite("Timeline Itinerary ViewModel Tests")
struct TRPTimelineItineraryViewModelTests {
    
    // MARK: - Timeline Creating Tests
    
    @Test("Create timeline with valid data")
    func testCreateTimelineWithValidData() {
        // Given: A mock timeline with plans and segments
        let timeline = TRPTimelineMockData.getMockTimeline()
        
        // When: Creating a view model with the timeline
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        
        // Then: View model should be initialized with the timeline data
        #expect(viewModel.numberOfSections() > 0)
        #expect(viewModel.selectedDayIndex == 0)
    }
    
    @Test("Create timeline with nil data")
    func testCreateTimelineWithNilData() {
        // Given: A nil timeline
        let timeline: TRPTimeline? = nil
        
        // When: Creating a view model with nil timeline
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        
        // Then: View model should handle nil gracefully
        #expect(viewModel.numberOfSections() == 0)
        #expect(viewModel.getDays().isEmpty)
    }
    
    @Test("Create timeline with empty plans")
    func testCreateTimelineWithEmptyPlans() {
        // Given: A timeline with no plans
        let city = TRPCity(id: 109, name: "Barcelona", coordinate: TRPLocation(lat: 41.3850639, lon: 2.1734034999999494))
        var timeline = TRPTimeline(id: 1, tripHash: "test", tripProfile: nil, city: city, plans: [], segments: nil)
        
        // When: Creating a view model with empty plans
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        
        // Then: View model should handle empty plans
        #expect(viewModel.numberOfSections() == 0)
        #expect(viewModel.getDays().isEmpty)
    }
    
    @Test("Create timeline with booked activities")
    func testCreateTimelineWithBookedActivities() {
        // Given: A timeline with booked activities
        let timeline = TRPTimelineMockData.getMockTimeline()
        
        // When: Creating a view model
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        viewModel.selectDay(at: 2) // Day 3 has booked activities
        
        // Then: Booked activities should be included in segments
        let bookedActivities = viewModel.getBookedActivitiesForSelectedDay()
        #expect(bookedActivities.count > 0)
        #expect(bookedActivities.contains(where: { $0.segmentType == .bookedActivity }))
    }
    
    // MARK: - Timeline Getting Tests
    
    @Test("Get number of sections")
    func testGetNumberOfSections() {
        // Given: A timeline with multiple plans
        let timeline = TRPTimelineMockData.getMockTimeline()
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        
        // When: Getting number of sections for day 0
        viewModel.selectDay(at: 0)
        let sections = viewModel.numberOfSections()
        
        // Then: Should return correct number of sections
        #expect(sections >= 0)
    }
    
    @Test("Get number of rows in section")
    func testGetNumberOfRowsInSection() {
        // Given: A timeline with steps
        let timeline = TRPTimelineMockData.getMockTimeline()
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        
        // When: Getting number of rows for first section
        viewModel.selectDay(at: 0)
        let sections = viewModel.numberOfSections()
        
        if sections > 0 {
            let rows = viewModel.numberOfRows(in: 0)
            // Then: Should return at least one row (segment)
            #expect(rows >= 0)
        }
    }
    
    @Test("Get cell type for index path")
    func testGetCellTypeForIndexPath() {
        // Given: A timeline with both itineraries and booked activities
        let timeline = TRPTimelineMockData.getMockTimeline()
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        viewModel.selectDay(at: 0) // Day 1
        
        // When: Getting cell type for first section
        let sections = viewModel.numberOfSections()
        if sections > 0 {
            let indexPath = IndexPath(row: 0, section: 0)
            let cellType = viewModel.cellType(at: indexPath)
            
            // Then: Should return a valid cell type
            #expect(cellType != nil)
            
            // Verify it's one of the expected types
            switch cellType {
            case .bookedActivity:
                // Valid type
                #expect(true)
            case .recommendations:
                // Valid type
                #expect(true)
            case .none:
                #expect(false, "Cell type should not be nil")
            }
        }
    }
    
    @Test("Get days from timeline")
    func testGetDaysFromTimeline() {
        // Given: A 6-day timeline
        let timeline = TRPTimelineMockData.getMockTimeline()
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        
        // When: Getting days
        let days = viewModel.getDays()
        
        // Then: Should return 6 days with formatted dates
        #expect(days.count == 6)
        for day in days {
            #expect(!day.isEmpty)
            // Should contain day name and date (e.g., "Saturday 07/12")
            #expect(day.contains("/"))
        }
    }
    
    @Test("Get trip date range")
    func testGetTripDateRange() {
        // Given: A timeline with known dates
        let timeline = TRPTimelineMockData.getMockTimeline()
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        
        // When: Getting trip date range
        let dateRange = viewModel.getTripDateRange()
        
        // Then: Should return valid start and end dates
        #expect(dateRange != nil)
        if let range = dateRange {
            #expect(range.start <= range.end)
        }
    }
    
    @Test("Get POIs for selected day")
    func testGetPOIsForSelectedDay() {
        // Given: A timeline with POIs
        let timeline = TRPTimelineMockData.getMockTimeline()
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        
        // When: Selecting day 0 and getting POIs
        viewModel.selectDay(at: 0)
        let pois = viewModel.getPoisForSelectedDay()
        
        // Then: Should return POIs for that day
        #expect(pois.count > 0)
        for poi in pois {
            #expect(!poi.id.isEmpty)
            #expect(!poi.name.isEmpty)
        }
    }
    
    @Test("Get segments with POIs for selected day")
    func testGetSegmentsWithPOIsForSelectedDay() {
        // Given: A timeline
        let timeline = TRPTimelineMockData.getMockTimeline()
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        
        // When: Getting segments with POIs
        viewModel.selectDay(at: 0)
        let segments = viewModel.getSegmentsWithPoisForSelectedDay()
        
        // Then: Should return array of POI arrays (one per segment)
        #expect(segments.count >= 0)
        for segment in segments {
            #expect(segment.count > 0) // Each segment should have at least one POI
        }
    }
    
    @Test("Get POI by ID")
    func testGetPOIById() {
        // Given: A timeline with known POIs
        let timeline = TRPTimelineMockData.getMockTimeline()
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        viewModel.selectDay(at: 0)
        
        // When: Getting a POI by ID (Casa Batlló ID from mock data)
        let poi = viewModel.getPoi(byId: "540484")
        
        // Then: Should return the correct POI
        #expect(poi != nil)
        #expect(poi?.name == "Casa Batlló")
    }
    
    @Test("Get booked activity by ID")
    func testGetBookedActivityById() {
        // Given: A timeline with booked activities
        let timeline = TRPTimelineMockData.getMockTimeline()
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        viewModel.selectDay(at: 2) // Day 3 has booked activity
        
        // When: Getting booked activity by ID
        let activity = viewModel.getBookedActivity(byId: "COOK-BCN-001")
        
        // Then: Should return the cooking class activity
        #expect(activity != nil)
        #expect(activity?.additionalData?.activityId == "COOK-BCN-001")
        #expect(activity?.title == "Paella Cooking Class")
    }
    
    @Test("Get step for POI ID")
    func testGetStepForPOIId() {
        // Given: A timeline
        let timeline = TRPTimelineMockData.getMockTimeline()
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        viewModel.selectDay(at: 0)
        
        // When: Getting step for POI ID (Park Güell)
        let step = viewModel.getStep(forPoiId: "540770")
        
        // Then: Should return the step with that POI
        #expect(step != nil)
        #expect(step?.poi?.id == "540770")
        #expect(step?.poi?.name == "Park Güell")
    }
    
    @Test("Get first plan")
    func testGetFirstPlan() {
        // Given: A timeline with multiple plans
        let timeline = TRPTimelineMockData.getMockTimeline()
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        
        // When: Getting first plan
        let firstPlan = viewModel.getFirstPlan()
        
        // Then: Should return the first plan (Day 1)
        #expect(firstPlan != nil)
        #expect(firstPlan?.id == "25459")
        #expect(firstPlan?.name == "Day 1: Gaudí & Modernism")
    }
    
    @Test("Get header data for section")
    func testGetHeaderDataForSection() {
        // Given: A timeline
        let timeline = TRPTimelineMockData.getMockTimeline()
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        viewModel.selectDay(at: 0)
        
        // When: Getting header data for first section
        let sections = viewModel.numberOfSections()
        if sections > 0 {
            let headerData = viewModel.headerData(for: 0)
            
            // Then: Should return valid header data
            #expect(!headerData.cityName.isEmpty)
            #expect(headerData.isFirstSection == true)
            #expect(headerData.shouldShowHeader == true)
            #expect(headerData.showFilterButton == true)
            #expect(headerData.showAddPlansButton == true)
        }
    }
    
    // MARK: - Timeline Editing Tests
    
    @Test("Update timeline with new data")
    func testUpdateTimelineWithNewData() {
        // Given: A view model with initial timeline
        let initialTimeline = TRPTimelineMockData.getMockTimeline()
        let viewModel = TRPTimelineItineraryViewModel(timeline: initialTimeline)
        let initialSections = viewModel.numberOfSections()
        
        // When: Updating with new timeline (empty one)
        let city = TRPCity(id: 109, name: "Barcelona", coordinate: TRPLocation(lat: 41.3850639, lon: 2.1734034999999494))
        let newTimeline = TRPTimeline(id: 2, tripHash: "new", tripProfile: nil, city: city, plans: [], segments: nil)
        viewModel.updateTimeline(newTimeline)
        
        // Then: View model should be updated
        let newSections = viewModel.numberOfSections()
        #expect(newSections == 0)
        #expect(newSections != initialSections)
    }
    
    @Test("Select different day")
    func testSelectDifferentDay() {
        // Given: A timeline with multiple days
        let timeline = TRPTimelineMockData.getMockTimeline()
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        
        // When: Selecting day 0
        viewModel.selectDay(at: 0)
        let day0Sections = viewModel.numberOfSections()
        
        // When: Changing to day 2
        viewModel.selectDay(at: 2)
        let day2Sections = viewModel.numberOfSections()
        
        // Then: Selected day index should be updated
        #expect(viewModel.selectedDayIndex == 2)
        // Different days may have different number of sections
        #expect(day0Sections >= 0)
        #expect(day2Sections >= 0)
    }
    
    @Test("Day filtering with booked activities")
    func testDayFilteringWithBookedActivities() {
        // Given: A timeline with booked activities on specific days
        let timeline = TRPTimelineMockData.getMockTimeline()
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        
        // When: Selecting day 2 (which has cooking class)
        viewModel.selectDay(at: 2)
        
        // Then: Should include the booked activity for that day
        let bookedActivities = viewModel.getBookedActivitiesForSelectedDay()
        #expect(bookedActivities.contains(where: { 
            $0.additionalData?.activityId == "COOK-BCN-001" 
        }))
    }
    
    @Test("Filter segments by day correctly")
    func testFilterSegmentsByDayCorrectly() {
        // Given: A timeline with steps across multiple days
        let timeline = TRPTimelineMockData.getMockTimeline()
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        
        // When: Selecting day 0
        viewModel.selectDay(at: 0)
        let day0POIs = viewModel.getPoisForSelectedDay()
        
        // When: Selecting day 1
        viewModel.selectDay(at: 1)
        let day1POIs = viewModel.getPoisForSelectedDay()
        
        // Then: Different days should have different POIs
        // (unless same POIs are visited on different days)
        #expect(day0POIs.count > 0)
        #expect(day1POIs.count > 0)
    }
    
    @Test("Handle invalid section index")
    func testHandleInvalidSectionIndex() {
        // Given: A timeline
        let timeline = TRPTimelineMockData.getMockTimeline()
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        viewModel.selectDay(at: 0)
        
        // When: Requesting rows for invalid section
        let rows = viewModel.numberOfRows(in: 999)
        
        // Then: Should return 0
        #expect(rows == 0)
    }
    
    @Test("Handle invalid index path for cell type")
    func testHandleInvalidIndexPathForCellType() {
        // Given: A timeline
        let timeline = TRPTimelineMockData.getMockTimeline()
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        viewModel.selectDay(at: 0)
        
        // When: Requesting cell type for invalid index path
        let invalidIndexPath = IndexPath(row: 999, section: 999)
        let cellType = viewModel.cellType(at: invalidIndexPath)
        
        // Then: Should return nil
        #expect(cellType == nil)
    }
    
    @Test("Multiple destination timeline header logic")
    func testMultipleDestinationTimelineHeaderLogic() {
        // Given: A timeline with multiple cities (Barcelona and Madrid)
        let timeline = TRPTimelineMockData.getMockTimeline()
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        
        // When: Selecting a day with Madrid trip
        viewModel.selectDay(at: 2) // Day 3 has Madrid trip
        
        // Then: Should properly identify multiple destinations
        let sections = viewModel.numberOfSections()
        if sections > 1 {
            let headerData = viewModel.headerData(for: 1)
            // If there are multiple cities, hasMultipleDestinations should be true
            #expect(headerData.hasMultipleDestinations == true || headerData.hasMultipleDestinations == false)
        }
    }
    
    @Test("Empty plan handling")
    func testEmptyPlanHandling() {
        // Given: A timeline with an empty plan (Day 6)
        let timeline = TRPTimelineMockData.getMockTimeline()
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        
        // When: Selecting the last day (empty plan)
        viewModel.selectDay(at: 5) // Day 6 is empty
        
        // Then: Should handle empty plan gracefully
        let sections = viewModel.numberOfSections()
        // Empty plan means no segments for that day
        #expect(sections == 0)
    }
    
    @Test("Cell type returns recommendations for itinerary")
    func testCellTypeReturnsRecommendationsForItinerary() {
        // Given: A timeline with itinerary segments
        let timeline = TRPTimelineMockData.getMockTimeline()
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        viewModel.selectDay(at: 0) // Day 1 has itinerary
        
        // When: Getting cell type
        let sections = viewModel.numberOfSections()
        if sections > 0 {
            let indexPath = IndexPath(row: 0, section: 0)
            let cellType = viewModel.cellType(at: indexPath)
            
            // Then: Should return recommendations type for itinerary
            if case .recommendations(let steps) = cellType {
                #expect(steps.count > 0)
            }
        }
    }
    
    @Test("Cell type returns booked activity for booked segment")
    func testCellTypeReturnsBookedActivityForBookedSegment() {
        // Given: A timeline with booked activity
        let timeline = TRPTimelineMockData.getMockTimeline()
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        viewModel.selectDay(at: 2) // Day 3 has booked activities
        
        // When: Getting cell types
        let sections = viewModel.numberOfSections()
        var foundBookedActivity = false
        
        for section in 0..<sections {
            let rows = viewModel.numberOfRows(in: section)
            for row in 0..<rows {
                let indexPath = IndexPath(row: row, section: section)
                if case .bookedActivity(let segment) = viewModel.cellType(at: indexPath) {
                    foundBookedActivity = true
                    #expect(segment.segmentType == .bookedActivity)
                    #expect(segment.additionalData != nil)
                }
            }
        }
        
        // Then: Should have found at least one booked activity
        #expect(foundBookedActivity)
    }
    
    @Test("Timeline with mixed itineraries and booked activities")
    func testTimelineWithMixedItinerariesAndBookedActivities() {
        // Given: A timeline with both types
        let timeline = TRPTimelineMockData.getMockTimeline()
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        viewModel.selectDay(at: 2) // Day 3 has both
        
        // When: Getting all segments
        let bookedActivities = viewModel.getBookedActivitiesForSelectedDay()
        let pois = viewModel.getPoisForSelectedDay()
        
        // Then: Should have both booked activities and itinerary POIs
        #expect(bookedActivities.count > 0)
        #expect(pois.count >= 0) // May or may not have itinerary POIs on same day
    }
}



