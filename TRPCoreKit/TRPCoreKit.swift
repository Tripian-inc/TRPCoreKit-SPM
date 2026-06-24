// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import UIKit
import TRPRestKit
import TRPFoundationKit

/// Environment configuration for TRPCoreKit SDK
public enum TRPEnvironment {
    case predev
    case dev
    case test
    case production

    /// Returns the base URL and path for the environment
    internal var baseUrlCreater: BaseUrlCreater {
        switch self {
        case .predev:
            return BaseUrlCreater(baseUrl: "gyssxjfp9d.execute-api.eu-west-1.amazonaws.com", basePath: "predev")
        case .dev:
            return BaseUrlCreater(baseUrl: "gyssxjfp9d.execute-api.eu-west-1.amazonaws.com", basePath: "dev")
        case .test:
            return BaseUrlCreater(baseUrl: "gyssxjfp9d.execute-api.eu-west-1.amazonaws.com", basePath: "test")
        case .production:
            return BaseUrlCreater(baseUrl: "gyssxjfp9d.execute-api.eu-west-1.amazonaws.com", basePath: "prod")
        }
    }

    /// Display name for logging
    internal var displayName: String {
        switch self {
        case .predev: return "PreDev"
        case .dev: return "Dev"
        case .test: return "Test"
        case .production: return "Production"
        }
    }
}

/// Delegate protocol for TRPCoreKit SDK interactions
public protocol TRPCoreKitDelegate: AnyObject {

    /// Called when the SDK needs to open an activity detail screen
    /// - Parameter activityId: The unique identifier of the activity to display
    func trpCoreKitDidRequestActivityDetail(activityId: String)

    /// Called when the SDK needs to open a booking detail screen for an already-booked activity
    /// - Parameter bookingId: The unique identifier of the booking to display
    func trpCoreKitDidRequestBookingDetail(bookingId: String)

    /// Called when the SDK needs to open an activity reservation screen
    /// - Parameters:
    ///   - activityId: The unique identifier of the activity to reserve
    ///   - date: The date and start time of the reservation. Time component reflects
    ///           the source segment/step start time; flexible activities always carry
    ///           a 00:00 time. Falls back to the timeline's selected day at 00:00 when
    ///           no source datetime is available.
    func trpCoreKitDidRequestActivityReservation(activityId: String, date: Date)

    /// Called when a timeline has been successfully created
    /// - Parameter tripHash: The trip hash of the newly created timeline
    func trpCoreKitDidCreateTimeline(tripHash: String)

    /// Called when a user manually adds an activity to the timeline
    /// - Parameter activityId: The unique identifier of the added activity
    func trpCoreKitDidAddActivity(activityId: String)

    /// Called when a user removes a saved (favourited) activity from Saved Plans
    /// - Parameter activityId: The base activity id of the removed favourite (e.g. "15423")
    func trpCoreKitDidRemoveFavorite(activityId: String)

    /// Called when authentication fails (refresh token error)
    /// Host app should dismiss SDK and re-authenticate the user
    func trpCoreKitDidFailWithAuthError()
}

// MARK: - TRPCoreKitDelegate Default Implementations
public extension TRPCoreKitDelegate {
    func trpCoreKitDidFailWithAuthError() {}
    func trpCoreKitDidAddActivity(activityId: String) {}
    func trpCoreKitDidRemoveFavorite(activityId: String) {}
}

public class TRPCoreKit {

    // MARK: - Singleton
    public static let shared = TRPCoreKit()

    // MARK: - Properties
    public weak var delegate: TRPCoreKitDelegate?

    // Keep reference to SDK coordinator
    private var sdkCoordinator: TRPSDKCoordinater?

    // MARK: - Initialization
    private init() {
        // Register fonts
        TRPFonts.registerAll()
    }

    /// Initialize TRPCoreKit SDK with environment configuration
    /// - Parameters:
    ///   - environment: Environment to use (predev, dev, test, production)
    ///   - apiKey: API key for authentication
    ///   - language: Language code (e.g., "en", "es", "tr"). Defaults to "en"
    ///   - currency: Currency code (e.g., "USD", "EUR", "TRY"). Defaults to "USD"
    ///   - delegate: Delegate to receive SDK callbacks
    public static func initialize(
        environment: TRPEnvironment,
        apiKey: String,
        language: String = "en",
        currency: String = "USD",
        delegate: TRPCoreKitDelegate? = nil
    ) {
        // Set delegate
        shared.delegate = delegate

        // Initialize TRPClient (RestKit)
        let baseUrl = environment.baseUrlCreater
        TRPClient.start(baseUrl: baseUrl, apiKey: apiKey, language: language, currency: currency)

        TRPUserAgentURLProtocol.register(host: baseUrl.baseUrl)

        // Prefetch languages - async, non-blocking
        TRPLanguagesController.shared.prefetchLanguagesIfNeeded()
    }

    /// Initialize TRPCoreKit SDK with custom base URL (for advanced use cases)
    /// - Parameters:
    ///   - baseUrl: Base URL for the API
    ///   - basePath: Base path for the API
    ///   - apiKey: API key for authentication
    ///   - language: Language code (e.g., "en", "es", "tr"). Defaults to "en"
    ///   - currency: Currency code (e.g., "USD", "EUR", "TRY"). Defaults to "USD"
    ///   - delegate: Delegate to receive SDK callbacks
    public static func initialize(
        baseUrl: String,
        basePath: String,
        apiKey: String,
        language: String = "en",
        currency: String = "USD",
        delegate: TRPCoreKitDelegate? = nil
    ) {
        // Set delegate
        shared.delegate = delegate

        // Initialize TRPClient (RestKit)
        let url = BaseUrlCreater(baseUrl: baseUrl, basePath: basePath)
        TRPClient.start(baseUrl: url, apiKey: apiKey, language: language, currency: currency)

        TRPUserAgentURLProtocol.register(host: url.baseUrl)

        // Prefetch languages - async, non-blocking
        TRPLanguagesController.shared.prefetchLanguagesIfNeeded()
    }

    // MARK: - Start SDK

    /// Start SDK for guest user
    /// - Parameters:
    ///   - uniqueId: Unique identifier for the guest user
    ///   - viewController: View controller to present SDK from
    ///   - canBack: Whether back button is enabled. Defaults to true
    public static func startForGuest(
        uniqueId: String,
        from viewController: UIViewController,
        canBack: Bool = true
    ) {
        let tripianNav = UINavigationController()
        tripianNav.modalPresentationStyle = .fullScreen

        let coordinator = TRPSDKCoordinater(navigationController: tripianNav, canBack: canBack)
        shared.sdkCoordinator = coordinator

        coordinator.startForGuest(uniqueId: uniqueId)
        viewController.present(tripianNav, animated: true)
    }

    /// Start SDK with email
    /// - Parameters:
    ///   - email: User email address
    ///   - viewController: View controller to present SDK from
    ///   - canBack: Whether back button is enabled. Defaults to true
    public static func startWithEmail(
        _ email: String,
        from viewController: UIViewController,
        canBack: Bool = true
    ) {
        let tripianNav = UINavigationController()
        tripianNav.modalPresentationStyle = .fullScreen

        let coordinator = TRPSDKCoordinater(navigationController: tripianNav, canBack: canBack)
        shared.sdkCoordinator = coordinator

        coordinator.startWithEmail(email)
        viewController.present(tripianNav, animated: true)
    }

    /// Start SDK with email and password
    /// - Parameters:
    ///   - email: User email address
    ///   - password: User password
    ///   - viewController: View controller to present SDK from
    ///   - canBack: Whether back button is enabled. Defaults to true
    public static func startWithEmailAndPassword(
        email: String,
        password: String,
        from viewController: UIViewController,
        canBack: Bool = true
    ) {
        let tripianNav = UINavigationController()
        tripianNav.modalPresentationStyle = .fullScreen

        let coordinator = TRPSDKCoordinater(navigationController: tripianNav, canBack: canBack)
        shared.sdkCoordinator = coordinator

        coordinator.startWithEmailAndPassword(email, password)
        viewController.present(tripianNav, animated: true)
    }

    /// Start SDK with itinerary model (creates or fetches timeline)
    /// - Parameters:
    ///   - itinerary: Itinerary model with activities and trip details
    ///   - tripHash: Optional trip hash. If provided, fetches existing timeline instead of creating new one
    ///   - uniqueId: Optional unique identifier. If not provided, uses device's identifierForVendor
    ///   - viewController: View controller to present SDK from
    ///   - canBack: Whether back button is enabled. Defaults to true
    public static func startWithItinerary(
        _ itinerary: TRPItineraryWithActivities,
        tripHash: String? = nil,
        uniqueId: String? = nil,
        from viewController: UIViewController,
        canBack: Bool = true
    ) {
        let tripianNav = UINavigationController()
        tripianNav.modalPresentationStyle = .fullScreen

        let coordinator = TRPSDKCoordinater(navigationController: tripianNav, canBack: canBack)
        shared.sdkCoordinator = coordinator

        coordinator.startWithItinerary(itinerary, tripHash: tripHash, uniqueId: uniqueId)
        viewController.present(tripianNav, animated: true)
    }

    /// Dismiss SDK
    /// - Parameter animated: Whether to animate dismissal. Defaults to true
    public static func dismiss(animated: Bool = true) {
        shared.sdkCoordinator?.remove()
        shared.sdkCoordinator = nil
    }

    // MARK: - Language & Currency

    /// Change SDK language after initialization
    /// - Parameter language: Language code (e.g., "en", "es", "fr")
    public static func changeLanguage(_ language: String) {
        TRPClient.changeLanguage(language)
        TRPLanguagesController.shared.applyLanguageChange()
    }

    /// Change SDK currency after initialization
    /// - Parameter currency: Currency code (e.g., "USD", "EUR")
    public static func changeCurrency(_ currency: String) {
        TRPClient.changeCurrency(currency)
    }

    /// Get current SDK language
    /// - Returns: Current language code
    public static func getLanguage() -> String {
        return TRPClient.getLanguage()
    }

    /// Get current SDK currency
    /// - Returns: Current currency code
    public static func getCurrency() -> String {
        return TRPClient.getCurrency()
    }
}
