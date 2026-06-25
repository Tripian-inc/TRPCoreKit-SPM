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
//  preserved for existing hosts; the Nexus entry switches it to `.nexus`.
//

import Foundation

public enum TripianProvider {
    case civitatis
    case nexus

    /// Numeric tour-api provider id used by product-lookup / availability calls.
    public var id: Int {
        switch self {
        case .civitatis: return 15
        case .nexus:     return 7   // Juniper
        }
    }

    /// Prefix the tour-api uses to wrap a raw product id into a timeline activity
    /// id: `{prefix}{productId}_{id}[_{cityId}]`. Civitatis "C_", Nexus(Juniper) "J_".
    public var activityIdPrefix: String {
        switch self {
        case .civitatis: return "C_"
        case .nexus:     return "J_"
        }
    }

    /// Transforms a raw tour-api product id into the id the host's detail / availability
    /// screen expects (applied when an activity detail or reservation is requested).
    ///
    /// Nexus `/get-product` keys on `"{TYPE}|{id}"` (e.g. "TKT|9148") while tour-api
    /// ids are `"{id}¬{TYPE}"` (e.g. "9148¬TKT", ¬ = U+00AC NOT SIGN) — which is what
    /// the tapped segment/step carries. Convert by swapping the two halves around `|`.
    /// Idempotent: ids without the separator (or not in the `{digits}¬{TYPE}` shape)
    /// pass through unchanged. Civitatis: identity.
    public var showsActivityCategories: Bool {
        switch self {
        case .civitatis: return true
        case .nexus:     return false
        }
    }

    public func activityDetailId(fromRaw rawId: String) -> String {
        switch self {
        case .civitatis:
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
