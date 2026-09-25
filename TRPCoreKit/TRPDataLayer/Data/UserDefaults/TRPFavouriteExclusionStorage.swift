//
//  TRPFavouriteExclusionStorage.swift
//  TRPCoreKit
//
//  Created by Cem Caygoz on 13.06.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import Foundation

/// Per-tripHash set of base activity ids that the user removed from favourites.
/// Persisted so a removed favourite never reappears in Saved Plans for the same
/// timeline, even across SDK open/close. Ids are stored in base form (`cleanedAsActivityId()`).
struct TRPFavouriteExclusionStorage {

    private static let keyPrefix = "trp_favourite_excluded_"

    private static func key(for tripHash: String) -> String {
        return keyPrefix + tripHash
    }

    static func excludedActivityIds(tripHash: String) -> Set<String> {
        let stored = UserDefaults.standard.stringArray(forKey: key(for: tripHash)) ?? []
        return Set(stored)
    }

    static func addExcludedActivityId(_ baseId: String, tripHash: String) {
        var current = excludedActivityIds(tripHash: tripHash)
        guard current.insert(baseId).inserted else { return }
        UserDefaults.standard.set(Array(current), forKey: key(for: tripHash))
    }
}
