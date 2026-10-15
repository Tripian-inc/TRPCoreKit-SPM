import Foundation

/// Names of the analytics events the SDK emits through
/// `TRPCoreKitDelegate.trpCoreKitDidLogAnalyticsEvent(name:parameters:)`.
/// Names are GA4-compatible (snake_case, max 40 chars) and prefixed with
/// `tripian_` so they never collide with host events.
///
/// Android equivalent: TRPAnalyticsEvent
public enum TRPAnalyticsEvent {
    public static let sdkOpened = "tripian_sdk_opened"
    public static let sdkClosed = "tripian_sdk_closed"
    public static let screenView = "tripian_screen_view"
    public static let error = "tripian_error"

    public static let loginSuccess = "tripian_login_success"
    public static let timelineCreated = "tripian_timeline_created"
    public static let timelineLoaded = "tripian_timeline_loaded"
    public static let timelineDeleted = "tripian_timeline_deleted"
    public static let timelineDayChanged = "tripian_timeline_day_changed"
    public static let timelineReset = "tripian_timeline_reset"
    public static let tripSelected = "tripian_trip_selected"

    public static let citySelected = "tripian_city_selected"
    public static let datesSelected = "tripian_dates_selected"
    public static let startingPointSelected = "tripian_starting_point_selected"

    public static let addPlanOpened = "tripian_add_plan_opened"
    public static let search = "tripian_search"
    public static let filterApplied = "tripian_filter_applied"
    public static let sortApplied = "tripian_sort_applied"

    public static let stepAdded = "tripian_step_added"
    public static let stepRemoved = "tripian_step_removed"
    public static let stepTimeChanged = "tripian_step_time_changed"
    public static let stepReordered = "tripian_step_reordered"
    public static let stepMovedToDay = "tripian_step_moved_to_day"

    public static let favoriteAdded = "tripian_favorite_added"
    public static let favoriteRemoved = "tripian_favorite_removed"

    public static let activityDetailClick = "tripian_activity_detail_click"
    public static let bookingDetailClick = "tripian_booking_detail_click"
    public static let reserveClick = "tripian_reserve_click"
    public static let poiDetailViewed = "tripian_poi_detail_viewed"
    public static let mapOpened = "tripian_map_opened"
    public static let directionsClick = "tripian_directions_click"
    public static let webPageOpened = "tripian_web_page_opened"
}

/// Parameter keys shared by the SDK analytics events.
///
/// Android equivalent: TRPAnalyticsParam
public enum TRPAnalyticsParam {
    public static let screenName = "screen_name"
    public static let entry = "entry"
    public static let source = "source"
    public static let reservationCount = "reservation_count"
    public static let tripHash = "trip_hash"
    public static let cityId = "city_id"
    public static let cityName = "city_name"
    public static let startDate = "start_date"
    public static let endDate = "end_date"
    public static let dayCount = "day_count"
    public static let dayIndex = "day_index"
    public static let itemId = "item_id"
    public static let itemType = "item_type"
    public static let itemName = "item_name"
    public static let listingType = "listing_type"
    public static let query = "query"
    public static let resultCount = "result_count"
    public static let categories = "categories"
    public static let sort = "sort"
    public static let time = "time"
    public static let date = "date"
    public static let errorCode = "error_code"
    public static let errorMessage = "error_message"
    public static let url = "url"
}

/// Screen identifiers reported with `TRPAnalyticsEvent.screenView`.
///
/// Android equivalent: TRPAnalyticsScreen
public enum TRPAnalyticsScreen {
    public static let splash = "tripian_splash"
    public static let myPlans = "tripian_my_plans"
    public static let citySelection = "tripian_city_selection"
    public static let dateSelection = "tripian_date_selection"
    public static let startingPointSelection = "tripian_starting_point_selection"
    public static let timeline = "tripian_timeline"
    public static let addPlan = "tripian_add_plan"
    public static let activityListing = "tripian_activity_listing"
    public static let poiListing = "tripian_poi_listing"
    public static let poiSelection = "tripian_poi_selection"
    public static let poiDetail = "tripian_poi_detail"
    public static let savedPlans = "tripian_saved_plans"
    public static let timeSelection = "tripian_time_selection"
    public static let map = "tripian_map"
    public static let webPage = "tripian_web_page"
    public static let onboarding = "tripian_onboarding"
}

/// Item types reported in `TRPAnalyticsParam.itemType`.
public enum TRPAnalyticsItemType {
    public static let activity = "activity"
    public static let bookedActivity = "booked_activity"
    public static let poi = "poi"
    public static let favorite = "favorite"
    public static let smartRecommendation = "smart_recommendation"
}

/// Single emission point for SDK analytics. Forwards every event to the host
/// through `TRPCoreKit.shared.delegate`; the SDK never talks to an analytics
/// backend itself, so the host decides where events go.
///
/// Android equivalent: TRPAnalytics
enum TRPAnalytics {

    private static let maxStringLength = 100

    /// Emits `event` with `params`; nil values are dropped and string values are
    /// truncated to the GA4 limit of 100 characters.
    static func log(_ event: String, _ params: [String: Any?] = [:]) {
        guard let delegate = TRPCoreKit.shared.delegate else { return }
        var sanitized: [String: Any] = [:]
        for (key, value) in params {
            if let cleaned = sanitize(value) {
                sanitized[key] = cleaned
            }
        }
        delegate.trpCoreKitDidLogAnalyticsEvent(name: event, parameters: sanitized)
    }

    /// Emits a `TRPAnalyticsEvent.screenView` for `screen` with optional extra `params`.
    static func screen(_ screen: String, _ params: [String: Any?] = [:]) {
        var merged = params
        merged[TRPAnalyticsParam.screenName] = screen
        log(TRPAnalyticsEvent.screenView, merged)
    }

    private static func sanitize(_ value: Any?) -> Any? {
        switch value {
        case nil:
            return nil
        case let string as String:
            let trimmed = String(string.prefix(maxStringLength))
            return trimmed.isEmpty ? nil : trimmed
        case let bool as Bool:
            return bool ? 1 : 0
        case let number as NSNumber:
            return number
        case let array as [Any]:
            let joined = array.map { "\($0)" }.joined(separator: ",")
            let trimmed = String(joined.prefix(maxStringLength))
            return trimmed.isEmpty ? nil : trimmed
        case let other?:
            return String("\(other)".prefix(maxStringLength))
        }
    }
}
