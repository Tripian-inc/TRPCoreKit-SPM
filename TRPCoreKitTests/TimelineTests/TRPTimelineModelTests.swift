//
//  TRPTimelineModelTests.swift
//  TRPCoreKitTests
//
//  Created by Unit Tests Generator on 04.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Testing
import Foundation
@testable import TRPCoreKit
import TRPFoundationKit

/// Test suite for Timeline models (TRPTimeline, TRPTimelinePlan, TRPTimelineStep)
@Suite("Timeline Model Tests")
struct TRPTimelineModelTests {
    
    // MARK: - TRPTimeline Tests
    
    @Test("Timeline creation with valid data")
    func testTimelineCreationWithValidData() {
        // Given: Timeline data
        let timeline = TRPTimelineMockData.getMockTimeline()
        
        // Then: Timeline should be properly initialized
        #expect(timeline.id == 7586)
        #expect(timeline.tripHash == "7cbeea9f5ddc40cd807b15d8778736f6")
        #expect(timeline.city.name == "Barcelona")
        #expect(timeline.plans != nil)
        #expect(timeline.segments != nil)
    }
    
    @Test("Get all POIs from timeline")
    func testGetAllPOIsFromTimeline() {
        // Given: A timeline with multiple plans
        let timeline = TRPTimelineMockData.getMockTimeline()
        
        // When: Getting all POIs
        let pois = timeline.getPois()
        
        // Then: Should return all unique POIs
        #expect(pois.count > 0)
        
        // Verify uniqueness
        let uniqueIds = Set(pois.map { $0.id })
        #expect(uniqueIds.count == pois.count)
        
        // All POIs should have valid data
        for poi in pois {
            #expect(!poi.id.isEmpty)
            #expect(!poi.name.isEmpty)
            #expect(poi.cityId == 109)
        }
    }
    
    @Test("Get POIs by category")
    func testGetPOIsByCategory() {
        // Given: A timeline
        let timeline = TRPTimelineMockData.getMockTimeline()
        
        // When: Getting POIs for Attractions (category ID 1)
        let attractions = timeline.getPoisWith(types: [1])
        
        // Then: Should return only attractions
        #expect(attractions.count > 0)
        for poi in attractions {
            #expect(poi.categories.contains(where: { $0.id == 1 }))
        }
        
        // When: Getting POIs for Restaurants (category ID 3)
        let restaurants = timeline.getPoisWith(types: [3])
        
        // Then: Should return only restaurants
        #expect(restaurants.count > 0)
        for poi in restaurants {
            #expect(poi.categories.contains(where: { $0.id == 3 }))
        }
    }
    
    @Test("Get POIs by multiple categories")
    func testGetPOIsByMultipleCategories() {
        // Given: A timeline
        let timeline = TRPTimelineMockData.getMockTimeline()
        
        // When: Getting POIs for both Attractions and Restaurants
        let pois = timeline.getPoisWith(types: [1, 3])
        
        // Then: Should return POIs matching either category
        #expect(pois.count > 0)
        for poi in pois {
            let hasMatchingCategory = poi.categories.contains(where: { cat in
                cat.id == 1 || cat.id == 3
            })
            #expect(hasMatchingCategory)
        }
    }
    
    @Test("Get part of day for POI")
    func testGetPartOfDayForPOI() {
        // Given: A timeline
        let timeline = TRPTimelineMockData.getMockTimeline()
        
        // When: Getting which days a POI appears on (Casa Batlló)
        let days = timeline.getPartOfDay(placeId: "540484")
        
        // Then: Should return array of day numbers
        if let days = days {
            #expect(days.count > 0)
            for day in days {
                #expect(day >= 1)
                #expect(day <= 6) // 6 days in mock data
            }
        }
    }
    
    @Test("Get POI score from timeline")
    func testGetPOIScoreFromTimeline() {
        // Given: A timeline
        let timeline = TRPTimelineMockData.getMockTimeline()
        
        // When: Getting score for Casa Batlló
        let score = timeline.getPoiScore(poiId: "540484")
        
        // Then: Should return a valid score
        if let score = score {
            #expect(score >= 0)
            #expect(score <= 100)
        }
    }
    
    @Test("Get step score from timeline")
    func testGetStepScoreFromTimeline() {
        // Given: A timeline
        let timeline = TRPTimelineMockData.getMockTimeline()
        
        // When: Getting score for a step
        let score = timeline.getStepScore(stepId: 126393)
        
        // Then: Should return a valid score
        if let score = score {
            #expect(score >= 0)
            #expect(score <= 100)
        }
    }
    
    @Test("Check if plan is first plan")
    func testIsFirstPlan() {
        // Given: A timeline
        let timeline = TRPTimelineMockData.getMockTimeline()
        
        // When: Checking if plan is first
        let isFirst = timeline.isFirstPlan(planId: "25459")
        
        // Then: Should return true for first plan
        #expect(isFirst == true)
        
        // When: Checking a non-first plan
        let isNotFirst = timeline.isFirstPlan(planId: "25460")
        
        // Then: Should return false
        #expect(isNotFirst == false)
    }
    
    @Test("Check if plan is last plan")
    func testIsLastPlan() {
        // Given: A timeline
        let timeline = TRPTimelineMockData.getMockTimeline()
        
        // When: Checking if plan is last (Day 6 empty plan)
        let isLast = timeline.isLastPlan(planId: "25464")
        
        // Then: Should return true for last plan
        #expect(isLast == true)
        
        // When: Checking a non-last plan
        let isNotLast = timeline.isLastPlan(planId: "25459")
        
        // Then: Should return false
        #expect(isNotLast == false)
    }
    
    // MARK: - TRPTimelinePlan Tests
    
    @Test("Timeline plan creation")
    func testTimelinePlanCreation() {
        // Given: Mock timeline
        let timeline = TRPTimelineMockData.getMockTimeline()
        
        // When: Getting first plan
        guard let plan = timeline.plans?.first else {
            #expect(false, "Plan should exist")
            return
        }
        
        // Then: Plan should have valid data
        #expect(plan.id == "25459")
        #expect(plan.name == "Day 1: Gaudí & Modernism")
        #expect(plan.steps.count > 0)
        #expect(plan.city != nil)
        #expect(plan.adults == 1)
        #expect(plan.children == 0)
        #expect(plan.pets == 0)
    }
    
    @Test("Get POIs from plan")
    func testGetPOIsFromPlan() {
        // Given: A plan with steps
        let timeline = TRPTimelineMockData.getMockTimeline()
        guard let plan = timeline.plans?.first else {
            #expect(false, "Plan should exist")
            return
        }
        
        // When: Getting POIs from plan
        let pois = plan.getPoi()
        
        // Then: Should return all POIs from steps
        #expect(pois.count == plan.steps.count)
        for poi in pois {
            #expect(!poi.id.isEmpty)
        }
    }
    
    @Test("Get start date from plan")
    func testGetStartDateFromPlan() {
        // Given: A plan
        let timeline = TRPTimelineMockData.getMockTimeline()
        guard let plan = timeline.plans?.first else {
            #expect(false, "Plan should exist")
            return
        }
        
        // When: Getting start date
        let startDate = plan.getStartDate()
        
        // Then: Should return valid date
        #expect(startDate.timeIntervalSince1970 > 0)
    }
    
    @Test("Get end date from plan")
    func testGetEndDateFromPlan() {
        // Given: A plan
        let timeline = TRPTimelineMockData.getMockTimeline()
        guard let plan = timeline.plans?.first else {
            #expect(false, "Plan should exist")
            return
        }
        
        // When: Getting end date
        let endDate = plan.getEndDate()
        
        // Then: Should return valid date after start date
        let startDate = plan.getStartDate()
        #expect(endDate >= startDate)
    }
    
    @Test("Plan equality")
    func testPlanEquality() {
        // Given: Two plans
        let timeline = TRPTimelineMockData.getMockTimeline()
        guard let plan1 = timeline.plans?.first,
              let plan2 = timeline.plans?.last else {
            #expect(false, "Plans should exist")
            return
        }
        
        // When: Comparing plans
        let areSame = plan1 == plan1
        let areDifferent = plan1 == plan2
        
        // Then: Same plan should equal itself
        #expect(areSame == true)
        // Different plans should not equal
        #expect(areDifferent == false)
    }
    
    @Test("Empty plan handling")
    func testEmptyPlanHandling() {
        // Given: Timeline with empty plan (Day 6)
        let timeline = TRPTimelineMockData.getMockTimeline()
        guard let emptyPlan = timeline.plans?.first(where: { $0.id == "25464" }) else {
            #expect(false, "Empty plan should exist")
            return
        }
        
        // Then: Empty plan should have no steps
        #expect(emptyPlan.steps.isEmpty)
        #expect(emptyPlan.name == "Day 6: Open Day")
    }
    
    // MARK: - TRPTimelineStep Tests
    
    @Test("Timeline step creation")
    func testTimelineStepCreation() {
        // Given: A timeline with steps
        let timeline = TRPTimelineMockData.getMockTimeline()
        guard let plan = timeline.plans?.first,
              let step = plan.steps.first else {
            #expect(false, "Step should exist")
            return
        }
        
        // Then: Step should have valid data
        #expect(step.id > 0)
        #expect(step.poi != nil)
        #expect(step.score != nil)
        #expect(step.order >= 0)
        #expect(step.startDateTimes != nil)
        #expect(step.endDateTimes != nil)
    }
    
    @Test("Step equality")
    func testStepEquality() {
        // Given: Steps
        let timeline = TRPTimelineMockData.getMockTimeline()
        guard let plan = timeline.plans?.first,
              plan.steps.count >= 2 else {
            #expect(false, "Steps should exist")
            return
        }
        
        let step1 = plan.steps[0]
        let step2 = plan.steps[1]
        
        // When: Comparing steps
        let areSame = step1 == step1
        let areDifferent = step1 == step2
        
        // Then: Same step should equal itself
        #expect(areSame == true)
        // Different steps should not equal
        #expect(areDifferent == false)
    }
    
    @Test("Get start time from step")
    func testGetStartTimeFromStep() {
        // Given: A step with time
        let timeline = TRPTimelineMockData.getMockTimeline()
        guard let plan = timeline.plans?.first,
              let step = plan.steps.first else {
            #expect(false, "Step should exist")
            return
        }
        
        // When: Getting start time
        let startTime = step.getStartTime()
        
        // Then: Should return formatted time (HH:mm)
        if let startTime = startTime {
            #expect(!startTime.isEmpty)
            #expect(startTime.contains(":"))
            // Should be in format "HH:mm"
            let components = startTime.split(separator: ":")
            #expect(components.count == 2)
        }
    }
    
    @Test("Get end time from step")
    func testGetEndTimeFromStep() {
        // Given: A step with time
        let timeline = TRPTimelineMockData.getMockTimeline()
        guard let plan = timeline.plans?.first,
              let step = plan.steps.first else {
            #expect(false, "Step should exist")
            return
        }
        
        // When: Getting end time
        let endTime = step.getEndTime()
        
        // Then: Should return formatted time (HH:mm)
        if let endTime = endTime {
            #expect(!endTime.isEmpty)
            #expect(endTime.contains(":"))
            // Should be in format "HH:mm"
            let components = endTime.split(separator: ":")
            #expect(components.count == 2)
        }
    }
    
    @Test("Step with POI data")
    func testStepWithPOIData() {
        // Given: A step with POI
        let timeline = TRPTimelineMockData.getMockTimeline()
        guard let plan = timeline.plans?.first,
              let step = plan.steps.first,
              let poi = step.poi else {
            #expect(false, "Step with POI should exist")
            return
        }
        
        // Then: POI should have complete data
        #expect(!poi.id.isEmpty)
        #expect(!poi.name.isEmpty)
        #expect(poi.cityId == 109)
        #expect(poi.coordinate.lat != 0)
        #expect(poi.coordinate.lon != 0)
        #expect(poi.categories.count > 0)
    }
    
    @Test("Step score validation")
    func testStepScoreValidation() {
        // Given: Steps with scores
        let timeline = TRPTimelineMockData.getMockTimeline()
        guard let plan = timeline.plans?.first else {
            #expect(false, "Plan should exist")
            return
        }
        
        // When: Checking step scores
        for step in plan.steps {
            if let score = step.score {
                // Then: Score should be in valid range
                #expect(score >= 0)
                #expect(score <= 100)
            }
        }
    }
    
    // MARK: - TRPTimelineSegment Tests
    
    @Test("Booked activity segment creation")
    func testBookedActivitySegmentCreation() {
        // Given: Timeline with booked activities
        let timeline = TRPTimelineMockData.getMockTimeline()
        
        // When: Finding booked activity segments
        let bookedSegments = timeline.segments?.filter { $0.segmentType == .bookedActivity }
        
        // Then: Should have booked activities
        #expect(bookedSegments != nil)
        #expect(bookedSegments!.count > 0)
        
        for segment in bookedSegments! {
            #expect(segment.segmentType == .bookedActivity)
            #expect(segment.additionalData != nil)
            #expect(!segment.additionalData!.activityId.isEmpty)
        }
    }
    
    @Test("Itinerary segment creation")
    func testItinerarySegmentCreation() {
        // Given: Timeline
        let timeline = TRPTimelineMockData.getMockTimeline()
        
        // When: Checking for itinerary segments in plans
        // Note: Plans are converted to itinerary segments by view model
        guard let plans = timeline.plans else {
            #expect(false, "Plans should exist")
            return
        }
        
        // Then: Plans should exist and can be used as itinerary segments
        #expect(plans.count > 0)
        for plan in plans {
            #expect(!plan.id.isEmpty)
            #expect(plan.city != nil)
        }
    }
    
    @Test("Segment additional data")
    func testSegmentAdditionalData() {
        // Given: Booked activity segment with additional data
        let timeline = TRPTimelineMockData.getMockTimeline()
        let cookingClass = timeline.segments?.first(where: { 
            $0.additionalData?.activityId == "COOK-BCN-001" 
        })
        
        guard let segment = cookingClass,
              let additionalData = segment.additionalData else {
            #expect(false, "Cooking class segment should exist")
            return
        }
        
        // Then: Additional data should be complete
        #expect(additionalData.activityId == "COOK-BCN-001")
        #expect(additionalData.bookingId == "BOOKING-12345-BCN")
        #expect(!additionalData.title.isEmpty)
        #expect(!additionalData.description.isEmpty)
        #expect(!additionalData.startDatetime.isEmpty)
        #expect(!additionalData.endDatetime.isEmpty)
        #expect(additionalData.coordinate != nil)
        #expect(additionalData.adultCount > 0)
    }
    
    @Test("Segment with different end location")
    func testSegmentWithDifferentEndLocation() {
        // Given: Madrid trip segment with different end location
        let timeline = TRPTimelineMockData.getMockTimeline()
        let madridTrip = timeline.segments?.first(where: { 
            $0.additionalData?.activityId == "TRAIN-MAD-001" 
        })
        
        guard let segment = madridTrip else {
            #expect(false, "Madrid trip segment should exist")
            return
        }
        
        // Then: Should have different end location marked
        #expect(segment.differentEndLocation == true)
        #expect(segment.city?.name == "Madrid")
        #expect(segment.destinationCoordinate != nil)
    }
    
    @Test("Segment initialization from plan")
    func testSegmentInitializationFromPlan() {
        // Given: A plan
        let timeline = TRPTimelineMockData.getMockTimeline()
        guard let plan = timeline.plans?.first else {
            #expect(false, "Plan should exist")
            return
        }
        
        // When: Creating segment from plan
        let segment = TRPTimelineSegment(from: plan)
        
        // Then: Segment should copy plan data
        #expect(segment.title == plan.name)
        #expect(segment.description == plan.description)
        #expect(segment.startDate == plan.startDate)
        #expect(segment.endDate == plan.endDate)
        #expect(segment.adults == plan.adults)
        #expect(segment.children == plan.children)
        #expect(segment.pets == plan.pets)
        #expect(segment.city?.id == plan.city?.id)
    }
}

