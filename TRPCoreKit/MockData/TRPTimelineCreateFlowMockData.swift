//
//  TRPTimelineCreateFlowMockData.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 27.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

/**
 Mock data for testing timeline creation flow

 Specifications:
 - 3 days plan
 - 2 booked activities (1 on day 1, 1 on day 3)
 - 2 wishlisted activities
 */
public class TRPTimelineCreateFlowMockData {

    // MARK: - Public Methods

    /// Returns a mock timeline profile for creating a new timeline
    public static func getMockTimelineProfile() -> TRPTimelineProfile {
        let profile = TRPTimelineProfile(cityId: 109) // Barcelona

        // Travelers
        profile.adults = 2
        profile.children = 0
        profile.pets = 0

        // Settings
        profile.answerIds = [] // Empty like the example
        profile.doNotRecommend = []
        profile.excludePoiIds = []

        // Create segments with booked activities
        // Dates are defined in segments, not in profile
        let startDate = Date().addDay(1) ?? Date()
        profile.segments = createMockSegments(startDate: startDate)

        return profile
    }

    /// Returns a mock timeline (used for both created and fetched responses)
    /// - Parameter withPlans: If true, includes generated plans. If false, plans are nil (still generating)
    public static func getMockTimeline(withPlans: Bool = true) -> TRPTimeline {
        let city = createBarcelonaCity()
        let startDate = Date().addDay(1) ?? Date()
        let profile = getMockTimelineProfile()

        // Create 3-day plans if requested
        let plans = withPlans ? create3DayPlans(city: city, startDate: startDate) : nil

        // Create timeline
        var timeline = TRPTimeline(
            id: 12345,
            tripHash: "mock_create_flow_hash_123",
            tripProfile: profile,
            city: city,
            plans: plans
        )

        timeline.segments = createMockSegments(startDate: startDate)

        return timeline
    }

    // MARK: - Private Helper Methods

    private static func createBarcelonaCity() -> TRPCity {
        return TRPCity(
            id: 109,
            name: "Barcelona",
            coordinate: TRPLocation(lat: 41.3850639, lon: 2.1734034999999494)
        )
    }

    private static func createMockSegments(startDate: Date) -> [TRPTimelineSegment] {
        var segments: [TRPTimelineSegment] = []

        // Segment 1: Booked Activity - Day 1 (Sagrada Familia Tour)
        let bookedActivity1 = TRPTimelineSegment()
        bookedActivity1.segmentType = .bookedActivity
        bookedActivity1.distinctPlan = true
        bookedActivity1.available = false
        bookedActivity1.title = "Sagrada Familia Guided Tour"
        bookedActivity1.description = "Skip-the-line guided tour of Gaudí's masterpiece"
        bookedActivity1.startDate = startDate.toString(format: "yyyy-MM-dd 14:00")
        bookedActivity1.endDate = startDate.toString(format: "yyyy-MM-dd 16:30")
        bookedActivity1.coordinate = TRPLocation(lat: 41.4036, lon: 2.1744)
        bookedActivity1.adults = 2
        bookedActivity1.children = 0
        bookedActivity1.pets = 0
        bookedActivity1.generatedStatus = 1

        // Additional Data for booked activity
//        bookedActivity1.additionalData = TRPSegmentActivityItem(coordinate: TRPLocation(lat: 41.4036, lon: 2.1744))
//        bookedActivity1.additionalData?.activityId = "1516123"
//        bookedActivity1.additionalData?.bookingId = "2113"
//        bookedActivity1.additionalData?.title = "Sagrada Familia Guided Tour"
//        bookedActivity1.additionalData?.imageUrl = "https://media.tacdn.com/media/attractions-splice-spp-674x446/06/6f/85/23.jpg"
//        bookedActivity1.additionalData?.description = "Skip-the-line guided tour of Gaudí's masterpiece"
//        bookedActivity1.additionalData?.startDatetime = startDate.toString(format: "yyyy-MM-dd 14:00")
//        bookedActivity1.additionalData?.endDatetime = startDate.toString(format: "yyyy-MM-dd 16:30")
//        bookedActivity1.additionalData?.cancellation = "Free cancellation up to 24 hours before"
//        segments.append(bookedActivity1)

        // Segment 2: Booked Activity - Day 3 (Flamenco Show)
        let day3Date = startDate.addDay(2) ?? startDate
        let bookedActivity2 = TRPTimelineSegment()
        bookedActivity2.segmentType = .bookedActivity
        bookedActivity2.distinctPlan = true
        bookedActivity2.available = false
        bookedActivity2.title = "Authentic Flamenco Show & Dinner"
        bookedActivity2.description = "Traditional flamenco performance with tapas dinner"
        bookedActivity2.startDate = day3Date.toString(format: "yyyy-MM-dd 20:00")
        bookedActivity2.endDate = day3Date.toString(format: "yyyy-MM-dd 22:30")
        bookedActivity2.coordinate = TRPLocation(lat: 41.3789, lon: 2.1750)
        bookedActivity2.adults = 2
        bookedActivity2.children = 0
        bookedActivity2.pets = 0
        bookedActivity2.generatedStatus = 1

        // Additional Data for booked activity
//        bookedActivity2.additionalData = TRPSegmentActivityItem(coordinate: TRPLocation(lat: 41.3789, lon: 2.1750))
//        bookedActivity2.additionalData?.activityId = "FLAMENCO-BCN-001"
//        bookedActivity2.additionalData?.bookingId = "BOOKING-FL-456"
//        bookedActivity2.additionalData?.title = "Authentic Flamenco Show & Dinner"
//        bookedActivity2.additionalData?.imageUrl = "https://media.tacdn.com/media/attractions-splice-spp-674x446/07/74/e1/dc.jpg"
//        bookedActivity2.additionalData?.description = "Traditional flamenco performance with tapas dinner"
//        bookedActivity2.additionalData?.startDatetime = day3Date.toString(format: "yyyy-MM-dd 20:00")
//        bookedActivity2.additionalData?.endDatetime = day3Date.toString(format: "yyyy-MM-dd 22:30")
//        bookedActivity2.additionalData?.cancellation = "Free cancellation up to 24 hours before"
//        segments.append(bookedActivity2)

        // Segment 3: Reserved Activity - Day 2 (Paella Cooking Class)
        let day2Date = startDate.addDay(1) ?? startDate
        let reservedActivity = TRPTimelineSegment()
        reservedActivity.segmentType = .reservedActivity  // RESERVED (not booked yet)
        reservedActivity.distinctPlan = true
        reservedActivity.available = false
        reservedActivity.title = "Paella Cooking Class"
        reservedActivity.description = "Learn to cook authentic Spanish paella with a local chef"
        reservedActivity.startDate = day2Date.toString(format: "yyyy-MM-dd 18:00")
        reservedActivity.endDate = day2Date.toString(format: "yyyy-MM-dd 20:30")
        reservedActivity.coordinate = TRPLocation(lat: 41.3874, lon: 2.1686)
        reservedActivity.adults = 2
        reservedActivity.children = 0
        reservedActivity.pets = 0
        reservedActivity.generatedStatus = 1

        // Additional Data for reserved activity (uses bookingId)
//        reservedActivity.additionalData = TRPSegmentActivityItem(coordinate: TRPLocation(lat: 41.3874, lon: 2.1686))
//        reservedActivity.additionalData?.activityId = "PAELLA-CLASS-789"
//        reservedActivity.additionalData?.bookingId = "RES-PAELLA-012"  // reservation ID stored in bookingId field
//        reservedActivity.additionalData?.title = "Paella Cooking Class"
//        reservedActivity.additionalData?.imageUrl = "https://media.tacdn.com/media/attractions-splice-spp-674x446/09/91/2a/5f.jpg"
//        reservedActivity.additionalData?.description = "Learn to cook authentic Spanish paella with a local chef"
//        reservedActivity.additionalData?.startDatetime = day2Date.toString(format: "yyyy-MM-dd 18:00")
//        reservedActivity.additionalData?.endDatetime = day2Date.toString(format: "yyyy-MM-dd 20:30")
//        reservedActivity.additionalData?.cancellation = "Reservation pending - Complete payment to confirm"
//        reservedActivity.additionalData?.adultCount = 2
//        reservedActivity.additionalData?.childCount = 0
//        segments.append(reservedActivity)

        return segments
    }

    private static func create3DayPlans(city: TRPCity, startDate: Date) -> [TRPTimelinePlan] {
        var plans: [TRPTimelinePlan] = []

        // Day 1
        let day1Steps = createDay1Steps(date: startDate, dayId: 1001)
        var plan1 = TRPTimelinePlan(
            id: "1001",
            startDate: startDate.toString(format: "yyyy-MM-dd 00:00") ?? "",
            endDate: startDate.toString(format: "yyyy-MM-dd 23:59") ?? "",
            steps: day1Steps,
            generatedStatus: 1
        )
        plan1.city = city
        plans.append(plan1)

        // Day 2
        let day2Date = startDate.addDay(1) ?? startDate
        let day2Steps = createDay2Steps(date: day2Date, dayId: 1002)
        var plan2 = TRPTimelinePlan(
            id: "1002",
            startDate: day2Date.toString(format: "yyyy-MM-dd 00:00") ?? "",
            endDate: day2Date.toString(format: "yyyy-MM-dd 23:59") ?? "",
            steps: day2Steps,
            generatedStatus: 1
        )
        plan2.city = city
        plans.append(plan2)

        // Day 3
        let day3Date = startDate.addDay(2) ?? startDate
        let day3Steps = createDay3Steps(date: day3Date, dayId: 1003)
        var plan3 = TRPTimelinePlan(
            id: "1003",
            startDate: day3Date.toString(format: "yyyy-MM-dd 00:00") ?? "",
            endDate: day3Date.toString(format: "yyyy-MM-dd 23:59") ?? "",
            steps: day3Steps,
            generatedStatus: 1
        )
        plan3.city = city
        plans.append(plan3)

        return plans
    }

    // MARK: - Day 1 Steps (includes Sagrada Familia booked activity)

    private static func createDay1Steps(date: Date, dayId: Int) -> [TRPTimelineStep] {
        var steps: [TRPTimelineStep] = []

        // Morning: Park Güell (Wishlisted POI #1)
        let parkGuell = createParkGuellPOI()
        let step1 = TRPTimelineStep(
            id: 10001,
            poi: parkGuell,
            score: 9.5,
            planId: String(dayId),
            scoreDetails: nil,
            order: 0,
            startDateTimes: date.toString(format: "yyyy-MM-dd 09:30:00"),
            endDateTimes: date.toString(format: "yyyy-MM-dd 11:30:00"),
            stepType: "poi",
            attention: nil,
            alternatives: nil,
            warningMessage: nil
        )
        steps.append(step1)

        // Lunch: La Boqueria Market
        let boqueria = createLaBoqueriaPOI()
        let step2 = TRPTimelineStep(
            id: 10002,
            poi: boqueria,
            score: 8.8,
            planId: String(dayId),
            scoreDetails: nil,
            order: 1,
            startDateTimes: date.toString(format: "yyyy-MM-dd 12:00:00"),
            endDateTimes: date.toString(format: "yyyy-MM-dd 13:00:00"),
            stepType: "poi",
            attention: nil,
            alternatives: nil,
            warningMessage: nil
        )
        steps.append(step2)

        // Afternoon: Sagrada Familia (Booked Activity - handled by segment)
        // Note: The booked activity is in segments, not steps

        // Evening: Gothic Quarter
        let gothicQuarter = createGothicQuarterPOI()
        let step3 = TRPTimelineStep(
            id: 10003,
            poi: gothicQuarter,
            score: 9.2,
            planId: String(dayId),
            scoreDetails: nil,
            order: 2,
            startDateTimes: date.toString(format: "yyyy-MM-dd 17:00:00"),
            endDateTimes: date.toString(format: "yyyy-MM-dd 19:00:00"),
            stepType: "poi",
            attention: nil,
            alternatives: nil,
            warningMessage: nil
        )
        steps.append(step3)

        return steps
    }

    // MARK: - Day 2 Steps

    private static func createDay2Steps(date: Date, dayId: Int) -> [TRPTimelineStep] {
        var steps: [TRPTimelineStep] = []

        // Morning: Casa Batlló
        let casaBatllo = createCasaBatlloPOI()
        let step1 = TRPTimelineStep(
            id: 10004,
            poi: casaBatllo,
            score: 9.3,
            planId: String(dayId),
            scoreDetails: nil,
            order: 0,
            startDateTimes: date.toString(format: "yyyy-MM-dd 10:00:00"),
            endDateTimes: date.toString(format: "yyyy-MM-dd 12:00:00"),
            stepType: "poi",
            attention: nil,
            alternatives: nil,
            warningMessage: nil
        )
        steps.append(step1)

        // Afternoon: Barceloneta Beach (Wishlisted POI #2)
        let barcelonetaBeach = createBarcelonetaBeachPOI()
        let step2 = TRPTimelineStep(
            id: 10005,
            poi: barcelonetaBeach,
            score: 8.5,
            planId: String(dayId),
            scoreDetails: nil,
            order: 1,
            startDateTimes: date.toString(format: "yyyy-MM-dd 14:00:00"),
            endDateTimes: date.toString(format: "yyyy-MM-dd 17:00:00"),
            stepType: "poi",
            attention: nil,
            alternatives: nil,
            warningMessage: nil
        )
        steps.append(step2)

        // Evening: Passeig de Gràcia
        let passeigGracia = createPasseigGraciaPOI()
        let step3 = TRPTimelineStep(
            id: 10006,
            poi: passeigGracia,
            score: 8.7,
            planId: String(dayId),
            scoreDetails: nil,
            order: 2,
            startDateTimes: date.toString(format: "yyyy-MM-dd 18:00:00"),
            endDateTimes: date.toString(format: "yyyy-MM-dd 20:00:00"),
            stepType: "poi",
            attention: nil,
            alternatives: nil,
            warningMessage: nil
        )
        steps.append(step3)

        return steps
    }

    // MARK: - Day 3 Steps (includes Flamenco Show booked activity)

    private static func createDay3Steps(date: Date, dayId: Int) -> [TRPTimelineStep] {
        var steps: [TRPTimelineStep] = []

        // Morning: Montjuïc Castle
        let montjuicCastle = createMontjuicCastlePOI()
        let step1 = TRPTimelineStep(
            id: 10007,
            poi: montjuicCastle,
            score: 8.9,
            planId: String(dayId),
            scoreDetails: nil,
            order: 0,
            startDateTimes: date.toString(format: "yyyy-MM-dd 10:00:00"),
            endDateTimes: date.toString(format: "yyyy-MM-dd 12:30:00"),
            stepType: "poi",
            attention: nil,
            alternatives: nil,
            warningMessage: nil
        )
        steps.append(step1)

        // Afternoon: Camp Nou
        let campNou = createCampNouPOI()
        let step2 = TRPTimelineStep(
            id: 10008,
            poi: campNou,
            score: 9.0,
            planId: String(dayId),
            scoreDetails: nil,
            order: 1,
            startDateTimes: date.toString(format: "yyyy-MM-dd 14:00:00"),
            endDateTimes: date.toString(format: "yyyy-MM-dd 17:00:00"),
            stepType: "poi",
            attention: nil,
            alternatives: nil,
            warningMessage: nil
        )
        steps.append(step2)

        // Evening: Flamenco Show (Booked Activity - handled by segment)
        // Note: The booked activity is in segments, not steps

        return steps
    }

    // MARK: - POI Creation Methods

    private static func createParkGuellPOI() -> TRPPoi {
        var poi = TRPPoi(
            id: "poi_park_guell",
            cityId: 109,
            name: "Park Güell",
            image: TRPImage(url: "https://example.com/park_guell.jpg", width: 1000, height: 667),
            icon: "parks",
            coordinate: TRPLocation(lat: 41.4145, lon: 2.1527),
            status: true
        )
        poi.description = "Whimsical park designed by Antoni Gaudí with mosaic art and stunning city views"
        poi.rating = 4.6
        poi.ratingCount = 52341
        poi.address = "Carrer d'Olot, 5, 08024 Barcelona"
        return poi
    }

    private static func createLaBoqueriaPOI() -> TRPPoi {
        var poi = TRPPoi(
            id: "poi_la_boqueria",
            cityId: 109,
            name: "La Boqueria Market",
            image: TRPImage(url: "https://example.com/la_boqueria.jpg", width: 1000, height: 667),
            icon: "restaurant",
            coordinate: TRPLocation(lat: 41.3818, lon: 2.1713),
            status: true
        )
        poi.description = "Famous public market with fresh produce, seafood, and traditional Spanish delicacies"
        poi.rating = 4.4
        poi.ratingCount = 38921
        poi.address = "La Rambla, 91, 08001 Barcelona"
        return poi
    }

    private static func createGothicQuarterPOI() -> TRPPoi {
        var poi = TRPPoi(
            id: "poi_gothic_quarter",
            cityId: 109,
            name: "Gothic Quarter",
            image: TRPImage(url: "https://example.com/gothic_quarter.jpg", width: 1000, height: 667),
            icon: "attraction",
            coordinate: TRPLocation(lat: 41.3828, lon: 2.1764),
            status: true
        )
        poi.description = "Historic medieval neighborhood with narrow streets, charming squares, and Gothic architecture"
        poi.rating = 4.7
        poi.ratingCount = 45678
        poi.address = "Barri Gòtic, 08002 Barcelona"
        return poi
    }

    private static func createCasaBatlloPOI() -> TRPPoi {
        var poi = TRPPoi(
            id: "poi_casa_batllo",
            cityId: 109,
            name: "Casa Batlló",
            image: TRPImage(url: "https://example.com/casa_batllo.jpg", width: 1000, height: 667),
            icon: "attraction",
            coordinate: TRPLocation(lat: 41.3916, lon: 2.1649),
            status: true
        )
        poi.description = "Gaudí's architectural masterpiece with dragon-inspired design and stunning modernist details"
        poi.rating = 4.7
        poi.ratingCount = 61234
        poi.address = "Passeig de Gràcia, 43, 08007 Barcelona"
        return poi
    }

    private static func createBarcelonetaBeachPOI() -> TRPPoi {
        var poi = TRPPoi(
            id: "poi_barceloneta_beach",
            cityId: 109,
            name: "Barceloneta Beach",
            image: TRPImage(url: "https://example.com/barceloneta_beach.jpg", width: 1000, height: 667),
            icon: "beach",
            coordinate: TRPLocation(lat: 41.3809, lon: 2.1896),
            status: true
        )
        poi.description = "Popular urban beach with golden sand, beachfront restaurants, and Mediterranean vibes"
        poi.rating = 4.3
        poi.ratingCount = 29876
        poi.address = "Platja de la Barceloneta, 08003 Barcelona"
        return poi
    }

    private static func createPasseigGraciaPOI() -> TRPPoi {
        var poi = TRPPoi(
            id: "poi_passeig_gracia",
            cityId: 109,
            name: "Passeig de Gràcia",
            image: TRPImage(url: "https://example.com/passeig_gracia.jpg", width: 1000, height: 667),
            icon: "attraction",
            coordinate: TRPLocation(lat: 41.3948, lon: 2.1637),
            status: true
        )
        poi.description = "Upscale boulevard with luxury shopping, modernist architecture, and elegant cafes"
        poi.rating = 4.6
        poi.ratingCount = 34567
        poi.address = "Passeig de Gràcia, 08007 Barcelona"
        return poi
    }

    private static func createMontjuicCastlePOI() -> TRPPoi {
        var poi = TRPPoi(
            id: "poi_montjuic_castle",
            cityId: 109,
            name: "Montjuïc Castle",
            image: TRPImage(url: "https://example.com/montjuic_castle.jpg", width: 1000, height: 667),
            icon: "attraction",
            coordinate: TRPLocation(lat: 41.3644, lon: 2.1668),
            status: true
        )
        poi.description = "Historic fortress atop Montjuïc hill with panoramic city and harbor views"
        poi.rating = 4.5
        poi.ratingCount = 28934
        poi.address = "Carretera de Montjuïc, 66, 08038 Barcelona"
        return poi
    }

    private static func createCampNouPOI() -> TRPPoi {
        var poi = TRPPoi(
            id: "poi_camp_nou",
            cityId: 109,
            name: "Camp Nou",
            image: TRPImage(url: "https://example.com/camp_nou.jpg", width: 1000, height: 667),
            icon: "attraction",
            coordinate: TRPLocation(lat: 41.3809, lon: 2.1228),
            status: true
        )
        poi.description = "Iconic FC Barcelona stadium and museum, one of the largest football stadiums in the world"
        poi.rating = 4.7
        poi.ratingCount = 87654
        poi.address = "C. d'Aristides Maillol, 12, 08028 Barcelona"
        return poi
    }
}
