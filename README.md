# Tripian Core Kit

Tripian Core Kit is the official iOS SDK by [Tripian](https://www.tripian.com) for integrating AI-powered travel planning features into your iOS application.

## Features

- **AI-Powered Itinerary Planning** - Smart recommendations based on user preferences
- **Multi-Day Trip Planning** - Plan trips with multiple destinations
- **Activity Booking Integration** - Seamlessly integrate with your booking system
- **Interactive Maps** - Mapbox-powered maps with route visualization
- **Offline Support** - Core features work without internet
- **Localization** - Support for multiple languages (EN, ES, TR, DE, FR)

## Requirements

- iOS 14.0+
- Xcode 14.0+
- Swift 5.0+

## Installation

### Swift Package Manager

Add Tripian Core Kit to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Tripian-inc/TRPCoreKit-SPM.git", branch: "main")
]
```

Or in Xcode: **File → Add Package Dependencies** → Enter repository URL

## Quick Start

```swift
import TRPCoreKit

// 1. Initialize SDK (in AppDelegate)
TRPCoreKit.initialize(
    environment: .production,
    apiKey: "YOUR_API_KEY",
    language: "en",
    delegate: self
)

// 2. Start SDK with itinerary
let destination = TRPSegmentDestinationItem(
    title: "Barcelona",
    coordinate: "41.3851,2.1734",
    cityId: 109
)

let itinerary = TRPItineraryWithActivities(
    tripName: "My Trip",
    startDatetime: "2025-01-15 09:00",
    endDatetime: "2025-01-18 18:00",
    uniqueId: "user-123",
    tripianHash: nil,
    destinationItems: [destination],
    favouriteItems: nil,
    tripItems: nil
)

// Start with new itinerary
TRPCoreKit.startWithItinerary(itinerary, from: self)

// Or reopen existing timeline with tripHash
// TRPCoreKit.startWithItinerary(itinerary, tripHash: "saved-hash", from: self)

// 3. Implement delegate
extension YourVC: TRPCoreKitDelegate {

    func trpCoreKitDidRequestActivityDetail(activityId: String) {
        // User wants to see activity details
    }

    func trpCoreKitDidRequestActivityReservation(activityId: String) {
        // User wants to book/reserve activity
    }

    func trpCoreKitDidCreateTimeline(tripHash: String) {
        // Save tripHash for reopening timeline later
        UserDefaults.standard.set(tripHash, forKey: "tripHash")
    }
}
```

## Configuration

Add required keys to your `Info.plist`:

```xml
<!-- Mapbox Access Token -->
<key>MBXAccessToken</key>
<string>YOUR_MAPBOX_TOKEN</string>

<!-- Google Places API Key -->
<key>TRPGooglePlaceApi</key>
<string>YOUR_GOOGLE_PLACES_KEY</string>

<!-- Location Permission -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show nearby recommendations</string>
```

## Documentation

For complete documentation, see:

- **[TRPCOREKIT_USAGE.md](./TRPCOREKIT_USAGE.md)** - Complete SDK usage guide
- **[API Reference](#api-reference)** - Method and delegate documentation

## API Reference

### Initialization

```swift
// Environment-based (recommended)
TRPCoreKit.initialize(
    environment: .production,  // .predev, .dev, .test, .production
    apiKey: String,
    language: String = "en",
    delegate: TRPCoreKitDelegate? = nil
)

// Custom URL
TRPCoreKit.initialize(
    baseUrl: String,
    basePath: String,
    apiKey: String,
    language: String = "en",
    delegate: TRPCoreKitDelegate? = nil
)
```

### Start Methods

```swift
// With itinerary (recommended)
TRPCoreKit.startWithItinerary(
    _ itinerary: TRPItineraryWithActivities,
    tripHash: String? = nil,
    uniqueId: String? = nil,  // Optional - uses device ID if not provided
    from viewController: UIViewController,
    canBack: Bool = true
)

// Guest user
TRPCoreKit.startForGuest(
    uniqueId: String,
    from viewController: UIViewController,
    canBack: Bool = true
)

// Email
TRPCoreKit.startWithEmail(
    _ email: String,
    from viewController: UIViewController,
    canBack: Bool = true
)

// Email + Password
TRPCoreKit.startWithEmailAndPassword(
    email: String,
    password: String,
    from viewController: UIViewController,
    canBack: Bool = true
)

// Dismiss
TRPCoreKit.dismiss(animated: Bool = true)
```

### Delegate Protocol

```swift
public protocol TRPCoreKitDelegate: AnyObject {

    /// Called when user taps on an activity to view details
    /// - Parameter activityId: Activity identifier
    func trpCoreKitDidRequestActivityDetail(activityId: String)

    /// Called when user wants to book/reserve an activity
    /// - Parameter activityId: Activity identifier
    func trpCoreKitDidRequestActivityReservation(activityId: String)

    /// Called when a new timeline is successfully created
    /// - Parameter tripHash: Unique identifier for the timeline
    func trpCoreKitDidCreateTimeline(tripHash: String)
}
```

### Data Models

#### TRPItineraryWithActivities

Main itinerary model containing trip details and activities.

```swift
public struct TRPItineraryWithActivities {
    var tripName: String?                              // Trip display name
    var startDatetime: String                          // Format: "yyyy-MM-dd HH:mm"
    var endDatetime: String                            // Format: "yyyy-MM-dd HH:mm"
    var uniqueId: String                               // User identifier
    var tripianHash: String?                           // Existing trip hash (for reopening)
    var destinationItems: [TRPSegmentDestinationItem]  // Destinations/cities
    var favouriteItems: [TRPSegmentFavoriteItem]?      // Wishlisted activities
    var tripItems: [TRPSegmentActivityItem]?           // Booked activities
}
```

#### TRPSegmentDestinationItem

Destination (city) information.

```swift
public struct TRPSegmentDestinationItem {
    var title: String           // City name (e.g., "Barcelona")
    var coordinate: String      // Format: "lat,lon" (e.g., "41.3851,2.1734")
    var cityId: Int?            // Tripian city ID (recommended for accuracy)
}
```

#### TRPSegmentActivityItem

Booked activity information.

```swift
public struct TRPSegmentActivityItem {
    var activityId: String?                // Activity identifier
    var bookingId: String?                 // Booking reference ID
    var title: String?                     // Activity title
    var imageUrl: String?                  // Activity image URL
    var description: String?               // Activity description
    var startDatetime: String?             // Format: "yyyy-MM-dd HH:mm"
    var endDatetime: String?               // Format: "yyyy-MM-dd HH:mm"
    var coordinate: TRPLocation            // Activity location (lat/lon)
    var cancellation: String?              // Cancellation policy text
    var adultCount: Int                    // Number of adults (default: 1)
    var childCount: Int                    // Number of children (default: 0)
    var bookingUrl: String?                // URL to view booking details
    var duration: Double?                  // Duration in minutes
    var price: TRPSegmentActivityPrice?    // Price information
    var cityId: Int?                       // Tripian city ID
}
```

#### TRPSegmentFavoriteItem

Wishlisted/saved activity information.

```swift
public struct TRPSegmentFavoriteItem {
    var activityId: String?                // Activity identifier
    var title: String                      // Activity title
    var cityName: String                   // City name
    var cityId: Int?                       // Tripian city ID
    var photoUrl: String?                  // Activity image URL
    var description: String?               // Activity description
    var activityUrl: String?               // URL to activity page
    var coordinate: TRPLocation            // Activity location (lat/lon)
    var rating: Float?                     // Rating (0-5)
    var ratingCount: Int?                  // Number of ratings
    var cancellation: String?              // Cancellation policy text
    var duration: Double?                  // Duration in minutes
    var price: TRPSegmentActivityPrice?    // Price information
    var locations: [String]?               // Meeting point locations
}
```

#### TRPSegmentActivityPrice

Price information for activities.

```swift
public struct TRPSegmentActivityPrice {
    var currency: String    // Currency code (e.g., "USD", "EUR")
    var value: Double       // Price amount
}
```

#### TRPLocation

Location coordinates (from TRPFoundationKit).

```swift
public struct TRPLocation {
    var lat: Double    // Latitude
    var lon: Double    // Longitude
}
```

## Architecture

Tripian Core Kit uses **MVVM-C** (Model-View-ViewModel-Coordinator) architecture:

- **Coordinator Pattern** - Navigation management via `TRPSDKCoordinater`
- **Repository Pattern** - Data access abstraction
- **Observer Pattern** - Reactive state management
- **UseCase Pattern** - Business logic encapsulation

## Dependencies

| Package | Purpose |
|---------|---------|
| TRPRestKit | API communication |
| TRPFoundationKit | Core utilities |
| MapboxMaps | Interactive maps |
| MapboxDirections | Route planning |
| SDWebImage | Image loading |
| Alamofire | Networking |

## Support

- **GitHub Issues**: [TRPCoreKit-SPM Issues](https://github.com/Tripian-inc/TRPCoreKit-SPM/issues)
- **Email**: support@tripian.com
- **Documentation**: [Tripian Developer Portal](https://developer.tripian.com)

## License

Tripian Core Kit is available under the Tripian License. See LICENSE for details.

---

**Last Updated:** January 2026
**SDK Version:** 1.3.x
**Minimum iOS:** 14.0

Built with ❤️ by [Tripian Software Team](https://www.tripian.com/about-us/)
