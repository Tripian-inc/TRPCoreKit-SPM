import Foundation

public struct TripianNavigateParams {
    public let type: String
    public let locator: String?
    public let detailURL: String?
    public let productId: String?
    public let date: String?

    public init(type: String, locator: String? = nil, detailURL: String? = nil, productId: String? = nil, date: String? = nil) {
        self.type = type
        self.locator = locator
        self.detailURL = detailURL
        self.productId = productId
        self.date = date
    }
}

/// Bridge between the SDK and a host app (e.g. the Nexus Capacitor plugin).
///
/// The host assigns `onNavigate`; the bridge then installs itself as
/// `TRPCoreKit.shared.delegate` and translates the SDK's already-wired tap /
/// booking / reservation callbacks into `TripianNavigateParams`. Assigning `nil`
/// removes the delegate. Mirrors the Android `TripianNavigateBridge`.
public class TripianNavigateBridge {

    // These string values are the CONTRACT with the host web layer
    // (useTripianActivity payload.type). Keep them in sync with the web handlers:
    //   "product"      → /product-detail/:productId
    //   "booking"      → My Trips, opened by Locator (modal / detail URL)
    //   "availability" → /availability?product=…&date=…
    public static let typeActivityDetail = "product"
    public static let typeBookingDetail = "booking"
    public static let typeActivityReservation = "availability"

    public static let shared = TripianNavigateBridge()

    /// Host navigation callback. Assigning a non-nil value installs this bridge as
    /// TRPCoreKit's delegate so taps inside the timeline drive `onNavigate`;
    /// assigning nil removes it.
    public var onNavigate: ((TripianNavigateParams) -> Void)? {
        didSet {
            TRPCoreKit.shared.delegate = (onNavigate != nil) ? self : nil
        }
    }

    private init() {}

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// MARK: - TRPCoreKitDelegate
extension TripianNavigateBridge: TRPCoreKitDelegate {

    public func trpCoreKitDidRequestActivityDetail(activityId: String) {
        // reserved_activity / POI detail → host opens the product detail. The raw
        // tour-api id is mapped to the host's detail-screen id (Nexus "{id}¬{TYPE}"
        // → "{TYPE}|{id}"; Civitatis identity).
        let productId = TRPCoreKit.shared.provider.activityDetailId(fromRaw: activityId)
        onNavigate?(TripianNavigateParams(type: Self.typeActivityDetail, productId: productId))
    }

    public func trpCoreKitDidRequestBookingDetail(bookingId: String) {
        // booked_activity → host opens the booking by its locator (no id transform).
        onNavigate?(TripianNavigateParams(type: Self.typeBookingDetail, locator: bookingId, productId: bookingId))
    }

    public func trpCoreKitDidRequestActivityReservation(activityId: String, date: Date) {
        // Reserve / Book → host opens availability for the product on the given day.
        // Same id transform as activity detail.
        let productId = TRPCoreKit.shared.provider.activityDetailId(fromRaw: activityId)
        onNavigate?(TripianNavigateParams(type: Self.typeActivityReservation,
                                          productId: productId,
                                          date: Self.dateFormatter.string(from: date)))
    }

    public func trpCoreKitDidCreateTimeline(tripHash: String) {
        // No navigation; the Nexus create path persists the hash via NexusTripStore.
    }
}
