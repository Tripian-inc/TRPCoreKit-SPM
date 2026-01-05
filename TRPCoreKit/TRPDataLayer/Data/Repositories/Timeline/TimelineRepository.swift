//
//  TimelineRepository.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 08.08.2025.
//  Copyright © 2025 Cem Çaygöz. All rights reserved.
//

import Foundation

public typealias TimelineResultValue = (Result<TRPTimeline, Error>)

public typealias TimelineResultStatus = (Result<Bool, Error>)


public protocol TimelineRepository {
    func fetchTimeline(tripHash: String, completion: @escaping (TimelineResultValue) -> Void)
    
    func createTimeline(profile: TRPTimelineProfile, completion: @escaping (TimelineResultValue) -> Void)
    
    func createEditTimelineSegment(profile: TRPCreateEditTimelineSegmentProfile, completion: @escaping (TimelineResultStatus) -> Void)
    
    func deleteTimeline(tripHash: String, completion: @escaping (TimelineResultStatus) -> Void)
    
    func deleteTimelineSegment(tripHash: String, segmentIndex: Int, completion: @escaping (TimelineResultStatus) -> Void)
    
    func fetchLocalTimeline(tripHash: String, completion: @escaping (TimelineResultValue) -> Void)
    
    func saveTimeline(tripHash: String, data: TRPTimeline)
}

