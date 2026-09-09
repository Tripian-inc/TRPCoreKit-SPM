//
//  TRPTimelineSegment+Location.swift
//  TRPCoreKit
//

import Foundation
import TRPFoundationKit

extension TRPTimelineSegment {

    /// Whether an activity segment has no real-world coordinate: either flagged `isNoLocation`
    /// by the client that created it, or carrying no usable coordinate at all.
    public var hasNoLocation: Bool {
        if additionalData?.isNoLocation == true { return true }
        guard let coordinate = additionalData?.coordinate ?? coordinate else { return true }
        return coordinate.isMissingOrZero
    }
}
