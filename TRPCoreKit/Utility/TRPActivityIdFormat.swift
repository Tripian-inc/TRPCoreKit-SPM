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

    static let defaultProviderId = 15

    /// `C_{productId}_{providerId}`, plus `_{cityId}` when known. `activityId` may be plain or
    /// already `C_`-prefixed — it is reduced to its bare product id either way.
    static func make(_ activityId: String,
                     providerId: Int = defaultProviderId,
                     cityId: Int? = nil) -> String {
        var id = "C_\(activityId.cleanedAsActivityId())_\(providerId)"
        if let cityId = cityId {
            id += "_\(cityId)"
        }
        return id
    }
}
