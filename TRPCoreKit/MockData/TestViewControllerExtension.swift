//
//  TestViewControllerExtension.swift
//  TRPCoreKit
//
//  Usage example for your test ViewController
//  Copy these extensions to your test app's ViewController
//

/*

// MARK: - How to use in your test ViewController

import UIKit
import TRPCoreKit

class ViewController: UIViewController {

    var isSDKCalled = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Your setup code
    }

    @IBAction func openSDKButtonTapped(_ sender: Any) {
        loginSDK()
    }
}

// MARK: - Login SDK
extension ViewController {
    func loginSDK() {
        let developmentUrl = "gyssxjfp9d.execute-api.eu-west-1.amazonaws.com"
        let apiKey = "predevNUVQpdicktDseQOxLbLhizyxsk" // dev
        let url = BaseUrlCreater(baseUrl: developmentUrl, basePath: "predev")
        TRPClient.start(baseUrl: url, apiKey: apiKey, language: "en")

        // Call the itinerary-based SDK opening
        self.openSDKWithItinerary()
        isSDKCalled = true
    }
}

// MARK: - Open Tripian SDK with Itinerary
extension ViewController {

    /// Opens SDK with 2 booked activities (matches exact API request format)
    /// This is the RECOMMENDED method to test the SDK with booking data
    func openSDKWithItinerary() {
        let tripianNav = UINavigationController()
        tripianNav.modalPresentationStyle = .fullScreen

        // Create timeline profile with 2 booked activities
        // Activity 1: Barcelona Tour (09:00-13:00) - 7 days from today
        // Activity 2: Madrid Day Trip (16:00-21:00) - 9 days from today
        let profile = TestItineraryExample.createTimelineProfileWith2BookedActivities()

        // Use TRPTimelineCoordinator to start timeline flow directly
        let timelineCoordinator = TRPTimelineCoordinator(navigationController: tripianNav)
        timelineCoordinator.start(with: profile)

        self.present(tripianNav, animated: true, completion: nil)
    }

    /// Opens SDK with existing tripHash (fetch existing timeline without creating new one)
    /// Use this when you already have a tripHash from a previous timeline creation
    /// - Parameter tripHash: The trip hash for the existing timeline
    func openSDKWithExistingTimeline(tripHash: String) {
        let tripianNav = UINavigationController()
        tripianNav.modalPresentationStyle = .fullScreen

        // Use TRPTimelineCoordinator to fetch and display existing timeline
        let timelineCoordinator = TRPTimelineCoordinator(navigationController: tripianNav)
        timelineCoordinator.start(tripHash: tripHash)

        self.present(tripianNav, animated: true, completion: nil)
    }

    /// Alternative: Opens SDK using TRPItineraryWithActivities model
    func openSDKWithItineraryModel() {
        let tripianNav = UINavigationController()
        tripianNav.modalPresentationStyle = .fullScreen
        let coordinator = TRPSDKCoordinater(navigationController: tripianNav, canBack: true)

        // Create itinerary model (segment.title will be same as additionalData.title)
        let itinerary = TestItineraryExample.create3DayItineraryWith2Activities()

        // Start SDK with itinerary (will create new timeline)
        coordinator.startWithItinerary(itinerary)

        self.present(tripianNav, animated: true, completion: nil)
    }

    /// Opens SDK using TRPItineraryWithActivities model with existing tripHash
    /// Use this when you already have a tripHash from a previous timeline creation
    /// - Parameter tripHash: The trip hash for the existing timeline
    func openSDKWithItineraryModelAndTripHash(tripHash: String) {
        let tripianNav = UINavigationController()
        tripianNav.modalPresentationStyle = .fullScreen
        let coordinator = TRPSDKCoordinater(navigationController: tripianNav, canBack: true)

        // Create itinerary model (required for uniqueId, even though we're using tripHash)
        let itinerary = TestItineraryExample.create3DayItineraryWith2Activities()

        // Start SDK with existing tripHash (will fetch existing timeline instead of creating new one)
        coordinator.startWithItinerary(itinerary, tripHash: tripHash)

        self.present(tripianNav, animated: true, completion: nil)
    }

    /// Alternative: Opens SDK with a 5-day itinerary including 3 activities and favorites
    func openSDKWithExtendedItinerary() {
        let tripianNav = UINavigationController()
        tripianNav.modalPresentationStyle = .fullScreen
        let coordinator = TRPSDKCoordinater(navigationController: tripianNav, canBack: true)

        // Create sample itinerary with 3 booked activities, 5-day plan, and favorite places
        let itinerary = TestItineraryExample.create5DayItineraryWith3ActivitiesAndFavorites()

        coordinator.startWithItinerary(itinerary)

        self.present(tripianNav, animated: true, completion: nil)
    }

    /// Original method - Opens SDK without itinerary data (normal flow)
    private func openSDK() {
        let tripianNav = UINavigationController()
        tripianNav.modalPresentationStyle = .fullScreen
        let coordinator = TRPSDKCoordinater(navigationController: tripianNav, canBack: true)
        coordinator.startForGuest(uniqueId: "15224")
        self.present(tripianNav, animated: true, completion: nil)
    }
}

// MARK: - Quick Test Buttons (Optional)
extension ViewController {

    /// Add these buttons to your storyboard and connect them

    @IBAction func testWithItineraryButtonTapped(_ sender: Any) {
        loginSDK()
        // This will automatically call openSDKWithItinerary()
    }

    @IBAction func testWithExtendedItineraryButtonTapped(_ sender: Any) {
        let developmentUrl = "gyssxjfp9d.execute-api.eu-west-1.amazonaws.com"
        let apiKey = "predevNUVQpdicktDseQOxLbLhizyxsk"
        let url = BaseUrlCreater(baseUrl: developmentUrl, basePath: "predev")
        TRPClient.start(baseUrl: url, apiKey: apiKey, language: "en")

        openSDKWithExtendedItinerary()
    }

    @IBAction func testNormalFlowButtonTapped(_ sender: Any) {
        let developmentUrl = "gyssxjfp9d.execute-api.eu-west-1.amazonaws.com"
        let apiKey = "predevNUVQpdicktDseQOxLbLhizyxsk"
        let url = BaseUrlCreater(baseUrl: developmentUrl, basePath: "predev")
        TRPClient.start(baseUrl: url, apiKey: apiKey, language: "en")

        openSDK()
    }

    @IBAction func testWithExistingTripHashButtonTapped(_ sender: Any) {
        let developmentUrl = "gyssxjfp9d.execute-api.eu-west-1.amazonaws.com"
        let apiKey = "predevNUVQpdicktDseQOxLbLhizyxsk"
        let url = BaseUrlCreater(baseUrl: developmentUrl, basePath: "predev")
        TRPClient.start(baseUrl: url, apiKey: apiKey, language: "en")

        // Replace with your actual tripHash from a previous timeline creation
        let tripHash = "YOUR_TRIP_HASH_HERE"
        openSDKWithExistingTimeline(tripHash: tripHash)
    }

    @IBAction func testWithItineraryAndTripHashButtonTapped(_ sender: Any) {
        let developmentUrl = "gyssxjfp9d.execute-api.eu-west-1.amazonaws.com"
        let apiKey = "predevNUVQpdicktDseQOxLbLhizyxsk"
        let url = BaseUrlCreater(baseUrl: developmentUrl, basePath: "predev")
        TRPClient.start(baseUrl: url, apiKey: apiKey, language: "en")

        // Replace with your actual tripHash from a previous timeline creation
        let tripHash = "YOUR_TRIP_HASH_HERE"
        openSDKWithItineraryModelAndTripHash(tripHash: tripHash)
    }
}

*/
