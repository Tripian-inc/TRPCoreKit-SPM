//
//  TRPTimelineMockData.swift
//  TRPCoreKit
//
//  Created by Mock Data Generator on 02.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

public class TRPTimelineMockData {
    
    public static func getMockTimeline() -> TRPTimeline {
        // Create mock city
        let city = createBarcelonaCity()
        
        // Create 6-day plan with multiple daily plans (extends to next month)
        let plans = create5DayPlans(city: city)
        
        // Create timeline
        var timeline = TRPTimeline(
            id: 7586,
            tripHash: "7cbeea9f5ddc40cd807b15d8778736f6",
            tripProfile: createMockTripProfile(),
            city: city,
            plans: plans
        )
        
        // Add segments with booked activities
        timeline.segments = createTimelineSegments(city: city)
        
        return timeline
    }
    
    // MARK: - Helper Methods
    
    private static func createBarcelonaCity() -> TRPCity {
        return TRPCity(
            id: 109,
            name: "Barcelona",
            coordinate: TRPLocation(lat: 41.3850639, lon: 2.1734034999999494)
        )
    }
    
    private static func createMadridCity() -> TRPCity {
        return TRPCity(
            id: 308,
            name: "Madrid",
            coordinate: TRPLocation(lat: 40.4167754, lon: -3.7037902)
        )
    }
    
    private static func createMockTripProfile() -> TRPTimelineProfile {
        let profile = TRPTimelineProfile(cityId: 109)
        profile.hash = "7cbeea9f5ddc40cd807b15d8778736f6"
        profile.considerWeather = false
        profile.adults = 1
        profile.children = 0
        profile.pets = 0
        profile.answerIds = []
        profile.doNotRecommend = []
        profile.excludePoiIds = []
        profile.excludeHashPois = []
        
        // Segment 1: Main Barcelona Discovery (Full trip - Extended to Jan 1st)
        let mainSegment = TRPTimelineSegment()
        mainSegment.available = true
        mainSegment.title = "Barcelona Discovery"
        mainSegment.description = "6-day exploration of Barcelona"
        mainSegment.startDate = "2025-12-07 09:00"
        mainSegment.endDate = "2026-01-01 22:00"
        mainSegment.coordinate = TRPLocation(lat: 41.3850639, lon: 2.1734034999999494)
        mainSegment.adults = 1
        mainSegment.children = 0
        mainSegment.pets = 0
        mainSegment.generatedStatus = 0
        mainSegment.answerIds = []
        mainSegment.doNotRecommend = []
        mainSegment.excludePoiIds = []
        mainSegment.includePoiIds = []
        mainSegment.dayIds = [25459, 25460, 25461, 25462, 25463, 25464]
        mainSegment.considerWeather = false
        mainSegment.distinctPlan = true
        mainSegment.segmentType = .itinerary
        mainSegment.city = createBarcelonaCity()
        mainSegment.differentEndLocation = false
        mainSegment.differentMealSuggestions = false
        mainSegment.customSettings = false
        
        // Segment 2: Monday Special Activity (December 8th)
        let mondaySegment = TRPTimelineSegment()
        mondaySegment.available = true
        mondaySegment.title = "Gothic Quarter Deep Dive"
        mondaySegment.description = "Monday special: Explore historic Gothic Quarter and local culture"
        mondaySegment.startDate = "2025-12-08 09:00"
        mondaySegment.endDate = "2025-12-08 22:00"
        mondaySegment.coordinate = TRPLocation(lat: 41.3850639, lon: 2.1734034999999494)
        mondaySegment.adults = 1
        mondaySegment.children = 0
        mondaySegment.pets = 0
        mondaySegment.generatedStatus = 0
        mondaySegment.answerIds = []
        mondaySegment.doNotRecommend = []
        mondaySegment.excludePoiIds = []
        mondaySegment.includePoiIds = []
        mondaySegment.dayIds = [25460]
        mondaySegment.considerWeather = false
        mondaySegment.distinctPlan = true
        mondaySegment.segmentType = .itinerary
        mondaySegment.city = createBarcelonaCity()
        mondaySegment.differentEndLocation = false
        mondaySegment.differentMealSuggestions = false
        mondaySegment.customSettings = false
        
        // Segment 3: Booked Activity - Cooking Class (December 9th) - No plans
        let bookedActivitySegment = TRPTimelineSegment()
        bookedActivitySegment.available = false
        bookedActivitySegment.title = "Paella Cooking Class"
        bookedActivitySegment.description = "Learn to cook authentic Spanish paella with a local chef"
        bookedActivitySegment.startDate = "2025-12-09 07:00"
        bookedActivitySegment.endDate = "2025-12-09 10:00"
        bookedActivitySegment.coordinate = TRPLocation(lat: 41.3850639, lon: 2.1734034999999494)
        bookedActivitySegment.adults = 1
        bookedActivitySegment.children = 0
        bookedActivitySegment.pets = 0
        bookedActivitySegment.generatedStatus = 0
        bookedActivitySegment.answerIds = []
        bookedActivitySegment.doNotRecommend = []
        bookedActivitySegment.excludePoiIds = []
        bookedActivitySegment.includePoiIds = []
        bookedActivitySegment.dayIds = [25461]
        bookedActivitySegment.considerWeather = false
        bookedActivitySegment.distinctPlan = false
        bookedActivitySegment.segmentType = .bookedActivity
        bookedActivitySegment.city = createBarcelonaCity()
        bookedActivitySegment.differentEndLocation = false
        bookedActivitySegment.differentMealSuggestions = false
        bookedActivitySegment.customSettings = false
        
        // Add additional data for the booked activity
        bookedActivitySegment.additionalData = TRPSegmentActivityItem(
            activityId: "COOK-BCN-001",
            bookingId: "BOOKING-12345-BCN",
            title: "Authentic Paella Cooking Class",
            imageUrl: "https://poi-pics.s3-eu-west-1.amazonaws.com/Place/109/cooking-class.jpg",
            description: "Join us for an unforgettable 3-hour hands-on paella cooking experience. Learn the secrets of authentic Spanish cuisine from a professional chef. Includes all ingredients, cooking equipment, wine pairing, and of course, eating your delicious creation! Perfect for food lovers and culture enthusiasts.",
            startDatetime: "2025-12-09 07:00:00",
            endDatetime: "2025-12-09 10:00:00",
            coordinate: TRPLocation(lat: 41.3850639, lon: 2.1734034999999494),
            cancellation: "Free cancellation up to 48 hours before the activity starts. Cancellations made less than 48 hours before will incur a 50% charge.",
            adultCount: 1,
            childCount: 0
        )
        
        // Segment 4: Madrid Day Trip - Train Excursion (December 9th) - Different Location
        let madridSegment = TRPTimelineSegment()
        madridSegment.available = false
        madridSegment.title = "Madrid Day Trip by High-Speed Train"
        madridSegment.description = "Booked train excursion to Madrid including Royal Palace and Prado Museum"
        madridSegment.startDate = "2025-12-09 11:00"
        madridSegment.endDate = "2025-12-09 21:00"
        madridSegment.coordinate = TRPLocation(lat: 41.3850639, lon: 2.1734034999999494) // Barcelona start
        madridSegment.destinationCoordinate = TRPLocation(lat: 40.4167754, lon: -3.7037902) // Madrid
        madridSegment.adults = 1
        madridSegment.children = 0
        madridSegment.pets = 0
        madridSegment.generatedStatus = 0
        madridSegment.answerIds = []
        madridSegment.doNotRecommend = []
        madridSegment.excludePoiIds = []
        madridSegment.includePoiIds = []
        madridSegment.dayIds = [25461]
        madridSegment.considerWeather = false
        madridSegment.distinctPlan = false
        madridSegment.segmentType = .bookedActivity
        madridSegment.city = createMadridCity()
        madridSegment.differentEndLocation = true // Different city!
        madridSegment.differentMealSuggestions = false
        madridSegment.customSettings = false
        
        // Add additional data for the Madrid trip
        madridSegment.additionalData = TRPSegmentActivityItem(
            activityId: "TRAIN-MAD-001",
            bookingId: "BOOKING-RENFE-789",
            title: "Madrid Day Trip: Royal Palace & Prado Museum Tour",
            imageUrl: "https://poi-pics.s3-eu-west-1.amazonaws.com/City/308/royal-palace-madrid.jpg",
            description: "Experience the best of Madrid in one day! Depart Barcelona on a comfortable high-speed AVE train (2.5 hours). Visit the magnificent Royal Palace of Madrid with skip-the-line access, explore the world-famous Prado Museum showcasing masterpieces by Velázquez, Goya, and El Greco. Enjoy a traditional tapas lunch in the historic center. Return to Barcelona in the evening. Includes round-trip train tickets, museum entries, guided tours, and lunch.",
            startDatetime: "2025-12-09 11:00:00",
            endDatetime: "2025-12-09 21:00:00",
            coordinate: TRPLocation(lat: 40.4167754, lon: -3.7037902), // Madrid location
            cancellation: "Free cancellation up to 7 days before departure. Cancellations within 7 days are non-refundable due to train ticket policies.",
            adultCount: 1,
            childCount: 0
        )
        
        profile.segments = [mainSegment, mondaySegment, bookedActivitySegment, madridSegment]
        
        return profile
    }
    
    private static func createTimelineSegments(city: TRPCity) -> [TRPTimelineSegment] {
        // Segment 3: Booked Activity - Cooking Class (December 9th) - This is the important one!
        let bookedActivitySegment = TRPTimelineSegment()
        bookedActivitySegment.available = true
        bookedActivitySegment.title = "Paella Cooking Class"
        bookedActivitySegment.description = "Learn to cook authentic Spanish paella with a local chef"
        bookedActivitySegment.startDate = "2025-12-09 07:00:00" // Match additionalData time
        bookedActivitySegment.endDate = "2025-12-09 10:00:00"   // Match additionalData time
        bookedActivitySegment.coordinate = TRPLocation(lat: 41.3850639, lon: 2.1734034999999494)
        bookedActivitySegment.adults = 1
        bookedActivitySegment.children = 0
        bookedActivitySegment.pets = 0
        bookedActivitySegment.generatedStatus = 0
        bookedActivitySegment.segmentType = .bookedActivity
        bookedActivitySegment.city = city
        
        // Add additional data for the booked activity
        bookedActivitySegment.additionalData = TRPSegmentActivityItem(
            activityId: "COOK-BCN-001",
            bookingId: "BOOKING-12345-BCN",
            title: "Authentic Paella Cooking Class",
            imageUrl: "https://poi-pics.s3-eu-west-1.amazonaws.com/Place/109/540770/9b8537cd5a0559b05f257b57d707982d.jpg",
            description: "Join us for an unforgettable 3-hour hands-on paella cooking experience. Learn the secrets of authentic Spanish cuisine from a professional chef. Includes all ingredients, cooking equipment, wine pairing, and of course, eating your delicious creation! Perfect for food lovers and culture enthusiasts.",
            startDatetime: "2025-12-09 07:00:00",
            endDatetime: "2025-12-09 10:00:00",
            coordinate: TRPLocation(lat: 41.3850639, lon: 2.1734034999999494),
            cancellation: "Free cancellation up to 48 hours before the activity starts.",
            adultCount: 1,
            childCount: 0
        )
        
        // Segment 4: Madrid Day Trip - Train Excursion (December 9th) - Different Location
        let madridSegment = TRPTimelineSegment()
        madridSegment.available = true
        madridSegment.title = "Madrid Day Trip by High-Speed Train"
        madridSegment.description = "Booked train excursion to Madrid including Royal Palace and Prado Museum"
        madridSegment.startDate = "2025-12-09 11:00:00"
        madridSegment.endDate = "2025-12-09 21:00:00"
        madridSegment.coordinate = TRPLocation(lat: 41.3850639, lon: 2.1734034999999494) // Barcelona start
        madridSegment.destinationCoordinate = TRPLocation(lat: 40.4167754, lon: -3.7037902) // Madrid
        madridSegment.adults = 1
        madridSegment.children = 0
        madridSegment.pets = 0
        madridSegment.generatedStatus = 0
        madridSegment.segmentType = .bookedActivity
        madridSegment.city = createMadridCity()
        madridSegment.differentEndLocation = true
        
        // Add additional data for the Madrid trip
        madridSegment.additionalData = TRPSegmentActivityItem(
            activityId: "TRAIN-MAD-001",
            bookingId: "BOOKING-RENFE-789",
            title: "Madrid Day Trip: Royal Palace & Prado Museum Tour",
            imageUrl: "https://poi-pics.s3-eu-west-1.amazonaws.com/City/308/royal-palace-madrid.jpg",
            description: "Experience the best of Madrid in one day! Depart Barcelona on a comfortable high-speed AVE train (2.5 hours). Visit the magnificent Royal Palace of Madrid with skip-the-line access, explore the world-famous Prado Museum showcasing masterpieces by Velázquez, Goya, and El Greco. Enjoy a traditional tapas lunch in the historic center. Return to Barcelona in the evening. Includes round-trip train tickets, museum entries, guided tours, and lunch.",
            startDatetime: "2025-12-09 11:00:00",
            endDatetime: "2025-12-09 21:00:00",
            coordinate: TRPLocation(lat: 40.4167754, lon: -3.7037902), // Madrid location
            cancellation: "Free cancellation up to 7 days before departure. Cancellations within 7 days are non-refundable due to train ticket policies.",
            adultCount: 1,
            childCount: 0
        )
        
        return [bookedActivitySegment, madridSegment]
    }
    
    private static func create5DayPlans(city: TRPCity) -> [TRPTimelinePlan] {
        return [
            createDay1Plan(city: city),
            createDay2Plan(city: city),
            createDay2AlternativePlan(city: city), // Second plan for Day 2
            createDay3Plan(city: city),
            createDay4Plan(city: city),
            createDay5Plan(city: city),
            createDay6EmptyPlan(city: city) // Empty plan for next month
        ]
    }
    
    // MARK: - Day 1: Gaudí & Modernism
    private static func createDay1Plan(city: TRPCity) -> TRPTimelinePlan {
        let steps = [
            createStep(id: 126392, poi: createCiutatComtal(), score: 86, order: 0,
                      startTime: "2025-12-07 09:00:00", endTime: "2025-12-07 10:00:00"),
            
            createStep(id: 126393, poi: createCasaBatllo(), score: 99, order: 1,
                      startTime: "2025-12-07 10:30:00", endTime: "2025-12-07 12:00:00"),
            
            createStep(id: 126394, poi: createLaPedrera(), score: 98, order: 2,
                      startTime: "2025-12-07 12:30:00", endTime: "2025-12-07 14:00:00"),
            
            createStep(id: 126395, poi: createTavernaElGlop(), score: 61, order: 3,
                      startTime: "2025-12-07 14:30:00", endTime: "2025-12-07 15:30:00"),
            
            createStep(id: 126396, poi: createParkGuell(), score: 93, order: 4,
                      startTime: "2025-12-07 16:00:00", endTime: "2025-12-07 17:30:00"),
            
            createStep(id: 126397, poi: createBombaySpicy(), score: 59, order: 5,
                      startTime: "2025-12-07 19:00:00", endTime: "2025-12-07 20:30:00")
        ]
        
        return TRPTimelinePlan(
            id: "25459",
            startDate: "2025-12-07 09:00",
            endDate: "2025-12-07 21:00",
            steps: steps,
            available: true,
            tripType: 3,
            name: "Day 1: Gaudí & Modernism",
            description: "Explore Barcelona's iconic modernist architecture",
            generatedStatus: 0,
            children: 0,
            pets: 0,
            adults: 1,
            city: city,
            accommodation: nil,
            destinationAccommodation: nil
        )
    }
    
    // MARK: - Day 2: Gothic Quarter & Beach
    private static func createDay2Plan(city: TRPCity) -> TRPTimelinePlan {
        let steps = [
            createStep(id: 126401, poi: createCiutatComtal(), score: 86, order: 0,
                      startTime: "2025-12-08 09:00:00", endTime: "2025-12-08 10:00:00"),
            
            createStep(id: 126402, poi: createPalauGuell(), score: 90, order: 1,
                      startTime: "2025-12-08 10:30:00", endTime: "2025-12-08 12:00:00"),
            
            createStep(id: 126403, poi: createPlacaCatalunya(), score: 84, order: 2,
                      startTime: "2025-12-08 12:30:00", endTime: "2025-12-08 13:30:00"),
            
            createStep(id: 126404, poi: createTavernaElGlop(), score: 61, order: 3,
                      startTime: "2025-12-08 14:00:00", endTime: "2025-12-08 15:00:00"),
            
            createStep(id: 126405, poi: createLaTaverna(), score: 85, order: 4,
                      startTime: "2025-12-08 20:00:00", endTime: "2025-12-08 22:00:00")
        ]
        
        return TRPTimelinePlan(
            id: "25460",
            startDate: "2025-12-08 09:00",
            endDate: "2025-12-08 22:00",
            steps: steps,
            available: true,
            tripType: 3,
            name: "Day 2: Gothic Quarter & Beach",
            description: "Discover historic Barcelona and relax by the sea",
            generatedStatus: 0,
            children: 0,
            pets: 0,
            adults: 1,
            city: city,
            accommodation: nil,
            destinationAccommodation: nil
        )
    }
    
    // MARK: - Day 2 Alternative: Art & Culture Route
    private static func createDay2AlternativePlan(city: TRPCity) -> TRPTimelinePlan {
        let steps = [
            createStep(id: 126421, poi: createCiutatComtal(), score: 86, order: 0,
                      startTime: "2025-12-08 09:00:00", endTime: "2025-12-08 10:00:00"),
            
            createStep(id: 126422, poi: createCasaBatllo(), score: 99, order: 1,
                      startTime: "2025-12-08 10:30:00", endTime: "2025-12-08 12:00:00"),
            
            createStep(id: 126423, poi: createLaPedrera(), score: 98, order: 2,
                      startTime: "2025-12-08 12:30:00", endTime: "2025-12-08 14:00:00"),
            
            createStep(id: 126424, poi: createBombaySpicy(), score: 59, order: 3,
                      startTime: "2025-12-08 14:30:00", endTime: "2025-12-08 15:30:00"),
            
            createStep(id: 126425, poi: createParkGuell(), score: 93, order: 4,
                      startTime: "2025-12-08 16:00:00", endTime: "2025-12-08 17:30:00"),
            
            createStep(id: 126426, poi: createLaTaverna(), score: 85, order: 5,
                      startTime: "2025-12-08 20:00:00", endTime: "2025-12-08 22:00:00")
        ]
        
        return TRPTimelinePlan(
            id: "25460-alt",
            startDate: "2025-12-08 09:00",
            endDate: "2025-12-08 22:00",
            steps: steps,
            available: true,
            tripType: 3,
            name: "Day 2 Alternative: Art & Culture Route",
            description: "Alternative plan for Monday: Focus on Gaudí's art and culture",
            generatedStatus: 0,
            children: 0,
            pets: 0,
            adults: 1,
            city: city,
            accommodation: nil,
            destinationAccommodation: nil
        )
    }
    
    // MARK: - Day 3: Sagrada Familia & Markets
    private static func createDay3Plan(city: TRPCity) -> TRPTimelinePlan {
        let steps = [
            createStep(id: 126406, poi: createCiutatComtal(), score: 86, order: 0,
                      startTime: "2025-12-09 09:00:00", endTime: "2025-12-09 10:00:00"),
            
            // ACTIVITY TYPE STEP - Will show as booking card
            createActivityStep(id: 126421, poi: createSagradaFamiliaGuidedTour(), score: 98, order: 1,
                              startTime: "2025-12-09 10:30:00", endTime: "2025-12-09 12:00:00"),
            
            createStep(id: 126408, poi: createBombaySpicy(), score: 59, order: 2,
                      startTime: "2025-12-09 13:00:00", endTime: "2025-12-09 14:00:00"),
            
            createStep(id: 126409, poi: createParkGuell(), score: 93, order: 3,
                      startTime: "2025-12-09 15:00:00", endTime: "2025-12-09 16:30:00"),
            
            // ANOTHER ACTIVITY TYPE STEP - Will also show as booking card
            createActivityStep(id: 126422, poi: createFlamencoShow(), score: 92, order: 4,
                              startTime: "2025-12-09 18:00:00", endTime: "2025-12-09 19:30:00"),
            
            createStep(id: 126410, poi: createLaTaverna(), score: 85, order: 5,
                      startTime: "2025-12-09 20:00:00", endTime: "2025-12-09 22:00:00")
        ]
        
        return TRPTimelinePlan(
            id: "25461",
            startDate: "2025-12-09 09:00",
            endDate: "2025-12-09 22:00",
            steps: steps,
            available: true,
            tripType: 3,
            name: "Day 3: Activities & Culture",
            description: "Experience guided tours and local culture",
            generatedStatus: 0,
            children: 0,
            pets: 0,
            adults: 1,
            city: city,
            accommodation: nil,
            destinationAccommodation: nil
        )
    }
    
    // MARK: - Day 4: Montjuïc & Museums
    private static func createDay4Plan(city: TRPCity) -> TRPTimelinePlan {
        let steps = [
            createStep(id: 126411, poi: createCiutatComtal(), score: 86, order: 0,
                      startTime: "2025-12-10 09:00:00", endTime: "2025-12-10 10:00:00"),
            
            createStep(id: 126412, poi: createLaPedrera(), score: 98, order: 1,
                      startTime: "2025-12-10 10:30:00", endTime: "2025-12-10 12:00:00"),
            
            createStep(id: 126413, poi: createTavernaElGlop(), score: 61, order: 2,
                      startTime: "2025-12-10 13:00:00", endTime: "2025-12-10 14:00:00"),
            
            createStep(id: 126414, poi: createPalauGuell(), score: 90, order: 3,
                      startTime: "2025-12-10 15:00:00", endTime: "2025-12-10 16:30:00"),
            
            createStep(id: 126415, poi: createLaTaverna(), score: 85, order: 4,
                      startTime: "2025-12-10 19:00:00", endTime: "2025-12-10 21:00:00")
        ]
        
        return TRPTimelinePlan(
            id: "25462",
            startDate: "2025-12-10 09:00",
            endDate: "2025-12-10 21:00",
            steps: steps,
            available: true,
            tripType: 3,
            name: "Day 4: Montjuïc & Museums",
            description: "Explore hill views and art museums",
            generatedStatus: 0,
            children: 0,
            pets: 0,
            adults: 1,
            city: city,
            accommodation: nil,
            destinationAccommodation: nil
        )
    }
    
    // MARK: - Day 5: Last Day Shopping & Farewell
    private static func createDay5Plan(city: TRPCity) -> TRPTimelinePlan {
        let steps = [
            createStep(id: 126416, poi: createCiutatComtal(), score: 86, order: 0,
                      startTime: "2025-12-11 09:00:00", endTime: "2025-12-11 10:00:00"),
            
            createStep(id: 126417, poi: createPlacaCatalunya(), score: 84, order: 1,
                      startTime: "2025-12-11 10:30:00", endTime: "2025-12-11 12:00:00"),
            
            createStep(id: 126418, poi: createBombaySpicy(), score: 59, order: 2,
                      startTime: "2025-12-11 13:00:00", endTime: "2025-12-11 14:00:00"),
            
            createStep(id: 126419, poi: createCasaBatllo(), score: 99, order: 3,
                      startTime: "2025-12-11 15:00:00", endTime: "2025-12-11 16:30:00"),
            
            createStep(id: 126420, poi: createLaTaverna(), score: 85, order: 4,
                      startTime: "2025-12-11 19:00:00", endTime: "2025-12-11 21:00:00")
        ]
        
        return TRPTimelinePlan(
            id: "25463",
            startDate: "2025-12-11 09:00",
            endDate: "2025-12-11 21:00",
            steps: steps,
            available: true,
            tripType: 3,
            name: "Day 5: Last Day Shopping & Farewell",
            description: "Final shopping and farewell dinner",
            generatedStatus: 0,
            children: 0,
            pets: 0,
            adults: 1,
            city: city,
            accommodation: nil,
            destinationAccommodation: nil
        )
    }
    
    // MARK: - Day 6: Empty Plan for Next Month
    private static func createDay6EmptyPlan(city: TRPCity) -> TRPTimelinePlan {
        // Empty plan with no steps - for January 1st
        return TRPTimelinePlan(
            id: "25464",
            startDate: "2026-01-01 09:00",
            endDate: "2026-01-01 21:00",
            steps: [], // No steps - empty plan
            available: true,
            tripType: 3,
            name: "Day 6: Open Day",
            description: "No plans scheduled for this day",
            generatedStatus: 0,
            children: 0,
            pets: 0,
            adults: 1,
            city: city,
            accommodation: nil,
            destinationAccommodation: nil
        )
    }
    
    private static func createStep(id: Int, poi: TRPPoi, score: Double, order: Int,
                                   startTime: String, endTime: String) -> TRPTimelineStep {
        return TRPTimelineStep(
            id: id,
            poi: poi,
            score: score,
            planId: "25459",
            scoreDetails: [],
            order: order,
            startDateTimes: startTime,
            endDateTimes: endTime,
            stepType: "poi",
            attention: nil,
            alternatives: [],
            warningMessage: []
        )
    }
    
    /// Helper to create an activity type step (shown as booking card)
    private static func createActivityStep(id: Int, poi: TRPPoi, score: Double, order: Int,
                                          startTime: String, endTime: String) -> TRPTimelineStep {
        return TRPTimelineStep(
            id: id,
            poi: poi,
            score: score,
            planId: "25459",
            scoreDetails: [],
            order: order,
            startDateTimes: startTime,
            endDateTimes: endTime,
            stepType: "activity", // This makes it display as a booking card
            attention: nil,
            alternatives: [],
            warningMessage: []
        )
    }
    
    // MARK: - POI Creators
    
    /// Helper to add Barcelona location to POI
    private static func addBarcelonaLocation(to poi: inout TRPPoi) {
        poi.locations = [TRPPoiLocation(id: 109, name: "Barcelona", locationType: "city", country: "Spain", continent: "Europe")]
    }
    
    private static func createCiutatComtal() -> TRPPoi {
        let image = TRPImage(url: "https://poi-pics.s3-eu-west-1.amazonaws.com/Place/109/540930/a0e51807320fa93a84480724727a75f7.jpg",
                            imageOwner: nil, width: nil, height: nil)
        
        var poi = TRPPoi(
            id: "540930",
            cityId: 109,
            name: "Ciutat Comtal",
            image: image,
            gallery: [],
            duration: nil,
            price: nil,
            rating: 4.47,
            ratingCount: 40279,
            description: "We Do Not Take Reservations.",
            webUrl: "https://www.laflautagroup.com/",
            phone: "+34 933 18 19 97",
            hours: "Sun, Sat: 9:00 AM - 1:00 AM | Mon, Tue, Wed, Thu: 8:30 AM - 1:00 AM | Fri: 8:30 AM - 1:30 AM",
            address: "Rambla de Catalunya, 18, L'Eixample, 08007 Barcelona, Spain",
            icon: "Restaurant",
            coordinate: TRPLocation(lat: 41.388888919944996, lon: 2.166817811510395),
            bookings: nil,
            categories: [TRPPoiCategory(id: 3, name: "Restaurants", isCustom: false)],
            tags: [],
            mustTries: [],
            cuisines: "european, tapas, mediterranean, seafood, ice cream, hamburgers, spanish",
            attention: "Reservation recommended.",
            closed: [],
            distance: nil,
            safety: [],
            status: true,
            placeType: .poi,
            offers: [],
            additionalData: nil
        )
        poi.locations = [TRPPoiLocation(id: 109, name: "Barcelona", locationType: "city", country: "Spain", continent: "Europe")]
        return poi
    }
    
    private static func createCasaBatllo() -> TRPPoi {
        let image = TRPImage(url: "https://poi-pics.s3-eu-west-1.amazonaws.com/Place/109/540484/a7851827f89def28341f5e6b80938032.jpg",
                            imageOwner: nil, width: nil, height: nil)
        
        var poi = TRPPoi(
            id: "540484",
            cityId: 109,
            name: "Casa Batlló",
            image: image,
            gallery: [],
            duration: 90,
            price: nil,
            rating: 4.6,
            ratingCount: 245826,
            description: "Casa Batlló is a building in the center of Barcelona. It was designed by Antoni Gaudí, and is considered one of his masterpieces.",
            webUrl: "https://www.casabatllo.es/",
            phone: "+34 932 16 03 06",
            hours: "Sun, Mon, Tue, Wed, Thu, Fri, Sat: 8:30 AM - 10:30 PM",
            address: "Pg. de Gràcia, 43, L'Eixample, 08007 Barcelona, Spain",
            icon: "Attraction",
            coordinate: TRPLocation(lat: 41.391640169945, lon: 2.164789513508397),
            bookings: nil,
            categories: [TRPPoiCategory(id: 1, name: "Attractions", isCustom: false)],
            tags: [],
            mustTries: [],
            cuisines: nil,
            attention: nil,
            closed: [],
            distance: nil,
            safety: [],
            status: true,
            placeType: .poi,
            offers: [],
            additionalData: nil
        )
        addBarcelonaLocation(to: &poi)
        return poi
    }
    
    private static func createLaPedrera() -> TRPPoi {
        let image = TRPImage(url: "https://poi-pics.s3-eu-west-1.amazonaws.com/Place/109/543194/72670f8390ba3d616c48f6a7b4574085.jpg",
                            imageOwner: nil, width: nil, height: nil)
        
        var poi = TRPPoi(
            id: "543194",
            cityId: 109,
            name: "La Pedrera - Casa Milà",
            image: image,
            gallery: [],
            duration: 90,
            price: nil,
            rating: 4.35,
            ratingCount: 127793,
            description: "Casa Milà, popularly known as La Pedrera or The stone quarry, is a modernist building in Barcelona.",
            webUrl: "https://www.lapedrera.com/es",
            phone: "+34 932 14 25 76",
            hours: "Sun, Mon, Tue, Wed, Thu, Fri, Sat: 9:00 AM - 11:00 PM",
            address: "Pg. de Gràcia, 92, L'Eixample, 08008 Barcelona, Spain",
            icon: "Attraction",
            coordinate: TRPLocation(lat: 41.395250919945, lon: 2.1619496161310052),
            bookings: nil,
            categories: [TRPPoiCategory(id: 1, name: "Attractions", isCustom: false)],
            tags: [],
            mustTries: [],
            cuisines: nil,
            attention: nil,
            closed: [],
            distance: nil,
            safety: [],
            status: true,
            placeType: .poi,
            offers: [],
            additionalData: nil
        )
        addBarcelonaLocation(to: &poi)
        return poi
    }
    
    private static func createTavernaElGlop() -> TRPPoi {
        let image = TRPImage(url: "https://poi-pics.s3-eu-west-1.amazonaws.com/Place/109/544238/8fd4f14ce6eb6dff074b3112b4d8c846.jpg",
                            imageOwner: nil, width: nil, height: nil)
        
        var poi = TRPPoi(
            id: "544238",
            cityId: 109,
            name: "Taverna El Glop",
            image: image,
            gallery: [],
            duration: nil,
            price: nil,
            rating: 4.22,
            ratingCount: 12298,
            description: nil,
            webUrl: "http://www.elglop.com/",
            phone: "+34 932 13 70 58",
            hours: "Sun, Mon, Tue, Wed, Thu, Fri, Sat: 11:00 AM - 12:00 AM",
            address: "Carrer de Sant Lluís, 24, Gràcia, 08012 Barcelona, Spain",
            icon: "Restaurant",
            coordinate: TRPLocation(lat: 41.404922719945, lon: 2.159591623158315),
            bookings: nil,
            categories: [TRPPoiCategory(id: 3, name: "Restaurants", isCustom: false)],
            tags: [],
            mustTries: [],
            cuisines: "tapas, mediterranean, seafood, ice cream, pasta, spanish",
            attention: "Reservations required.",
            closed: [],
            distance: nil,
            safety: [],
            status: true,
            placeType: .poi,
            offers: [],
            additionalData: nil
        )
        addBarcelonaLocation(to: &poi)
        return poi
    }
    
    private static func createParkGuell() -> TRPPoi {
        let image = TRPImage(url: "https://poi-pics.s3-eu-west-1.amazonaws.com/Place/109/540770/9b8537cd5a0559b05f257b57d707982d.jpg",
                            imageOwner: nil, width: nil, height: nil)
        
        var poi = TRPPoi(
            id: "540770",
            cityId: 109,
            name: "Park Güell",
            image: image,
            gallery: [],
            duration: 90,
            price: nil,
            rating: 4.14,
            ratingCount: 296654,
            description: "Parc Güell is a privatized park system composed of gardens and architectural elements located on Carmel Hill, in Barcelona.",
            webUrl: "https://parkguell.barcelona/",
            phone: "+34 934 09 18 31",
            hours: "Sun, Mon, Tue, Wed, Thu, Fri, Sat: 9:00 AM - 8:00 PM",
            address: "Gràcia, 08024 Barcelona, Spain",
            icon: "Attraction",
            coordinate: TRPLocation(lat: 41.41453021994501, lon: 2.1527417301423077),
            bookings: nil,
            categories: [TRPPoiCategory(id: 1, name: "Attractions", isCustom: false)],
            tags: [],
            mustTries: [],
            cuisines: nil,
            attention: nil,
            closed: [],
            distance: nil,
            safety: [],
            status: true,
            placeType: .poi,
            offers: [],
            additionalData: nil
        )
        addBarcelonaLocation(to: &poi)
        return poi
    }
    
    private static func createPalauGuell() -> TRPPoi {
        let image = TRPImage(url: "https://poi-pics.s3-eu-west-1.amazonaws.com/Place/109/543512/f258dbead165a8fc65fc4832a10115fb.jpg",
                            imageOwner: nil, width: nil, height: nil)
        
        var poi = TRPPoi(
            id: "543512",
            cityId: 109,
            name: "Palau Güell",
            image: image,
            gallery: [],
            duration: 90,
            price: nil,
            rating: 4.53,
            ratingCount: 31827,
            description: "The Palau Güell is a mansion designed by the architect Antoni Gaudí for the industrial tycoon Eusebi Güell.",
            webUrl: "https://inici.palauguell.cat/",
            phone: "+34 934 72 57 75",
            hours: "Sun, Tue, Wed, Thu, Fri, Sat: 10:00 AM - 8:00 PM",
            address: "Carrer Nou de la Rambla, 3-5, Ciutat Vella, 08001 Barcelona, Spain",
            icon: "Attraction",
            coordinate: TRPLocation(lat: 41.378920519945, lon: 2.174287004273508),
            bookings: nil,
            categories: [TRPPoiCategory(id: 1, name: "Attractions", isCustom: false)],
            tags: [],
            mustTries: [],
            cuisines: nil,
            attention: nil,
            closed: [1], // Closed on Monday
            distance: nil,
            safety: [],
            status: true,
            placeType: .poi,
            offers: [],
            additionalData: nil
        )
        addBarcelonaLocation(to: &poi)
        return poi
    }
    
    private static func createBombaySpicy() -> TRPPoi {
        let image = TRPImage(url: "https://poi-pics.s3-eu-west-1.amazonaws.com/Place/109/540640/1d90b758459a2ab9c931b8d9260593de.jpg",
                            imageOwner: nil, width: nil, height: nil)
        
        var poi = TRPPoi(
            id: "540640",
            cityId: 109,
            name: "Bombay Spicy",
            image: image,
            gallery: [],
            duration: nil,
            price: nil,
            rating: 4.14,
            ratingCount: 3836,
            description: "We used to serve authentic indian food having big variety for both vegetarián & nonvegeterian peoples.",
            webUrl: "https://bombayspicybarcelona.com/index.html",
            phone: "+34 933 17 49 18",
            hours: "Sun, Mon, Tue, Wed, Thu, Fri: 12:00 PM - 11:30 PM | Sat: 12:00 PM - 11:45 PM",
            address: "Carrer de Sant Pau, 18, Ciutat Vella, 08001 Barcelona, Spain",
            icon: "Restaurant",
            coordinate: TRPLocation(lat: 41.380526319945, lon: 2.173043705439045),
            bookings: nil,
            categories: [TRPPoiCategory(id: 3, name: "Restaurants", isCustom: false)],
            tags: [],
            mustTries: [],
            cuisines: "tapas, indian",
            attention: nil,
            closed: [],
            distance: nil,
            safety: [],
            status: true,
            placeType: .poi,
            offers: [],
            additionalData: nil
        )
        addBarcelonaLocation(to: &poi)
        return poi
    }
    
    private static func createPlacaCatalunya() -> TRPPoi {
        let image = TRPImage(url: "https://poi-pics.s3-eu-west-1.amazonaws.com/Place/109/543441/f6b77e499f314d43026ce9f45ad63e25.jpg",
                            imageOwner: nil, width: nil, height: nil)
        
        var poi = TRPPoi(
            id: "543441",
            cityId: 109,
            name: "Plaça de Catalunya",
            image: image,
            gallery: [],
            duration: 120,
            price: nil,
            rating: 4.17,
            ratingCount: 210789,
            description: "Plaça de Catalunya is a large square in central Barcelona that is generally considered to be both its city centre.",
            webUrl: "https://www.meet.barcelona/ca/visita-la-i-estima-la/punts-dinteres-de-la-ciutat/la-placa-de-catalunya-99400356287",
            phone: nil,
            hours: "Mon, Tue, Wed, Thu, Fri, Sat, Sun: Open 24 hours",
            address: "L'Eixample, 08002 Barcelona, Spain",
            icon: "Attraction",
            coordinate: TRPLocation(lat: 41.387050819944996, lon: 2.170094310175692),
            bookings: nil,
            categories: [TRPPoiCategory(id: 1, name: "Attractions", isCustom: false)],
            tags: [],
            mustTries: [],
            cuisines: nil,
            attention: nil,
            closed: [],
            distance: nil,
            safety: [],
            status: true,
            placeType: .poi,
            offers: [],
            additionalData: nil
        )
        addBarcelonaLocation(to: &poi)
        return poi
    }
    
    private static func createLaTaverna() -> TRPPoi {
        let image = TRPImage(url: "https://poi-pics.s3-eu-west-1.amazonaws.com/Place/109/539846/338abac4fb316a086287ccc259edbeef.jpg",
                            imageOwner: nil, width: nil, height: nil)
        
        var poi = TRPPoi(
            id: "539846",
            cityId: 109,
            name: "La Taverna de Barcelona",
            image: image,
            gallery: [],
            duration: nil,
            price: nil,
            rating: 4.09,
            ratingCount: 7528,
            description: "Catalan Sport Bar, Live Music Every day 2 passes, from 22h to 24h and 00:30 to 03: 00h.",
            webUrl: "https://www.instagram.com/latavernadebarcelona",
            phone: "+34 933 01 76 53",
            hours: "Sun, Tue, Wed, Thu, Fri, Sat: 7:00 PM - 3:00 AM",
            address: "Ronda de la Univ., 37, L'Eixample, 08007 Barcelona, Spain",
            icon: "Bar",
            coordinate: TRPLocation(lat: 41.387368819944996, lon: 2.167970510406593),
            bookings: nil,
            categories: [TRPPoiCategory(id: 31, name: "Bars", isCustom: false)],
            tags: [],
            mustTries: [],
            cuisines: "european, tapas, seafood, pub, ice cream, pasta, hamburgers, spanish, gastropub",
            attention: "Reservation recommended.",
            closed: [1], // Closed on Monday
            distance: nil,
            safety: [],
            status: true,
            placeType: .poi,
            offers: [],
            additionalData: nil
        )
        addBarcelonaLocation(to: &poi)
        return poi
    }
    
    // MARK: - Activity POIs (for activity type steps)
    
    private static func createSagradaFamiliaGuidedTour() -> TRPPoi {
        let image = TRPImage(url: "https://poi-pics.s3-eu-west-1.amazonaws.com/Place/109/539346/7ba7b60e8f64e66f1b75f3e6e1eb5a20.jpg",
                            imageOwner: nil, width: nil, height: nil)
        
        var poi = TRPPoi(
            id: "C_154506_15",
            cityId: 109,
            name: "Sagrada Familia Guided Tour with Skip-the-Line Access",
            image: image,
            gallery: [],
            duration: 90,
            price: 45,
            rating: 4.8,
            ratingCount: 51109,
            description: "On this guided tour of the Sagrada Familia, explore Gaudí's masterpiece with an expert guide. Skip the long lines and discover the history, architecture, and symbolism of this iconic basilica. Learn about the construction that has been ongoing since 1882 and marvel at the stunning stained glass windows and intricate facades.",
            webUrl: "https://tripian.com",
            phone: nil,
            hours: "Sun, Mon, Tue, Wed, Thu, Fri, Sat: 9:00 AM - 8:00 PM",
            address: "C/ de Mallorca, 401, L'Eixample, 08013 Barcelona, Spain",
            icon: "Activity",
            coordinate: TRPLocation(lat: 41.4036299, lon: 2.1743558),
            bookings: nil,
            categories: [TRPPoiCategory(id: 1, name: "Activities", isCustom: false)],
            tags: [],
            mustTries: [],
            cuisines: nil,
            attention: "Skip-the-line access included. Tour starts on time - please arrive 10 minutes early.",
            closed: [],
            distance: nil,
            safety: [],
            status: true,
            placeType: .poi,
            offers: [],
            additionalData: nil
        )
        addBarcelonaLocation(to: &poi)
        return poi
    }
    
    private static func createFlamencoShow() -> TRPPoi {
        let image = TRPImage(url: "https://poi-pics.s3-eu-west-1.amazonaws.com/Activities/flamenco-barcelona.jpg",
                            imageOwner: nil, width: nil, height: nil)
        
        var poi = TRPPoi(
            id: "ACTIVITY_FLAMENCO_001",
            cityId: 109,
            name: "Authentic Flamenco Show with Tapas & Drinks",
            image: image,
            gallery: [],
            duration: 90,
            price: 35,
            rating: 4.7,
            ratingCount: 8542,
            description: "Experience the passion of authentic Spanish flamenco in an intimate tablao setting. This 90-minute show features professional dancers, singers, and guitarists performing traditional and contemporary flamenco. Includes a selection of Spanish tapas and one drink (wine, beer, or soft drink). Located in the heart of Barcelona's Gothic Quarter.",
            webUrl: "https://tripian.com",
            phone: "+34 933 19 17 89",
            hours: "Daily shows at 6:00 PM and 8:30 PM",
            address: "Plaça Reial, 17, Ciutat Vella, 08002 Barcelona, Spain",
            icon: "Activity",
            coordinate: TRPLocation(lat: 41.3798, lon: 2.1755),
            bookings: nil,
            categories: [TRPPoiCategory(id: 1, name: "Activities", isCustom: false)],
            tags: [],
            mustTries: [],
            cuisines: nil,
            attention: "Reserved seating. Doors open 30 minutes before showtime. Smart casual dress code recommended.",
            closed: [],
            distance: nil,
            safety: [],
            status: true,
            placeType: .poi,
            offers: [],
            additionalData: nil
        )
        addBarcelonaLocation(to: &poi)
        return poi
    }
}
