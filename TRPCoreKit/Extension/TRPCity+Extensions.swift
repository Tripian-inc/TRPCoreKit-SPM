//
//  TRPCity+Extensions.swift
//  TRPCoreKit
//

import Foundation
import TRPFoundationKit

extension TRPCity {
    /// Returns a usable coordinate for this city. When the city instance itself was
    /// built as a placeholder with `(0, 0)` (e.g. via the booked-activity merge path
    /// in `createSegmentProfileFromTripItem`), falls back to `TRPCityCache` by id.
    /// Returns `nil` only when neither the city nor the cache has a real coordinate.
    public func resolvedCoordinate() -> TRPLocation? {
        if !coordinate.isMissingOrZero {
            return coordinate
        }
        if id > 0,
           let cached = TRPCityCache.shared.getCity(byId: id),
           !cached.coordinate.isMissingOrZero {
            return cached.coordinate
        }
        return nil
    }
}
