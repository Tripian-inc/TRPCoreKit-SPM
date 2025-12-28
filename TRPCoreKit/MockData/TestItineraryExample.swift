//
//  TestItineraryExample.swift
//  TRPCoreKit
//
//  Created for testing startWithItinerary functionality
//  This file demonstrates how to create a TRPItineraryWithActivities for testing
//

import Foundation
import TRPFoundationKit

/**
 Example helper for testing SDK with itinerary data

 Usage in your test ViewController:

 ```swift
 extension ViewController {
     func openSDKWithItinerary() {
         let tripianNav = UINavigationController()
         tripianNav.modalPresentationStyle = .fullScreen
         let coordinator = TRPSDKCoordinater(navigationController: tripianNav, canBack: true)

         // Create sample itinerary with 2 booked activities and 3-day plan
         let itinerary = TestItineraryExample.create3DayItineraryWith2Activities()

         coordinator.startWithItinerary(itinerary)
         self.present(tripianNav, animated: true, completion: nil)
     }
 }
 ```
 */
public class TestItineraryExample {

    /// Creates a TRPTimelineProfile with 2 booked activities (matches exact API request format)
    /// This method creates the profile directly with segment-level customization
    /// Activity 1: 1 week from today (7 days)
    /// Activity 2: 2 days after first activity (9 days from today)
    public static func createTimelineProfileWith2BookedActivities() -> TRPTimelineProfile {
        let profile = TRPTimelineProfile()

        profile.adults = 1
        profile.children = 0
        profile.pets = 0

        // First activity: 1 week from today at 09:00
        let firstActivityBaseDate = Date().addDay(7) ?? Date()
        let firstActivityStart = firstActivityBaseDate.getDateWithZeroHour().addingTimeInterval(9 * 3600) // 09:00
        let firstActivityEnd = firstActivityBaseDate.getDateWithZeroHour().addingTimeInterval(13 * 3600) // 13:00

        // Second activity: 2 days after first (9 days from today) at 16:00
        let secondActivityBaseDate = Date().addDay(9) ?? Date()
        let secondActivityStart = secondActivityBaseDate.getDateWithZeroHour().addingTimeInterval(16 * 3600) // 16:00
        let secondActivityEnd = secondActivityBaseDate.getDateWithZeroHour().addingTimeInterval(21 * 3600) // 21:00

        // Segment 1: Barcelona Tour (09:00-13:00) - 7 days from today
        let segment1 = TRPTimelineSegment()
        segment1.segmentType = .bookedActivity
        segment1.distinctPlan = true
        segment1.available = false
        segment1.title = "Booking/Activity 1"
        segment1.description = ""
        segment1.startDate = firstActivityStart.toString(format: "yyyy-MM-dd HH:mm")
        segment1.endDate = firstActivityEnd.toString(format: "yyyy-MM-dd HH:mm")
        segment1.coordinate = TRPLocation(lat: 41.38804215422857, lon: 2.1703845185984965)
        segment1.adults = 1
        segment1.children = 0
        segment1.pets = 0

        // Additional data for segment 1
        segment1.additionalData = TRPSegmentActivityItem(
            activityId: "1516123",
            bookingId: "2113",
            title: "Booking/Activity 1",
            imageUrl: "https://d2v9cz8rnpdl6f.cloudfront.net/Place/trialxxxxxxxxxxxxxxxxxxxxxxxxxxx/dce26ca431670f40e4ee546232923704.jpg",
            description: "",
            startDatetime: firstActivityStart.toString(format: "yyyy-MM-dd HH:mm"),
            endDatetime: firstActivityEnd.toString(format: "yyyy-MM-dd HH:mm"),
            coordinate: TRPLocation(lat: 41.38804215422857, lon: 2.1703845185984965),
            cancellation: "Cancelacion gratuita",
            adultCount: 1,
            childCount: 0
        )

        // Segment 2: Madrid Trip (16:00-21:00) - 9 days from today
        let segment2 = TRPTimelineSegment()
        segment2.segmentType = .bookedActivity
        segment2.distinctPlan = true
        segment2.available = false
        segment2.title = "Madrid Day Trip by High-Speed Train"
        segment2.description = "Booked train excursion to Madrid including Royal Palace and Prado Museum"
        segment2.startDate = secondActivityStart.toString(format: "yyyy-MM-dd HH:mm")
        segment2.endDate = secondActivityEnd.toString(format: "yyyy-MM-dd HH:mm")
        segment2.coordinate = TRPLocation(lat: 40.4167754, lon: -3.7037902)
        segment2.adults = 1
        segment2.children = 0
        segment2.pets = 0

        // Additional data for segment 2
        segment2.additionalData = TRPSegmentActivityItem(
            activityId: "TRAIN-MAD-001",
            bookingId: "BOOKING-RENFE-789",
            title: "Madrid Day Trip by High-Speed Train",
            imageUrl: "https://media.tacdn.com/media/attractions-splice-spp-674x446/07/74/e1/dc.jpg",
            description: "Booked train excursion to Madrid including Royal Palace and Prado Museum",
            startDatetime: secondActivityStart.toString(format: "yyyy-MM-dd HH:mm"),
            endDatetime: secondActivityEnd.toString(format: "yyyy-MM-dd HH:mm"),
            coordinate: TRPLocation(lat: 40.4167754, lon: -3.7037902),
            cancellation: "Cancelacion gratuita",
            adultCount: 1,
            childCount: 0
        )

        profile.segments = [segment1, segment2]

        print("\n📝 [TestItineraryExample] Created profile with booked activities:")
        print("   - Total segments: \(profile.segments.count)")
        for (index, segment) in profile.segments.enumerated() {
            print("   - Segment \(index + 1): \(segment.title ?? "Unknown")")
            print("     - Start: \(segment.startDate ?? "nil")")
            print("     - End: \(segment.endDate ?? "nil")")
            print("     - Type: \(segment.segmentType.rawValue)")
        }

        // Add 2 favourite items
        var favouriteItems: [TRPSegmentFavoriteItem] = []

        let sagradaFamilia = TRPSegmentFavoriteItem(
            activityId: nil,
            title: "Sagrada Familia",
            photoUrl: "https://media.tacdn.com/media/attractions-splice-spp-674x446/06/6f/5e/52.jpg",
            description: "Antoni Gaudí's unfinished masterpiece and iconic Barcelona landmark",
            activityUrl: nil,
            coordinate: "41.4036,2.1744",
            rating: 4.8,
            ratingCount: 87654,
            cancellation: nil,
            price: nil,
            locations: nil
        )
        favouriteItems.append(sagradaFamilia)

        let parkGuell = TRPSegmentFavoriteItem(
            activityId: nil,
            title: "Park Güell",
            photoUrl: "https://media.tacdn.com/media/attractions-splice-spp-674x446/09/91/2a/5f.jpg",
            description: "Gaudí's colorful park with stunning mosaic art and city views",
            activityUrl: nil,
            coordinate: "41.4145,2.1527",
            rating: 4.6,
            ratingCount: 52341,
            cancellation: nil,
            price: nil,
            locations: nil
        )
        favouriteItems.append(parkGuell)

        profile.favouriteItems = favouriteItems

        return profile
    }

    /// Creates an itinerary with 2 booked activities (matches API request format)
    /// - Activity 1: Barcelona Tour (09:00-13:00) - 1 week from today
    /// - Activity 2: Madrid Day Trip by Train (16:00-21:00) - 2 days after first activity
    public static func create3DayItineraryWith2Activities() -> TRPItineraryWithActivities {

        // First activity: 1 week from today at 09:00
        let firstActivityBaseDate = Date().addDay(7) ?? Date()
        let firstActivityStart = firstActivityBaseDate.getDateWithZeroHour().addingTimeInterval(9 * 3600) // 09:00
        let firstActivityEnd = firstActivityBaseDate.getDateWithZeroHour().addingTimeInterval(13 * 3600) // 13:00

        // Second activity: 2 days after first (9 days from today) at 16:00
        let secondActivityBaseDate = Date().addDay(9) ?? Date()
        let secondActivityStart = secondActivityBaseDate.getDateWithZeroHour().addingTimeInterval(16 * 3600) // 16:00
        let secondActivityEnd = secondActivityBaseDate.getDateWithZeroHour().addingTimeInterval(21 * 3600) // 21:00

        // Create destination item (Barcelona)
        let destination = TRPSegmentDestinationItem(
            title: "Barcelona",
            coordinate: "41.3850639,2.1734034999999494"
        )

        // Create 2 booked activities
        var tripItems: [TRPSegmentActivityItem] = []

        // Activity 1: Barcelona Tour (09:00-13:00) - 7 days from today
        let barcelonaTour = TRPSegmentActivityItem(
            activityId: "1516123",
            bookingId: "2113",
            title: "Booking/Activity 1",
            imageUrl: "https://d2v9cz8rnpdl6f.cloudfront.net/Place/trialxxxxxxxxxxxxxxxxxxxxxxxxxxx/dce26ca431670f40e4ee546232923704.jpg",
            description: "",
            startDatetime: firstActivityStart.toString(format: "yyyy-MM-dd HH:mm"),
            endDatetime: firstActivityEnd.toString(format: "yyyy-MM-dd HH:mm"),
            coordinate: TRPLocation(lat: 41.38804215422857, lon: 2.1703845185984965),
            cancellation: "Cancelacion gratuita",
            adultCount: 1,
            childCount: 0
        )
        tripItems.append(barcelonaTour)

        // Activity 2: Madrid Day Trip by High-Speed Train (16:00-21:00) - 9 days from today
        let madridTrip = TRPSegmentActivityItem(
            activityId: "TRAIN-MAD-001",
            bookingId: "BOOKING-RENFE-789",
            title: "Madrid Day Trip by High-Speed Train",
            imageUrl: "https://media.tacdn.com/media/attractions-splice-spp-674x446/07/74/e1/dc.jpg",
            description: "Booked train excursion to Madrid including Royal Palace and Prado Museum",
            startDatetime: secondActivityStart.toString(format: "yyyy-MM-dd HH:mm"),
            endDatetime: secondActivityEnd.toString(format: "yyyy-MM-dd HH:mm"),
            coordinate: TRPLocation(lat: 40.4167754, lon: -3.7037902),
            cancellation: "Cancelacion gratuita",
            adultCount: 1,
            childCount: 0
        )
        tripItems.append(madridTrip)

        // Create 2 favourite items
        var favouriteItems: [TRPSegmentFavoriteItem] = []

        let sagradaFamilia = TRPSegmentFavoriteItem(
            activityId: nil,
            title: "Sagrada Familia",
            photoUrl: "https://media.tacdn.com/media/attractions-splice-spp-674x446/06/6f/5e/52.jpg",
            description: "Antoni Gaudí's unfinished masterpiece and iconic Barcelona landmark",
            activityUrl: nil,
            coordinate: "41.4036,2.1744",
            rating: 4.8,
            ratingCount: 87654,
            cancellation: nil,
            price: nil,
            locations: nil
        )
        favouriteItems.append(sagradaFamilia)

        let parkGuell = TRPSegmentFavoriteItem(
            activityId: nil,
            title: "Park Güell",
            photoUrl: "https://media.tacdn.com/media/attractions-splice-spp-674x446/09/91/2a/5f.jpg",
            description: "Gaudí's colorful park with stunning mosaic art and city views",
            activityUrl: nil,
            coordinate: "41.4145,2.1527",
            rating: 4.6,
            ratingCount: 52341,
            cancellation: nil,
            price: nil,
            locations: nil
        )
        favouriteItems.append(parkGuell)

        // Create itinerary
        let itinerary = TRPItineraryWithActivities(
            tripName: "Barcelona & Madrid Day Trip",
            startDatetime: firstActivityStart.toString(format: "yyyy-MM-dd HH:mm"),
            endDatetime: secondActivityEnd.toString(format: "yyyy-MM-dd HH:mm"),
            uniqueId: "TEST-USER-12345",
            tripianHash: nil, // Will be generated by backend
            destinationItems: [destination],
            favouriteItems: favouriteItems,
            tripItems: tripItems
        )

        return itinerary
    }

    /// Creates a 5-day itinerary with 3 booked activities and favorite items
    public static func create5DayItineraryWith3ActivitiesAndFavorites() -> TRPItineraryWithActivities {

        let startDate = Date().addDay(1) ?? Date()
        let endDate = startDate.addDay(4) ?? startDate

        // Create destination item
        let destination = TRPSegmentDestinationItem(
            title: "Barcelona",
            coordinate: "41.3850639,2.1734034999999494"
        )

        // Create 3 booked activities
        var tripItems: [TRPSegmentActivityItem] = []

        // Activity 1: Park Güell Tour (Day 2, 10:00-12:00)
        let day2Date = startDate.addDay(1) ?? startDate
        let parkGuell = TRPSegmentActivityItem(
            activityId: "9876543",
            bookingId: "BOOKING-PARKGUELL-003",
            title: "Park Güell Guided Tour",
            imageUrl: "https://media.tacdn.com/media/attractions-splice-spp-674x446/09/91/2a/5f.jpg",
            description: "Explore Gaudí's colorful park with mosaic art",
            startDatetime: day2Date.toString(format: "yyyy-MM-dd 10:00:00"),
            endDatetime: day2Date.toString(format: "yyyy-MM-dd 12:00:00"),
            coordinate: TRPLocation(lat: 41.4145, lon: 2.1527),
            cancellation: "Free cancellation up to 24 hours before",
            adultCount: 2,
            childCount: 1
        )
        tripItems.append(parkGuell)

        // Activity 2: Sagrada Familia (Day 3, 14:00-16:30)
        let day3Date = startDate.addDay(2) ?? startDate
        let sagradaFamilia = TRPSegmentActivityItem(
            activityId: "1516123",
            bookingId: "BOOKING-SAGRADA-004",
            title: "Sagrada Familia Guided Tour",
            imageUrl: "https://media.tacdn.com/media/attractions-splice-spp-674x446/06/6f/5e/52.jpg",
            description: "Skip-the-line guided tour of Gaudí's masterpiece",
            startDatetime: day3Date.toString(format: "yyyy-MM-dd 14:00:00"),
            endDatetime: day3Date.toString(format: "yyyy-MM-dd 16:30:00"),
            coordinate: TRPLocation(lat: 41.4036, lon: 2.1744),
            cancellation: "Free cancellation up to 24 hours before",
            adultCount: 2,
            childCount: 1
        )
        tripItems.append(sagradaFamilia)

        // Activity 3: Paella Cooking Class (Day 4, 18:00-21:00) - RESERVED (not yet confirmed)
        let day4Date = startDate.addDay(3) ?? startDate
        let paellaCookingClass = TRPSegmentActivityItem(
            activityId: "PAELLA-CLASS-789",
            bookingId: "RES-PAELLA-005", // Reservation ID
            title: "Paella Cooking Class",
            imageUrl: "https://media.tacdn.com/media/attractions-splice-spp-674x446/09/91/2a/5f.jpg",
            description: "Learn to cook authentic Spanish paella with a local chef",
            startDatetime: day4Date.toString(format: "yyyy-MM-dd 18:00:00"),
            endDatetime: day4Date.toString(format: "yyyy-MM-dd 21:00:00"),
            coordinate: TRPLocation(lat: 41.3874, lon: 2.1686),
            cancellation: "Free cancellation",
            adultCount: 2,
            childCount: 0
        )
        tripItems.append(paellaCookingClass)

        // Create favorite items (places user wants to visit)
        var favouriteItems: [TRPSegmentFavoriteItem] = []

        let gothicQuarter = TRPSegmentFavoriteItem(
            activityId: nil,
            title: "Gothic Quarter",
            photoUrl: "https://example.com/gothic_quarter.jpg",
            description: "Historic medieval neighborhood",
            activityUrl: nil,
            coordinate: "41.3828,2.1764",
            rating: 4.7,
            ratingCount: 45678,
            cancellation: nil,
            price: nil,
            locations: nil
        )
        favouriteItems.append(gothicQuarter)

        let beachBarceloneta = TRPSegmentFavoriteItem(
            activityId: nil,
            title: "Barceloneta Beach",
            photoUrl: "https://example.com/barceloneta_beach.jpg",
            description: "Popular urban beach",
            activityUrl: nil,
            coordinate: "41.3809,2.1896",
            rating: 4.3,
            ratingCount: 29876,
            cancellation: nil,
            price: nil,
            locations: nil
        )
        favouriteItems.append(beachBarceloneta)

        // Create itinerary
        let itinerary = TRPItineraryWithActivities(
            tripName: "Barcelona Family Trip",
            startDatetime: startDate.toString(format: "yyyy-MM-dd HH:mm:ss") ?? "",
            endDatetime: endDate.toString(format: "yyyy-MM-dd HH:mm:ss") ?? "",
            uniqueId: "TEST-USER-12345",
            tripianHash: nil,
            destinationItems: [destination],
            favouriteItems: favouriteItems,
            tripItems: tripItems
        )

        return itinerary
    }
}
