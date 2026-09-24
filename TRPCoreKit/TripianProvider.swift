//
//  TripianProvider.swift
//  TRPCoreKit
//
//  Per-host tour-api content provider. The active provider is global and
//  host-configurable via `TRPCoreKit.shared.provider`; all provider-dependent
//  values (numeric provider id + the activity-id prefix) read it instead of
//  hard-coding a single customer's values. Mirrors the Android `TripianProvider`.
//
//  Defaults to `.civitatis` so the original SDK behavior (id 15, "C_" prefix) is
//  preserved for existing hosts; the Nexus entry switches it to `.nexus` and
//  CruiseGenie to `.getYourGuide`.
//

import Foundation

public enum TripianProvider {
    case civitatis
    case nexus
    case getYourGuide

    /// Numeric tour-api provider id used by product-lookup / availability calls.
    public var id: Int {
        switch self {
        case .civitatis:    return 15
        case .nexus:        return 7   // Juniper
        case .getYourGuide: return 4
        }
    }

    /// Prefix the tour-api uses to wrap a raw product id into a timeline activity
    /// id: `{prefix}{productId}_{id}[_{cityId}]`. Civitatis "C_", Nexus(Juniper) "J_",
    /// GetYourGuide "G_".
    public var activityIdPrefix: String {
        switch self {
        case .civitatis:    return "C_"
        case .nexus:        return "J_"
        case .getYourGuide: return "G_"
        }
    }

    /// Transforms a raw tour-api product id into the id the host's detail / availability
    /// screen expects (applied when an activity detail or reservation is requested).
    ///
    /// Nexus `/get-product` keys on `"{TYPE}|{id}"` (e.g. "TKT|9148") while tour-api
    /// ids are `"{id}¬{TYPE}"` (e.g. "9148¬TKT", ¬ = U+00AC NOT SIGN) — which is what
    /// the tapped segment/step carries. Convert by swapping the two halves around `|`.
    /// Idempotent: ids without the separator (or not in the `{digits}¬{TYPE}` shape)
    /// pass through unchanged. Civitatis and GetYourGuide: identity.
    public var showsActivityCategories: Bool {
        switch self {
        case .civitatis:    return true
        case .nexus:        return false
        case .getYourGuide: return false
        }
    }

    /// Whether a city id the host already resolved is kept as it is. When false every destination
    /// and booked activity is resolved again from its coordinate or product, and booked segments
    /// are sent without a city.
    public var keepsHostCityIds: Bool {
        switch self {
        case .civitatis:    return false
        case .nexus:        return true
        case .getYourGuide: return true
        }
    }

    /// Whether tapping a step of `stepType` asks the host for its product detail rather than
    /// opening the SDK's POI detail. Civitatis sends only activity steps; the others send every
    /// step that is not a plain poi.
    public func opensHostDetail(forStepType stepType: String?) -> Bool {
        switch self {
        case .civitatis:
            return stepType == "activity"
        case .nexus, .getYourGuide:
            return stepType != "poi"
        }
    }

    /// How the timeline map connects the selected day's places.
    public var mapRouteStyle: TRPMapRouteStyle {
        switch self {
        case .civitatis:    return .walkingPerSegment
        case .nexus:        return .dayLegs
        case .getYourGuide: return .none
        }
    }

    /// Whether the timeline map draws the day's route (walking and driving legs)
    /// between its located items.
    public var drawsRoutesOnMap: Bool {
        return mapRouteStyle == .dayLegs
    }

    /// Whether the timeline lists every segment and plan step of a day as one flat,
    /// time-ordered sequence with route legs between consecutive rows, instead of a
    /// smart-recommendations card per itinerary segment.
    public var usesFlatTimeline: Bool {
        switch self {
        case .civitatis:    return false
        case .nexus:        return true
        case .getYourGuide: return true
        }
    }

    /// How the timeline rows' actions behave on a day that has already passed.
    public var pastDayActionStyle: TRPPastDayActionStyle {
        switch self {
        case .civitatis:    return .removalOnly
        case .nexus:        return .readOnly
        case .getYourGuide: return .readOnly
        }
    }

    public func activityDetailId(fromRaw rawId: String) -> String {
        switch self {
        case .civitatis, .getYourGuide:
            return rawId
        case .nexus:
            let separator: Character = "\u{AC}"
            guard rawId.contains(separator) else { return rawId }
            let parts = rawId.split(separator: separator, omittingEmptySubsequences: false).map(String.init)
            guard parts.count == 2,
                  !parts[0].isEmpty, parts[0].allSatisfy({ $0.isNumber }),
                  !parts[1].isEmpty else {
                return rawId
            }
            return "\(parts[1])|\(parts[0])"
        }
    }
}

/// How the timeline map connects a day's places.
public enum TRPMapRouteStyle {
    /// No route lines.
    case none
    /// One walking route through the places of each itinerary segment.
    case walkingPerSegment
    /// The day's located items in order, one route per city, drawn as walking and driving legs.
    case dayLegs
}
