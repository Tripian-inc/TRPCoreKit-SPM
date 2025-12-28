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

    /// Called when a timeline has been successfully created
    /// - Parameter tripHash: The trip hash of the newly created timeline
    func trpCoreKitDidCreateTimeline(tripHash: String)
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
    ///   - delegate: Delegate to receive SDK callbacks
    public static func initialize(
        environment: TRPEnvironment,
        apiKey: String,
        language: String = "en",
        delegate: TRPCoreKitDelegate? = nil
    ) {
        // Set delegate
        shared.delegate = delegate

        // Initialize TRPClient (RestKit)
        let baseUrl = environment.baseUrlCreater
        TRPClient.start(baseUrl: baseUrl, apiKey: apiKey, language: language)

        print("🚀 [TRPCoreKit] SDK initialized - Environment: \(environment.displayName), Language: \(language)")
    }

    /// Initialize TRPCoreKit SDK with custom base URL (for advanced use cases)
    /// - Parameters:
    ///   - baseUrl: Base URL for the API
    ///   - basePath: Base path for the API
    ///   - apiKey: API key for authentication
    ///   - language: Language code (e.g., "en", "es", "tr"). Defaults to "en"
    ///   - delegate: Delegate to receive SDK callbacks
    public static func initialize(
        baseUrl: String,
        basePath: String,
        apiKey: String,
        language: String = "en",
        delegate: TRPCoreKitDelegate? = nil
    ) {
        // Set delegate
        shared.delegate = delegate

        // Initialize TRPClient (RestKit)
        let url = BaseUrlCreater(baseUrl: baseUrl, basePath: basePath)
        TRPClient.start(baseUrl: url, apiKey: apiKey, language: language)

        print("🚀 [TRPCoreKit] SDK initialized - Custom URL: \(baseUrl)/\(basePath), Language: \(language)")
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

        print("🚀 [TRPCoreKit] SDK started for guest user: \(uniqueId)")
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

        print("🚀 [TRPCoreKit] SDK started with email: \(email)")
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

        print("🚀 [TRPCoreKit] SDK started with email and password")
    }

    /// Start SDK with itinerary model (creates or fetches timeline)
    /// - Parameters:
    ///   - itinerary: Itinerary model with activities and trip details
    ///   - tripHash: Optional trip hash. If provided, fetches existing timeline instead of creating new one
    ///   - viewController: View controller to present SDK from
    ///   - canBack: Whether back button is enabled. Defaults to true
    public static func startWithItinerary(
        _ itinerary: TRPItineraryWithActivities,
        tripHash: String? = nil,
        from viewController: UIViewController,
        canBack: Bool = true
    ) {
        let tripianNav = UINavigationController()
        tripianNav.modalPresentationStyle = .fullScreen

        let coordinator = TRPSDKCoordinater(navigationController: tripianNav, canBack: canBack)
        shared.sdkCoordinator = coordinator

        coordinator.startWithItinerary(itinerary, tripHash: tripHash)
        viewController.present(tripianNav, animated: true)

        if let tripHash = tripHash {
            print("🚀 [TRPCoreKit] SDK started with itinerary and tripHash: \(tripHash)")
        } else {
            print("🚀 [TRPCoreKit] SDK started with itinerary (will create new timeline)")
        }
    }

    /// Dismiss SDK
    /// - Parameter animated: Whether to animate dismissal. Defaults to true
    public static func dismiss(animated: Bool = true) {
        shared.sdkCoordinator?.remove()
        shared.sdkCoordinator = nil
        print("🚀 [TRPCoreKit] SDK dismissed")
    }
}
