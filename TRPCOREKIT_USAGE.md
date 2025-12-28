# TRPCoreKit SDK Usage Guide

TRPCoreKit is the main SDK for integrating Tripian's travel planning features into your iOS application. This guide covers all aspects of SDK integration and usage.

---

## Table of Contents

1. [Installation](#installation)
2. [Quick Start](#quick-start)
3. [SDK Initialization](#sdk-initialization)
4. [Starting the SDK](#starting-the-sdk)
5. [Delegate Callbacks](#delegate-callbacks)
6. [Complete Integration Example](#complete-integration-example)
7. [Advanced Usage](#advanced-usage)
8. [API Reference](#api-reference)

---

## Installation

### Swift Package Manager (SPM)

Add TRPCoreKit to your project via Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/Tripian-inc/TRPCoreKit-SPM.git", branch: "main")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter repository URL
3. Select version/branch
4. Add to your target

---

## Quick Start

The simplest way to integrate TRPCoreKit:

```swift
import UIKit
import TRPCoreKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Initialize SDK
        TRPCoreKit.initialize(
            environment: .predev,
            apiKey: "your-api-key-here",
            language: "en",
            delegate: self
        )
    }

    func openTripianSDK() {
        // 2. Start SDK
        TRPCoreKit.startForGuest(uniqueId: "user123", from: self)
    }
}

// 3. Implement delegate
extension ViewController: TRPCoreKitDelegate {

    func trpCoreKitDidRequestActivityDetail(activityId: String) {
        print("User selected activity: \(activityId)")
        // Open your activity detail screen
    }

    func trpCoreKitDidCreateTimeline(tripHash: String) {
        print("Timeline created: \(tripHash)")
        // Save tripHash, send analytics, etc.
    }
}
```

---

## SDK Initialization

### Environment-based Initialization (Recommended)

Initialize SDK with a predefined environment:

```swift
TRPCoreKit.initialize(
    environment: .predev,      // or .dev, .test, .production
    apiKey: "your-api-key",
    language: "en",            // Optional, defaults to "en"
    delegate: self             // Optional
)
```

**Available Environments:**
- `.predev` - Pre-development environment
- `.dev` - Development environment
- `.test` - Test environment
- `.production` - Production environment

### Custom URL Initialization (Advanced)

For custom API endpoints:

```swift
TRPCoreKit.initialize(
    baseUrl: "your-custom-url.com",
    basePath: "api/v1",
    apiKey: "your-api-key",
    language: "en",
    delegate: self
)
```

### Supported Languages

- `"en"` - English
- `"es"` - Spanish
- `"tr"` - Turkish
- `"de"` - German
- `"fr"` - French

---

## Starting the SDK

TRPCoreKit provides multiple ways to start the SDK based on your use case.

### 1. Guest User

Start SDK for a guest user with a unique identifier:

```swift
TRPCoreKit.startForGuest(
    uniqueId: "user-unique-id",
    from: self,
    canBack: true  // Optional, defaults to true
)
```

**Use Case:** When you want to identify users without requiring login.

---

### 2. Email Authentication

Start SDK with user's email address:

```swift
TRPCoreKit.startWithEmail(
    "user@example.com",
    from: self,
    canBack: true
)
```

**Use Case:** When user is authenticated via email in your system.

---

### 3. Email + Password Authentication

Start SDK with email and password:

```swift
TRPCoreKit.startWithEmailAndPassword(
    email: "user@example.com",
    password: "user-password",
    from: self,
    canBack: true
)
```

**Use Case:** Direct authentication through Tripian's system.

---

### 4. With Itinerary (Create New Timeline)

Start SDK with an itinerary model to create a new timeline:

```swift
let itinerary = TRPItineraryWithActivities(
    uniqueId: "user123",
    cityId: 3,
    cityName: "Barcelona",
    arrivalDate: "2024-01-15",
    departureDate: "2024-01-18",
    numberOfAdults: 2,
    numberOfChildren: 0,
    tripItems: bookedActivities,      // Your booked activities
    favouriteItems: savedActivities   // User's saved items
)

TRPCoreKit.startWithItinerary(
    itinerary,
    from: self
)
```

**Use Case:** When you have booked activities and want to generate a trip itinerary.

---

### 5. With Itinerary + TripHash (Fetch Existing Timeline)

Start SDK with an existing timeline:

```swift
let itinerary = TRPItineraryWithActivities(/* ... */)

TRPCoreKit.startWithItinerary(
    itinerary,
    tripHash: "4cc35bc6235c4d71894325501bfe3ef5",
    from: self
)
```

**Use Case:** When you want to open a previously created timeline.

---

### 6. Dismissing the SDK

Close the SDK programmatically:

```swift
TRPCoreKit.dismiss(animated: true)  // animated parameter is optional
```

---

## Delegate Callbacks

Implement `TRPCoreKitDelegate` to receive callbacks from the SDK.

### Activity Detail Request

Called when user taps on an activity in the activity listing:

```swift
func trpCoreKitDidRequestActivityDetail(activityId: String) {
    print("User wants to see activity: \(activityId)")

    // Option 1: Open your own activity detail screen
    let detailVC = YourActivityDetailVC(activityId: activityId)
    navigationController?.pushViewController(detailVC, animated: true)

    // Option 2: Open external link
    if let url = URL(string: "https://your-app.com/activity/\(activityId)") {
        UIApplication.shared.open(url)
    }
}
```

**Activity ID Format:**
- For tours: `"tour_12345"`
- For custom activities: String identifier from your system

---

### Timeline Created

Called when a new timeline is successfully created:

```swift
func trpCoreKitDidCreateTimeline(tripHash: String) {
    print("New timeline created with hash: \(tripHash)")

    // Save tripHash for future use
    UserDefaults.standard.set(tripHash, forKey: "lastTripHash")

    // Send analytics event
    Analytics.logEvent("timeline_created", parameters: [
        "trip_hash": tripHash,
        "user_id": currentUserId
    ])

    // Show success message
    showSuccessToast("Your itinerary has been created!")
}
```

**TripHash:** Unique identifier for the created timeline. Save this to reopen the timeline later.

---

## Complete Integration Example

Here's a complete example showing all integration points:

```swift
import UIKit
import TRPCoreKit

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // Initialize SDK on app launch
        TRPCoreKit.initialize(
            environment: .production,
            apiKey: "your-production-api-key",
            language: Locale.current.languageCode ?? "en",
            delegate: AppCoordinator.shared
        )

        return true
    }
}

// MARK: - Main View Controller
class TripPlanningViewController: UIViewController {

    @IBAction func planTripButtonTapped(_ sender: UIButton) {
        // Simple: Start with guest user
        TRPCoreKit.startForGuest(
            uniqueId: getUserId(),
            from: self
        )
    }

    @IBAction func viewMyItineraryButtonTapped(_ sender: UIButton) {
        // Open existing timeline
        guard let tripHash = getSavedTripHash() else { return }

        let itinerary = buildItineraryModel()
        TRPCoreKit.startWithItinerary(
            itinerary,
            tripHash: tripHash,
            from: self
        )
    }

    @IBAction func planWithBookingsButtonTapped(_ sender: UIButton) {
        // Create new timeline with booked activities
        let itinerary = buildItineraryWithBookings()
        TRPCoreKit.startWithItinerary(itinerary, from: self)
    }

    // MARK: - Helper Methods

    private func getUserId() -> String {
        return UserDefaults.standard.string(forKey: "userId") ?? UUID().uuidString
    }

    private func getSavedTripHash() -> String? {
        return UserDefaults.standard.string(forKey: "lastTripHash")
    }

    private func buildItineraryModel() -> TRPItineraryWithActivities {
        return TRPItineraryWithActivities(
            uniqueId: getUserId(),
            cityId: 3,
            cityName: "Barcelona",
            arrivalDate: "2024-01-15",
            departureDate: "2024-01-18",
            numberOfAdults: 2,
            numberOfChildren: 1
        )
    }

    private func buildItineraryWithBookings() -> TRPItineraryWithActivities {
        let bookedActivities = getBookedActivitiesFromAPI()

        return TRPItineraryWithActivities(
            uniqueId: getUserId(),
            cityId: 3,
            cityName: "Barcelona",
            arrivalDate: "2024-01-15",
            departureDate: "2024-01-18",
            numberOfAdults: 2,
            numberOfChildren: 1,
            tripItems: bookedActivities,
            favouriteItems: nil
        )
    }

    private func getBookedActivitiesFromAPI() -> [TRPTripItem] {
        // Fetch from your backend
        return []
    }
}

// MARK: - App Coordinator (Delegate Handler)
class AppCoordinator: TRPCoreKitDelegate {

    static let shared = AppCoordinator()
    private init() {}

    // Handle activity detail requests
    func trpCoreKitDidRequestActivityDetail(activityId: String) {
        print("📍 Activity selected: \(activityId)")

        // Option 1: Open in your app
        if let topVC = UIApplication.shared.topViewController() {
            let detailVC = ActivityDetailViewController(activityId: activityId)
            topVC.navigationController?.pushViewController(detailVC, animated: true)
        }

        // Option 2: Open web view
        // let url = "https://your-app.com/activity/\(activityId)"
        // openWebView(url: url)
    }

    // Handle timeline creation
    func trpCoreKitDidCreateTimeline(tripHash: String) {
        print("✅ Timeline created: \(tripHash)")

        // Save tripHash
        UserDefaults.standard.set(tripHash, forKey: "lastTripHash")

        // Sync to backend
        syncTripHashToBackend(tripHash)

        // Send analytics
        Analytics.logEvent("timeline_created", parameters: [
            "trip_hash": tripHash,
            "timestamp": Date().timeIntervalSince1970
        ])

        // Show success notification
        NotificationCenter.default.post(
            name: NSNotification.Name("TimelineCreated"),
            object: nil,
            userInfo: ["tripHash": tripHash]
        )
    }

    private func syncTripHashToBackend(_ tripHash: String) {
        // Call your backend API
        // BackendAPI.saveTripHash(tripHash) { result in ... }
    }
}

// MARK: - Utility Extension
extension UIApplication {
    func topViewController() -> UIViewController? {
        guard let window = windows.first(where: { $0.isKeyWindow }),
              let rootVC = window.rootViewController else {
            return nil
        }

        var topVC = rootVC
        while let presentedVC = topVC.presentedViewController {
            topVC = presentedVC
        }

        return topVC
    }
}
```

---

## Advanced Usage

### Checking SDK Availability

```swift
// Check if SDK is initialized
if TRPCoreKit.shared.delegate != nil {
    print("SDK is ready")
}
```

### Dynamic Language Switching

```swift
// Re-initialize with new language
TRPCoreKit.initialize(
    environment: .production,
    apiKey: apiKey,
    language: "es",  // Switch to Spanish
    delegate: self
)
```

### Error Handling

```swift
func openSDKSafely() {
    guard isNetworkAvailable() else {
        showAlert("No internet connection")
        return
    }

    guard let userId = getUserId(), !userId.isEmpty else {
        showAlert("User not authenticated")
        return
    }

    TRPCoreKit.startForGuest(uniqueId: userId, from: self)
}
```

---

## API Reference

### TRPEnvironment

```swift
public enum TRPEnvironment {
    case predev      // Pre-development
    case dev         // Development
    case test        // Test/Staging
    case production  // Production
}
```

### TRPCoreKit Methods

#### Initialization

```swift
// Environment-based
static func initialize(
    environment: TRPEnvironment,
    apiKey: String,
    language: String = "en",
    delegate: TRPCoreKitDelegate? = nil
)

// Custom URL
static func initialize(
    baseUrl: String,
    basePath: String,
    apiKey: String,
    language: String = "en",
    delegate: TRPCoreKitDelegate? = nil
)
```

#### Start Methods

```swift
// Guest user
static func startForGuest(
    uniqueId: String,
    from viewController: UIViewController,
    canBack: Bool = true
)

// Email
static func startWithEmail(
    _ email: String,
    from viewController: UIViewController,
    canBack: Bool = true
)

// Email + Password
static func startWithEmailAndPassword(
    email: String,
    password: String,
    from viewController: UIViewController,
    canBack: Bool = true
)

// Itinerary
static func startWithItinerary(
    _ itinerary: TRPItineraryWithActivities,
    tripHash: String? = nil,
    from viewController: UIViewController,
    canBack: Bool = true
)

// Dismiss
static func dismiss(animated: Bool = true)
```

### TRPCoreKitDelegate

```swift
public protocol TRPCoreKitDelegate: AnyObject {

    /// Called when user selects an activity
    func trpCoreKitDidRequestActivityDetail(activityId: String)

    /// Called when timeline is created
    func trpCoreKitDidCreateTimeline(tripHash: String)
}
```

---

## Best Practices

1. **Initialize Once**: Call `TRPCoreKit.initialize()` in `AppDelegate` or app startup
2. **Use Environment Enum**: Prefer environment-based initialization over custom URLs
3. **Handle Delegate Callbacks**: Always implement delegate methods to handle user interactions
4. **Save TripHash**: Store tripHash when timeline is created for future access
5. **Error Handling**: Wrap SDK calls in proper error handling
6. **Memory Management**: SDK automatically manages coordinator lifecycle
7. **Testing**: Use `.test` or `.predev` environments for development

---

## Troubleshooting

### SDK Not Starting

```swift
// Ensure SDK is initialized before starting
TRPCoreKit.initialize(environment: .predev, apiKey: "...")
TRPCoreKit.startForGuest(uniqueId: "...", from: self)
```

### Delegate Not Called

```swift
// Make sure delegate is set during initialization
TRPCoreKit.initialize(
    environment: .predev,
    apiKey: "...",
    delegate: self  // ✅ Set delegate here
)

// And implement protocol
extension MyViewController: TRPCoreKitDelegate {
    // Implement methods
}
```

### Build Errors

- Ensure TRPCoreKit is added to your target
- Clean build folder: Cmd+Shift+K
- Update package: Right-click package → Update Package

---

## Support

For issues, questions, or feature requests:
- GitHub Issues: [TRPCoreKit-SPM Issues](https://github.com/Tripian-inc/TRPCoreKit-SPM/issues)
- Email: support@tripian.com
- Documentation: [Tripian Developer Portal](https://developer.tripian.com)

---

## License

TRPCoreKit is available under the Tripian License. See LICENSE file for details.

---

**Last Updated:** December 2024
**SDK Version:** 1.0.0
**Minimum iOS Version:** 14.0
