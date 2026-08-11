//
//  TRPActivityIdFormat.swift
//  TRPCoreKit
//
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import Foundation

/// Single builder for the API's activity id form. Counterpart to `String.cleanedAsActivityId()`
/// and `String.trp_parsedProviderId()`, which take the same string apart.
internal enum TRPActivityIdFormat {

    static var defaultProviderId: Int { TRPCoreKit.shared.provider.id }

    /// `{prefix}{productId}_{providerId}`, plus `_{cityId}` when known; prefix and default provider
    /// id come from the active `TRPCoreKit.shared.provider` (Civitatis `C_`/15, Nexus `J_`/7).
    /// `activityId` may be plain or already prefixed — it is reduced to its bare product id either way.
    static func make(_ activityId: String,
                     providerId: Int = defaultProviderId,
                     cityId: Int? = nil) -> String {
        var id = "\(TRPCoreKit.shared.provider.activityIdPrefix)\(activityId.cleanedAsActivityId())_\(providerId)"
        if let cityId = cityId {
            id += "_\(cityId)"
        }
        return id
    }
}
