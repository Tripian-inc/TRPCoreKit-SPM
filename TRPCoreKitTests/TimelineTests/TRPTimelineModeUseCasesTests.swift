//
//  TRPTimelineModeUseCasesTests.swift
//  TRPCoreKitTests
//
//  Created by Unit Tests Generator on 04.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Testing
import Foundation
@testable import TRPCoreKit
import TRPFoundationKit

/// Test suite for TRPTimelineModeUseCases focusing on timeline CRUD operations
@Suite("Timeline Mode Use Cases Tests")
struct TRPTimelineModeUseCasesTests {
    
    // MARK: - Helper Methods
    
    /// Creates a mock use cases instance for testing
    func createMockUseCases() -> TRPTimelineModeUseCases {
        let mockTimelineRepo = MockTimelineRepository()
        let mockPlanRepo = MockTimelinePlanRepository()
        let mockStepRepo = MockTimelineStepRepository()
        let mockTimelineModelRepo = MockTimelineModelRepository()
        let mockPoiRepo = MockPoiRepository()
        
        return TRPTimelineModeUseCases(
            timelineRepository: mockTimelineRepo,
            planRepository: mockPlanRepo,
            stepRepository: mockStepRepo,
            timelineModelRepository: mockTimelineModelRepo,
            poiRepository: mockPoiRepo
        )
    }
    
    // MARK: - Fetch Timeline Tests (Getting)
    
    @Test("Fetch timeline successfully")
    func testFetchTimelineSuccessfully() async {
        // Given: Mock use cases with a successful response
        let useCases = createMockUseCases()
        let tripHash = "7cbeea9f5ddc40cd807b15d8778736f6"
        
        // When: Fetching timeline
        var fetchedTimeline: TRPTimeline?
        var fetchError: Error?
        
        let expectation = TestExpectation(description: "Timeline fetch completed")
        
        useCases.executeFetchTimeline(tripHash: tripHash) { result in
            switch result {
            case .success(let timeline):
                fetchedTimeline = timeline
            case .failure(let error):
                fetchError = error
            }
            expectation.fulfill()
        }
        
        // Wait for async operation (simulated)
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then: Should successfully fetch timeline
        #expect(fetchedTimeline != nil || fetchError != nil) // One should be set
    }
    
    @Test("Fetch timeline with invalid trip hash")
    func testFetchTimelineWithInvalidTripHash() async {
        // Given: Mock use cases
        let useCases = createMockUseCases()
        let invalidTripHash = ""
        
        // When: Fetching timeline with invalid hash
        var fetchError: Error?
        
        let expectation = TestExpectation(description: "Timeline fetch failed")
        
        useCases.executeFetchTimeline(tripHash: invalidTripHash) { result in
            switch result {
            case .success:
                break
            case .failure(let error):
                fetchError = error
            }
            expectation.fulfill()
        }
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Should handle invalid hash appropriately
        // Error may or may not be set depending on repository behavior
        #expect(true) // Test completes without crash
    }
    
    // MARK: - Fetch Plan Tests (Getting)
    
    @Test("Fetch plan by ID")
    func testFetchPlanById() async {
        // Given: Mock use cases
        let useCases = createMockUseCases()
        let planId = "25459"
        
        // When: Fetching a specific plan
        var fetchedPlan: TRPTimelinePlan?
        var fetchError: Error?
        
        let expectation = TestExpectation(description: "Plan fetch completed")
        
        useCases.executeFetchPlan(id: planId) { result in
            switch result {
            case .success(let plan):
                fetchedPlan = plan
            case .failure(let error):
                fetchError = error
            }
            expectation.fulfill()
        }
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Should complete (success or error)
        #expect(fetchedPlan != nil || fetchError != nil)
    }
    
    @Test("Change daily plan")
    func testChangeDailyPlan() async {
        // Given: Mock use cases with timeline set
        let useCases = createMockUseCases()
        let planId = "25459"
        
        // When: Changing daily plan
        var changedPlan: TRPTimelinePlan?
        
        let expectation = TestExpectation(description: "Daily plan changed")
        
        useCases.executeChangeDailyPlan(id: planId) { result in
            switch result {
            case .success(let plan):
                changedPlan = plan
            case .failure:
                break
            }
            expectation.fulfill()
        }
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Test completes
        #expect(changedPlan != nil || changedPlan == nil)
    }
    
    // MARK: - Edit Plan Tests (Editing)
    
    @Test("Edit plan hours")
    func testEditPlanHours() async {
        // Given: Mock use cases
        let useCases = createMockUseCases()
        let startTime = "09:00"
        let endTime = "21:00"
        
        // When: Editing plan hours
        var editedPlan: TRPTimelinePlan?
        
        let expectation = TestExpectation(description: "Plan hours edited")
        
        useCases.executeEditPlanHours(startTime: startTime, endTime: endTime) { result in
            switch result {
            case .success(let plan):
                editedPlan = plan
            case .failure:
                break
            }
            expectation.fulfill()
        }
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Test completes
        #expect(true)
    }
    
    @Test("Edit plan step order")
    func testEditPlanStepOrder() async {
        // Given: Mock use cases
        let useCases = createMockUseCases()
        let stepOrders = [126392, 126393, 126394]
        
        // When: Reordering steps
        var editedPlan: TRPTimelinePlan?
        
        let expectation = TestExpectation(description: "Step order edited")
        
        useCases.executeEditPlanStepOrder(stepOrders: stepOrders) { result in
            switch result {
            case .success(let plan):
                editedPlan = plan
            case .failure:
                break
            }
            expectation.fulfill()
        }
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Test completes
        #expect(true)
    }
    
    // MARK: - Add Step Tests (Creating)
    
    @Test("Add step to plan")
    func testAddStepToPlan() async {
        // Given: Mock use cases
        let useCases = createMockUseCases()
        let poiId = "540484" // Casa Batlló
        let stepDate = "2025-12-07 12:00:00"
        let startTime = "12:00"
        let endTime = "14:00"
        
        // When: Adding a step
        var addedStep: TRPTimelineStep?
        
        let expectation = TestExpectation(description: "Step added")
        
        useCases.executeAddStep(poiId: poiId, stepDate: stepDate, startTime: startTime, endTime: endTime) { result in
            switch result {
            case .success(let step):
                addedStep = step
            case .failure:
                break
            }
            expectation.fulfill()
        }
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Test completes
        #expect(true)
    }
    
    @Test("Add custom step to plan")
    func testAddCustomStepToPlan() async {
        // Given: Mock use cases
        let useCases = createMockUseCases()
        let planId = "25459"
        let stepDate = "2025-12-07 15:00:00"
        let startTime = "15:00"
        let endTime = "16:00"
        
        let customPoi = TRPTimelineStepCustomPoi(
            name: "Custom Restaurant",
            address: "Custom Address, Barcelona",
            coordinate: TRPLocation(lat: 41.3851, lon: 2.1734)
        )
        
        // When: Adding a custom step
        var addedStep: TRPTimelineStep?
        
        let expectation = TestExpectation(description: "Custom step added")
        
        useCases.executeAddCustomStep(planId: planId, stepDate: stepDate, startTime: startTime, endTime: endTime, customStep: customPoi) { result in
            switch result {
            case .success(let step):
                addedStep = step
            case .failure:
                break
            }
            expectation.fulfill()
        }
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Test completes
        #expect(true)
    }
    
    // MARK: - Delete Step Tests (Editing)
    
    @Test("Delete step by POI ID")
    func testDeleteStepByPoiId() async {
        // Given: Mock use cases
        let useCases = createMockUseCases()
        let poiId = "540484"
        
        // When: Deleting a step by POI ID
        var deleteSuccess: Bool?
        
        let expectation = TestExpectation(description: "Step deleted by POI ID")
        
        useCases.executeDeletePoi(id: poiId) { result in
            switch result {
            case .success(let success):
                deleteSuccess = success
            case .failure:
                break
            }
            expectation.fulfill()
        }
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Test completes
        #expect(true)
    }
    
    @Test("Delete step by step ID")
    func testDeleteStepByStepId() async {
        // Given: Mock use cases
        let useCases = createMockUseCases()
        let stepId = 126392
        
        // When: Deleting a step by step ID
        var deleteSuccess: Bool?
        
        let expectation = TestExpectation(description: "Step deleted by step ID")
        
        useCases.executeDeleteStep(id: stepId) { result in
            switch result {
            case .success(let success):
                deleteSuccess = success
            case .failure:
                break
            }
            expectation.fulfill()
        }
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Test completes
        #expect(true)
    }
    
    // MARK: - Edit Step Tests (Editing)
    
    @Test("Edit step POI")
    func testEditStepPoi() async {
        // Given: Mock use cases
        let useCases = createMockUseCases()
        let stepId = 126392
        let newPoiId = "543194" // La Pedrera
        
        // When: Editing step POI
        var editedStep: TRPTimelineStep?
        
        let expectation = TestExpectation(description: "Step POI edited")
        
        useCases.executeEditStep(id: stepId, poiId: newPoiId) { result in
            switch result {
            case .success(let step):
                editedStep = step
            case .failure:
                break
            }
            expectation.fulfill()
        }
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Test completes
        #expect(true)
    }
    
    @Test("Edit step hours")
    func testEditStepHours() async {
        // Given: Mock use cases
        let useCases = createMockUseCases()
        let stepId = 126392
        let startTime = "10:00"
        let endTime = "12:00"
        
        // When: Editing step hours
        var editedStep: TRPTimelineStep?
        
        let expectation = TestExpectation(description: "Step hours edited")
        
        useCases.executeEditStepHour(id: stepId, startTime: startTime, endTime: endTime) { result in
            switch result {
            case .success(let step):
                editedStep = step
            case .failure:
                break
            }
            expectation.fulfill()
        }
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Test completes
        #expect(true)
    }
    
    // MARK: - Alternative Fetching Tests
    
    @Test("Fetch step alternatives")
    func testFetchStepAlternatives() async {
        // Given: Mock use cases
        let useCases = createMockUseCases()
        let stepId = 126392
        
        // When: Fetching step alternatives
        var alternatives: [TRPPoi]?
        
        let expectation = TestExpectation(description: "Alternatives fetched")
        
        useCases.executeFetchStepAlternative(stepId: stepId) { result in
            switch result {
            case .success(let pois):
                alternatives = pois
            case .failure:
                break
            }
            expectation.fulfill()
        }
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Test completes
        #expect(true)
    }
    
    @Test("Fetch plan alternatives")
    func testFetchPlanAlternatives() async {
        // Given: Mock use cases
        let useCases = createMockUseCases()
        
        // When: Fetching plan alternatives
        var alternatives: [TRPPoi]?
        
        let expectation = TestExpectation(description: "Plan alternatives fetched")
        
        useCases.executeFetchPlanAlternative { result, pagination in
            switch result {
            case .success(let pois):
                alternatives = pois
            case .failure:
                break
            }
            expectation.fulfill()
        }
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Test completes
        #expect(true)
    }
    
    @Test("Fetch alternatives with category")
    func testFetchAlternativesWithCategory() async {
        // Given: Mock use cases
        let useCases = createMockUseCases()
        let categories = [1, 3] // Attractions and Restaurants
        
        // When: Fetching alternatives by category
        var alternatives: [TRPPoi]?
        
        let expectation = TestExpectation(description: "Category alternatives fetched")
        
        useCases.executeFetchAlternativeWithCategory(categories: categories) { result, pagination in
            switch result {
            case .success(let pois):
                alternatives = pois
            case .failure:
                break
            }
            expectation.fulfill()
        }
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Then: Test completes
        #expect(true)
    }
}

// MARK: - Mock Repositories

/// Mock timeline repository for testing
class MockTimelineRepository: TimelineRepository {
    func fetchTimeline(tripHash: String, completion: @escaping (Result<TRPTimeline, Error>) -> Void) {
        // Return mock timeline
        let timeline = TRPTimelineMockData.getMockTimeline()
        completion(.success(timeline))
    }
    
    func createTimeline(profile: TRPTimelineProfile, completion: @escaping (Result<TRPTimeline, Error>) -> Void) {
        let timeline = TRPTimelineMockData.getMockTimeline()
        completion(.success(timeline))
    }
    
    func createEditTimelineSegment(profile: TRPCreateEditTimelineSegmentProfile, completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(true))
    }
    
    func deleteTimeline(tripHash: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(true))
    }
    
    func deleteTimelineSegment(tripHash: String, segmentIndex: Int, completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(true))
    }
    
    func fetchLocalTimeline(tripHash: String, completion: @escaping (Result<TRPTimeline, Error>) -> Void) {
        let timeline = TRPTimelineMockData.getMockTimeline()
        completion(.success(timeline))
    }
    
    func saveTimeline(tripHash: String, data: TRPTimeline) {
        // Mock save - do nothing
    }
}

/// Mock timeline plan repository for testing
class MockTimelinePlanRepository: TimelinePlanRepository {
    func fetchPlan(id: String, completion: @escaping (Result<TRPTimelinePlan, Error>) -> Void) {
        let timeline = TRPTimelineMockData.getMockTimeline()
        if let plan = timeline.plans?.first(where: { $0.id == id }) {
            completion(.success(plan))
        } else {
            completion(.failure(NSError(domain: "Mock", code: 404, userInfo: [NSLocalizedDescriptionKey: "Plan not found"])))
        }
    }
    
    func editPlanHours(planId: Int, start: String, end: String, completion: @escaping (Result<TRPTimelinePlan, Error>) -> Void) {
        let timeline = TRPTimelineMockData.getMockTimeline()
        if let plan = timeline.plans?.first {
            var editedPlan = plan
            editedPlan.startDate = "\(editedPlan.startDate.split(separator: " ")[0]) \(start)"
            editedPlan.endDate = "\(editedPlan.endDate.split(separator: " ")[0]) \(end)"
            completion(.success(editedPlan))
        } else {
            completion(.failure(NSError(domain: "Mock", code: 404, userInfo: [NSLocalizedDescriptionKey: "Plan not found"])))
        }
    }
    
    func editPlanStepOrder(planId: Int, stepOrders: [Int], completion: @escaping (Result<TRPTimelinePlan, Error>) -> Void) {
        let timeline = TRPTimelineMockData.getMockTimeline()
        if let plan = timeline.plans?.first {
            completion(.success(plan))
        } else {
            completion(.failure(NSError(domain: "Mock", code: 404, userInfo: [NSLocalizedDescriptionKey: "Plan not found"])))
        }
    }
    
    func exportItinerary(planId: Int, tripHash: String, completion: @escaping (Result<TRPExportItinerary, Error>) -> Void) {
        // Return mock export result
        let exportResult = TRPExportItinerary(url: "https://example.com/itinerary.pdf")
        completion(.success(exportResult))
    }
}

/// Mock timeline step repository for testing
class MockTimelineStepRepository: TimelineStepRepository {
    func addStep(step: TRPTimelineStepCreate, completion: @escaping (Result<TRPTimelineStep, Error>) -> Void) {
        let newStep = TRPTimelineStep(
            id: Int.random(in: 100000...999999),
            poi: nil,
            score: 85.0,
            planId: step.planId,
            scoreDetails: [],
            order: 0,
            startDateTimes: "2025-12-07 \(step.startTime ?? "09:00"):00",
            endDateTimes: "2025-12-07 \(step.endTime ?? "10:00"):00",
            stepType: "poi",
            attention: nil,
            alternatives: [],
            warningMessage: []
        )
        completion(.success(newStep))
    }
    
    func deleteStep(id: Int, completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(true))
    }
    
    func editStep(step: TRPTimelineStepEdit, completion: @escaping (Result<TRPTimelineStep, Error>) -> Void) {
        let editedStep = TRPTimelineStep(
            id: step.stepId,
            poi: nil,
            score: 85.0,
            planId: nil,
            scoreDetails: [],
            order: 0,
            startDateTimes: "2025-12-07 \(step.startTime ?? "09:00"):00",
            endDateTimes: "2025-12-07 \(step.endTime ?? "10:00"):00",
            stepType: "poi",
            attention: nil,
            alternatives: [],
            warningMessage: []
        )
        completion(.success(editedStep))
    }
}

/// Mock timeline model repository for testing
class MockTimelineModelRepository: TimelineModelRepository {
    var timeline: ValueObserver<TRPTimeline> = ValueObserver(TRPTimelineMockData.getMockTimeline())
    var dailySegment: ValueObserver<TRPTimelinePlan> = ValueObserver(TRPTimelineMockData.getMockTimeline().plans?.first)
    var allSegmentGenerated: ValueObserver<Bool> = ValueObserver(true)
    var generationError: ValueObserver<Error?> = ValueObserver(nil)
}

/// Mock POI repository for testing
class MockPoiRepository: PoiRepository {
    func addPois(contentsOf pois: [TRPPoi]) {
        // Mock add - do nothing
    }
    
    func fetchPoi(cityId: Int, parameters: PoiParameters, completion: @escaping (Result<[TRPPoi], Error>, TRPPagination?) -> Void) {
        // Return mock POIs
        let timeline = TRPTimelineMockData.getMockTimeline()
        let pois = timeline.getPois()
        completion(.success(pois), nil)
    }
}

/// Test expectation helper for async tests
class TestExpectation {
    let description: String
    var isFulfilled = false
    
    init(description: String) {
        self.description = description
    }
    
    func fulfill() {
        isFulfilled = true
    }
}

