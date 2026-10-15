//
//  TRPTimelineItineraryVC+Analytics.swift
//  TRPCoreKit
//

import Foundation

/// Timeline-scoped analytics helpers; every event carries the trip hash and the selected day.
extension TRPTimelineItineraryVC {

    internal func logTimelineEvent(_ event: String, _ params: [String: Any?] = [:]) {
        var merged: [String: Any?] = [
            TRPAnalyticsParam.screenName: TRPAnalyticsScreen.timeline,
            TRPAnalyticsParam.tripHash: viewModel.getTripHash(),
            TRPAnalyticsParam.dayIndex: viewModel.selectedDayIndex
        ]
        params.forEach { merged[$0.key] = $0.value }
        TRPAnalytics.log(event, merged)
    }

    internal func logSegmentClick(_ event: String, segment: TRPTimelineSegment, itemId: String?, source: String? = nil) {
        logTimelineEvent(event, [
            TRPAnalyticsParam.itemId: itemId,
            TRPAnalyticsParam.itemType: segment.segmentType == .bookedActivity ? TRPAnalyticsItemType.bookedActivity : TRPAnalyticsItemType.activity,
            TRPAnalyticsParam.itemName: segment.title,
            TRPAnalyticsParam.source: source
        ])
    }

    internal func logStepClick(_ event: String, step: TRPTimelineStep, itemId: String?, source: String? = nil) {
        logTimelineEvent(event, [
            TRPAnalyticsParam.itemId: itemId,
            TRPAnalyticsParam.itemType: step.stepType == "poi" ? TRPAnalyticsItemType.poi : TRPAnalyticsItemType.activity,
            TRPAnalyticsParam.itemName: step.poi?.name,
            TRPAnalyticsParam.source: source
        ])
    }
}
