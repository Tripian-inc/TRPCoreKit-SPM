//
//  TimelineRemoteApi.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 08.08.2025.
//  Copyright © 2025 Cem Çaygöz. All rights reserved.
//

import Foundation
public protocol TimelineRemoteApi {
       
    func createTimeline(profile: TRPTimelineProfile,
                        completion: @escaping (TimelineResultValue) -> Void)
       
    func createEditTimelineSegment(profile: TRPCreateEditTimelineSegmentProfile,
                                   completion: @escaping (TimelineResultStatus) -> Void)
    
    func fetchTimeline(tripHash: String,
                       completion: @escaping (TimelineResultValue) -> Void)
    
    func deleteTimeline(tripHash: String,
                        completion: @escaping (TimelineResultStatus) -> Void)
    
    func deleteTimelineSegment(tripHash: String,
                               segmentIndex: Int,
                               completion: @escaping (TimelineResultStatus) -> Void)
       
}
