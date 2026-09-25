//
//  TRPTimelineRefreshState.swift
//  TRPDataLayer
//
//  App-wide observable for timeline refresh activity. Any screen can subscribe
//  to know when a segment-generation poll + getTimeline cycle starts and
//  finishes — regardless of which view controller triggered it. This decouples
//  refresh-status awareness from `TRPTimelineItineraryVC`'s delegate, so flows
//  initiated from modal screens (e.g. AddPlanActivityListing) can show their
//  own UX without hijacking the timeline screen's loader.
//
//  Mirrors the existing `ValueObserver<T>` pub/sub pattern used elsewhere in
//  the SDK (e.g. `allSegmentGenerated`, `timeline`, `generationError`).
//
//  Created by Cem Çaygöz on 08.05.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import Foundation

public enum TRPTimelineRefreshStatus {
    case idle
    case refreshing
    case completed
    case failed(Error)
}

public final class TRPTimelineRefreshState {

    public static let shared = TRPTimelineRefreshState()

    /// Observe transitions: `.idle` → `.refreshing` → `.completed` / `.failed`.
    /// Subscribe via `status.addObserver(self) { newStatus in ... }`.
    public let status: ValueObserver<TRPTimelineRefreshStatus> = ValueObserver(.idle)

    private init() {}

    public func setRefreshing() { status.value = .refreshing }
    public func setCompleted()  { status.value = .completed }
    public func setFailed(_ error: Error) { status.value = .failed(error) }
    public func setIdle() { status.value = .idle }
}
