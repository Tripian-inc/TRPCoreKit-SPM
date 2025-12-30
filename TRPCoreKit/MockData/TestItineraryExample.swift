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

        // Create destination items (Barcelona and Madrid)
        let barcelonaDestination = TRPSegmentDestinationItem(
            title: "Barcelona",
            coordinate: "41.3850639,2.1734034999999494",
            cityId: 109
        )

        let madridDestination = TRPSegmentDestinationItem(
            title: "Madrid",
            coordinate: "40.4167754,-3.7037902",
            cityId: 45
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
            activityId: "101069",
            title: "Sagrada Familia Private Tour",
            cityName: "Barcelona",
            photoUrl: "https://cdn2.civitatis.com/espana/barcelona/tour-privado-sagrada-familia.jpg",
            description: "The Sagrada Familia is one of the most emblematic symbols of Barcelona. Discover the history and architecture of Gaudí's unfinished masterpiece with this private tour just for you and your partner, family or friends.\n\nDescription\n\nAt the scheduled time, we'll begin our&nbsp;private tour of Barcelona's Sagrada Familia&nbsp;meeting at&nbsp;416 Mallorca Street.\n\nWe will first take in the breathtaking exterior architecture designed by&nbsp;Antonio Gaudí. The building&nbsp;features many details that often go unnoticed, such as the meaning of the magic square and the scenes from the life of Christ represented by the sculptures. Our English-speaking guide will reveal all while we admire the Nativity, Passion and Glory façades.\n\nNext, we'll visit the interior of the Sagrada Familia. Inside, you will see the stunning illuminations through its colourful stained glass windows on both sides of the central nave. We'll then&nbsp;go down to the crypt, which includes the chapels of Saint Joseph, Our Lady of Montserrat, and El Carmen, where Gaudí is buried.\n\nThe basilica also houses the Sagrada Familia Museum, through which we'll learn more about Gaudí's work and the architectural evolution of this still unfinished church, whose construction began in 1882.\n\nAfter an hour and a half, our private tour will conclude at one of the entrances of the Sagrada Familia, allowing you to continue visiting the monument at your leisure.\n\nVisit the&nbsp;Sagrada Familia without queues\n\nIf you'd prefer to skip the queues, you can book a&nbsp;guided group tour of the Sagrada Familia without queues, sharing the experience with other travellers in addition to your guide.",
            activityUrl: "https://tripian.com/redirect.html?data=eyJ0aW1lc3RhbXAiOiIyMDI1LTEyLTI5VDIxOjQ0OjExLjE3NTg4OFoiLCJhcGlfZW52IjoiZGV2IiwiYXBpa2V5IjoicHJlZGV2TlVWUXBkaWNrdERzZVFPeExiTGhpenl4c2siLCJ1c2VyX2lkIjowLCJldmVudF90eXBlIjoidG91cl9jbGljayIsImFjdGlvbl9hcmVhIjoidG91cmFwaSIsImNvbnRleHQiOnsidXJsIjoiaHR0cHM6Ly9jaXZpdGF0aXMuY29tL2VuL2JhcmNlbG9uYS9zYWdyYWRhLWZhbWlsaWEtcHJpdmF0ZS10b3VyIn19&sig=c705d1d1ea3d91b35a61354f09b79f4c33e8ce45b9016944ab1253a5b54328b7",
            coordinate: TRPLocation(lat: 41.4032, lon: 2.17556),
            rating: 3.5,
            ratingCount: 6,
            cancellation: "full_refundable",
            duration: 90.0,
            price: TRPSegmentActivityPrice(currency: "USD", value: 334.39),
            locations: nil
        )
        favouriteItems.append(sagradaFamilia)

        let parkGuell = TRPSegmentFavoriteItem(
            activityId: "100832",
            title: "Barcelona Free Walking Tour",
            cityName: "Barcelona",
            photoUrl: "https://cdn2.civitatis.com/espana/cambrils/bautismo-buceo-cambrils.jpg",
            description: "Get started in the exciting sport of scuba diving with this beginner's activity in Cambrils. This is the perfect introduction to this fantastic world of aquatic adventuring.\n\nBeginner's Scuba Dive in Cambrils\n\nAt the time you choose, we will meet up at the dive center in Cambrils. There, you will meet your instructor who will explain basic notions and techniques to begin diving.\n\nAfter learning these fundamental concepts, we will put on our wetsuits and walk to the shore, where we will don the rest of the equipment and enter the ocean waters.\n\nWe will submerge ourselves, little by little, while the instructor guides us. You will soon be breathing underwater!\n\nFor around 40 minutes, depending on air consumption, we will enjoy exploring the exotic seabed of Cambrils while looking for its inhabitants.\n\nAfter this unique experience, we will return to the dive center.",
            activityUrl: "https://tripian.com/redirect.html?data=eyJ0aW1lc3RhbXAiOiIyMDI1LTEyLTI5VDIxOjM1OjM3LjAwMjYxOVoiLCJhcGlfZW52IjoiZGV2IiwiYXBpa2V5IjoicHJlZGV2TlVWUXBkaWNrdERzZVFPeExiTGhpenl4c2siLCJ1c2VyX2lkIjowLCJldmVudF90eXBlIjoidG91cl9jbGljayIsImFjdGlvbl9hcmVhIjoidG91cmFwaSIsImNvbnRleHQiOnsidXJsIjoiaHR0cHM6Ly9jaXZpdGF0aXMuY29tL2VuL3Nvbi14b3JpZ3Vlci9tZW5vcmNhLXBhZGktb3Blbi13YXRlci1kaXZpbmctY291cnNlIn19&sig=addd06ae580a0189a5917e8a24533229dbb6ed4b18169b2521cc4aff82ea35b8",
            coordinate: TRPLocation(lat: 39.9266, lon: 3.84505),
            rating: 5.0,
            ratingCount: 2,
            cancellation: "full_refundable",
            duration: 120.0,
            price: TRPSegmentActivityPrice(currency: "USD", value: 77.89),
            locations: nil
        )
        favouriteItems.append(parkGuell)

        let fav3 = TRPSegmentFavoriteItem(
            activityId: "104141",
            title: "Arribes del Douro Cruise",
            cityName: "Madrid",
            photoUrl: "https://cdn2.civitatis.com/portugal/miranda-de-duero/paseo-barco-arribes-duero.jpg",
            description: "Get started in the exciting sport of scuba diving with this beginner's activity in Cambrils. This is the perfect introduction to this fantastic world of aquatic adventuring.\n\nBeginner's Scuba Dive in Cambrils\n\nAt the time you choose, we will meet up at the dive center in Cambrils. There, you will meet your instructor who will explain basic notions and techniques to begin diving.\n\nAfter learning these fundamental concepts, we will put on our wetsuits and walk to the shore, where we will don the rest of the equipment and enter the ocean waters.\n\nWe will submerge ourselves, little by little, while the instructor guides us. You will soon be breathing underwater!\n\nFor around 40 minutes, depending on air consumption, we will enjoy exploring the exotic seabed of Cambrils while looking for its inhabitants.\n\nAfter this unique experience, we will return to the dive center.",
            activityUrl: "https://tripian.com/redirect.html?data=eyJ0aW1lc3RhbXAiOiIyMDI1LTEyLTI5VDIxOjM1OjM3LjAwMjYxOVoiLCJhcGlfZW52IjoiZGV2IiwiYXBpa2V5IjoicHJlZGV2TlVWUXBkaWNrdERzZVFPeExiTGhpenl4c2siLCJ1c2VyX2lkIjowLCJldmVudF90eXBlIjoidG91cl9jbGljayIsImFjdGlvbl9hcmVhIjoidG91cmFwaSIsImNvbnRleHQiOnsidXJsIjoiaHR0cHM6Ly9jaXZpdGF0aXMuY29tL2VuL3Nvbi14b3JpZ3Vlci9tZW5vcmNhLXBhZGktb3Blbi13YXRlci1kaXZpbmctY291cnNlIn19&sig=addd06ae580a0189a5917e8a24533229dbb6ed4b18169b2521cc4aff82ea35b8",
            coordinate: TRPLocation(lat: 41.4938, lon: -6.26938),
            rating: 0.0,
            ratingCount: 0,
            cancellation: "non_refundable",
            duration: 75,
            price: TRPSegmentActivityPrice(currency: "USD", value: 18.69),
            locations: nil
        )
        favouriteItems.append(fav3)

        // Create itinerary
        let itinerary = TRPItineraryWithActivities(
            tripName: "Barcelona & Madrid Day Trip",
            startDatetime: firstActivityStart.toString(format: "yyyy-MM-dd HH:mm"),
            endDatetime: secondActivityEnd.toString(format: "yyyy-MM-dd HH:mm"),
            uniqueId: "TEST-USER-12345",
            tripianHash: nil, // Will be generated by backend
            destinationItems: [barcelonaDestination, madridDestination],
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
            coordinate: "41.3850639,2.1734034999999494",
            cityId: 109
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
//
//        let gothicQuarter = TRPSegmentFavoriteItem(
//            activityId: nil,
//            title: "Gothic Quarter",
//            photoUrl: "https://example.com/gothic_quarter.jpg",
//            description: "Historic medieval neighborhood",
//            activityUrl: nil,
//            coordinate: "41.3828,2.1764",
//            rating: 4.7,
//            ratingCount: 45678,
//            cancellation: nil,
//            price: nil,
//            locations: nil
//        )
//        favouriteItems.append(gothicQuarter)
//
//        let beachBarceloneta = TRPSegmentFavoriteItem(
//            activityId: nil,
//            title: "Barceloneta Beach",
//            photoUrl: "https://example.com/barceloneta_beach.jpg",
//            description: "Popular urban beach",
//            activityUrl: nil,
//            coordinate: "41.3809,2.1896",
//            rating: 4.3,
//            ratingCount: 29876,
//            cancellation: nil,
//            price: nil,
//            locations: nil
//        )
//        favouriteItems.append(beachBarceloneta)

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
