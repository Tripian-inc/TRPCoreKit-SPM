//
//  TRPLocation+Extensions.swift
//  TRPCoreKit
//

import Foundation
import TRPFoundationKit

extension TRPLocation {
    /// True when the coordinate carries no usable position: either both lat/lon are
    /// the `(0, 0)` sentinel used by the data layer for "missing", or the values are
    /// non-finite (NaN / infinity).
    public var isMissingOrZero: Bool {
        return (lat == 0 && lon == 0) || !lat.isFinite || !lon.isFinite
    }
}
