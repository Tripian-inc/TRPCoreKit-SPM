//
//  TRPCreateTimelineFromActivityModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 19.08.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
import TRPFoundationKit
import Foundation

public struct TRPCreateTimelineFromActivityModel {
    var activityId: AnyHashable?
    var title: String?
    var startDate: Date?
    var endDate: Date?
    var city: TRPCity?
    var startCoordinate: TRPLocation?
    var endCoordinate: TRPLocation?
    var description: String?
    
    init(activityId: AnyHashable? = nil, title: String? = nil, description: String? = nil, startDate: Date? = nil, endDate: Date? = nil, city: TRPCity? = nil, startCoordinate: TRPLocation? = nil, endCoordinate: TRPLocation? = nil) {
        self.activityId = activityId
        self.startDate = startDate
        self.endDate = endDate
        self.city = city
        self.startCoordinate = startCoordinate
        self.endCoordinate = endCoordinate
        self.title = title
        self.description = description
    }
}

extension TRPCreateTimelineFromActivityModel {
//    func convertToCreateTimelineModel() -> TRPTimelineProfile {
//        let timeline = TRPTimelineProfile(cityId: nil)
//        
//        timeline.segments = [createSegmentForActivity()]
//        
//        if let startTime = startDate?.getHourInt(), let endTime = endDate?.getHourInt() {
//            if startTime > 9 {
//                timeline.segments.insert(createSegmentForPreActivity(), at: 0)
//            }
//            if endTime < 21 {
//                timeline.segments.append(createSegmentForPostActivity())
//            }
//        }
//        
//        return timeline
//    }
    
    private func createSegmentForActivity() -> TRPTimelineSegment {
        let segment = TRPTimelineSegment()
        segment.title = title
        segment.description = description
        segment.available = false
        if let startDate = startDate?.toString(format: "yyyy-MM-dd HH:mm"),
           let endDate = endDate?.toString(format: "yyyy-MM-dd HH:mm") {
            segment.startDate = startDate
            segment.endDate = endDate
        }
        if let startCoordinate, let endCoordinate {
            segment.coordinate = startCoordinate
            segment.destinationCoordinate = endCoordinate
        }
        
        return segment
    }
    
    private func createSegmentForPreActivity() -> TRPTimelineSegment {
        let segment = TRPTimelineSegment()
        segment.title = "Pre-Activity Plan"
        segment.available = true
        if let date = startDate?.toString(format: "yyyy-MM-dd"), let endDate = startDate?.toString(format: "yyyy-MM-dd HH:mm") {
            segment.startDate = date + " 09:00"
            segment.endDate = endDate
        }
        if let coordinate = startCoordinate {
            segment.destinationCoordinate = coordinate
        }
        return segment
    }
    
    private func createSegmentForPostActivity() -> TRPTimelineSegment {
        let segment = TRPTimelineSegment()
        segment.title = "Post-Activity Plan"
        segment.available = true
        if let startDate = startDate?.toString(format: "yyyy-MM-dd HH:mm"), let endDate = endDate?.toString(format: "yyyy-MM-dd") {
            segment.startDate = startDate
            segment.endDate = endDate + " 21:00"
        }
        if let coordinate = endCoordinate {
            segment.coordinate = coordinate
        }
        return segment
    }
}
