//
//  TRPTimelineViewModelXCTests.swift
//  TRPCoreKitTests
//
//  Created by Unit Tests on 05.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import XCTest
@testable import TRPCoreKit
import TRPFoundationKit

/// XCTest-compatible tests for TRPTimelineItineraryViewModel
class TRPTimelineViewModelXCTests: XCTestCase {
    
    var timeline: TRPTimeline!
    var viewModel: TRPTimelineItineraryViewModel!
    
    override func setUp() {
        super.setUp()
        timeline = TRPTimelineMockData.getMockTimeline()
        viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
    }
    
    override func tearDown() {
        timeline = nil
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Creating Tests
    
    func testCreateTimelineWithValidData() {
        // Given: A mock timeline
        let timeline = TRPTimelineMockData.getMockTimeline()
        
        // When: Creating a view model
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        
        // Then: View model should be initialized
        XCTAssertTrue(viewModel.numberOfSections() > 0)
        XCTAssertEqual(viewModel.selectedDayIndex, 0)
    }
    
    func testCreateTimelineWithNilData() {
        // Given: A nil timeline
        let timeline: TRPTimeline? = nil
        
        // When: Creating a view model
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)
        
        // Then: View model should handle nil gracefully
        XCTAssertEqual(viewModel.numberOfSections(), 0)
        XCTAssertTrue(viewModel.getDays().isEmpty)
    }
    
    func testCreateTimelineWithBookedActivities() {
        // Given: Timeline with booked activities
        viewModel.selectDay(at: 2) // Day 3 has booked activities
        
        // When: Getting booked activities
        let bookedActivities = viewModel.getBookedActivitiesForSelectedDay()
        
        // Then: Should have booked activities
        XCTAssertTrue(bookedActivities.count > 0)
        XCTAssertTrue(bookedActivities.contains(where: { $0.segmentType == .bookedActivity }))
    }
    
    // MARK: - Getting Tests
    
    func testGetNumberOfSections() {
        // When: Getting number of sections
        viewModel.selectDay(at: 0)
        let sections = viewModel.numberOfSections()
        
        // Then: Should return valid number
        XCTAssertTrue(sections >= 0)
    }
    
    func testGetDaysFromTimeline() {
        // When: Getting days
        let days = viewModel.getDays()
        
        // Then: Should return 6 days
        XCTAssertEqual(days.count, 6)
        for day in days {
            XCTAssertFalse(day.isEmpty)
            XCTAssertTrue(day.contains("/"))
        }
    }
    
    func testGetTripDateRange() {
        // When: Getting date range
        let dateRange = viewModel.getTripDateRange()
        
        // Then: Should return valid dates
        XCTAssertNotNil(dateRange)
        if let range = dateRange {
            XCTAssertTrue(range.start <= range.end)
        }
    }
    
    func testGetPOIsForSelectedDay() {
        // When: Getting POIs for day 0
        viewModel.selectDay(at: 0)
        let pois = viewModel.getPoisForSelectedDay()
        
        // Then: Should return POIs
        XCTAssertTrue(pois.count > 0)
        for poi in pois {
            XCTAssertFalse(poi.id.isEmpty)
            XCTAssertFalse(poi.name.isEmpty)
        }
    }
    
    func testGetPOIById() {
        // Given: Day 0 selected
        viewModel.selectDay(at: 0)
        
        // When: Getting Casa Batlló by ID
        let poi = viewModel.getPoi(byId: "540484")
        
        // Then: Should return the POI
        XCTAssertNotNil(poi)
        XCTAssertEqual(poi?.name, "Casa Batlló")
    }
    
    func testGetBookedActivityById() {
        // Given: Day 3 with booked activity
        viewModel.selectDay(at: 2)
        
        // When: Getting cooking class
        let activity = viewModel.getBookedActivity(byId: "COOK-BCN-001")
        
        // Then: Should return the activity
        XCTAssertNotNil(activity)
        XCTAssertEqual(activity?.additionalData?.activityId, "COOK-BCN-001")
        XCTAssertEqual(activity?.title, "Paella Cooking Class")
    }
    
    func testGetFirstPlan() {
        // When: Getting first plan
        let firstPlan = viewModel.getFirstPlan()
        
        // Then: Should return Day 1 plan
        XCTAssertNotNil(firstPlan)
        XCTAssertEqual(firstPlan?.id, "25459")
        XCTAssertEqual(firstPlan?.name, "Day 1: Gaudí & Modernism")
    }
    
    func testGetHeaderDataForSection() {
        // Given: Day 0 selected
        viewModel.selectDay(at: 0)
        
        // When: Getting header data
        let sections = viewModel.numberOfSections()
        if sections > 0 {
            let headerData = viewModel.headerData(for: 0)
            
            // Then: Should return valid header data
            XCTAssertFalse(headerData.cityName.isEmpty)
            XCTAssertTrue(headerData.isFirstSection)
            XCTAssertTrue(headerData.shouldShowHeader)
        }
    }
    
    // MARK: - Editing Tests
    
    func testUpdateTimelineWithNewData() {
        // Given: Initial sections count
        let initialSections = viewModel.numberOfSections()
        
        // When: Updating with empty timeline
        let city = TRPCity(id: 109, name: "Barcelona", coordinate: TRPLocation(lat: 41.3850639, lon: 2.1734034999999494))
        let newTimeline = TRPTimeline(id: 2, tripHash: "new", tripProfile: nil, city: city, plans: [], segments: nil)
        viewModel.updateTimeline(newTimeline)
        
        // Then: Sections should be updated
        let newSections = viewModel.numberOfSections()
        XCTAssertEqual(newSections, 0)
        XCTAssertNotEqual(newSections, initialSections)
    }
    
    func testSelectDifferentDay() {
        // When: Selecting day 0
        viewModel.selectDay(at: 0)
        let day0Sections = viewModel.numberOfSections()
        
        // When: Changing to day 2
        viewModel.selectDay(at: 2)
        let day2Sections = viewModel.numberOfSections()
        
        // Then: Selected day should be updated
        XCTAssertEqual(viewModel.selectedDayIndex, 2)
        XCTAssertTrue(day0Sections >= 0)
        XCTAssertTrue(day2Sections >= 0)
    }
    
    func testDayFilteringWithBookedActivities() {
        // When: Selecting day 2 (has cooking class)
        viewModel.selectDay(at: 2)
        
        // Then: Should include booked activity
        let bookedActivities = viewModel.getBookedActivitiesForSelectedDay()
        XCTAssertTrue(bookedActivities.contains(where: {
            $0.additionalData?.activityId == "COOK-BCN-001"
        }))
    }
    
    func testHandleInvalidSectionIndex() {
        // When: Requesting rows for invalid section
        let rows = viewModel.numberOfRows(in: 999)
        
        // Then: Should return 0
        XCTAssertEqual(rows, 0)
    }
    
    func testHandleInvalidIndexPath() {
        // When: Requesting cell type for invalid index path
        let invalidIndexPath = IndexPath(row: 999, section: 999)
        let cellType = viewModel.cellType(at: invalidIndexPath)
        
        // Then: Should return nil
        XCTAssertNil(cellType)
    }
    
    func testEmptyPlanHandling() {
        // When: Selecting last day (empty plan)
        viewModel.selectDay(at: 5)
        
        // Then: Should have no segments
        let sections = viewModel.numberOfSections()
        XCTAssertEqual(sections, 0)
    }
}



