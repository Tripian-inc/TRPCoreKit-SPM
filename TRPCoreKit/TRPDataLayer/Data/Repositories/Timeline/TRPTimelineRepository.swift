//
//  TRPTimelineRepository.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 17.08.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import Foundation
final public class TRPTimelineRepository: TimelineRepository {
    
    private(set) var remoteApi: TimelineRemoteApi
    
    private(set) var localStorage: TimelineLocalStorage
    
    public init(remoteApi: TimelineRemoteApi = TRPTimelineRemoteApi(),
                localStorage: TimelineLocalStorage = TRPTimelineLocalStorage()) {
        self.remoteApi = remoteApi
        self.localStorage = localStorage
    }
    
    public func fetchTimeline(tripHash: String, completion: @escaping (TimelineResultValue) -> Void) {
        remoteApi.fetchTimeline(tripHash: tripHash, completion: completion)
    }
    
    public func createTimeline(profile: TRPTimelineProfile, completion: @escaping (TimelineResultValue) -> Void) {
        remoteApi.createTimeline(profile: profile, completion: completion)
    }
    
    public func createEditTimelineSegment(profile: TRPCreateEditTimelineSegmentProfile, completion: @escaping (TimelineResultStatus) -> Void) {
        remoteApi.createEditTimelineSegment(profile: profile, completion: completion)
    }
    
    public func deleteTimeline(tripHash: String, completion: @escaping (TimelineResultStatus) -> Void) {
        remoteApi.deleteTimeline(tripHash: tripHash, completion: completion)
    }
    
    public func deleteTimelineSegment(tripHash: String, segmentIndex: Int, completion: @escaping (TimelineResultStatus) -> Void) {
        remoteApi.deleteTimelineSegment(tripHash: tripHash, segmentIndex: segmentIndex, completion: completion)
    }
    
    public func fetchLocalTimeline(tripHash: String, completion: @escaping (TimelineResultValue) -> Void) {
        localStorage.fetchTimeline(tripHash: tripHash, completion: completion)
    }
    
    public func saveTimeline(tripHash: String, data: TRPTimeline) {
        localStorage.saveTimeline(tripHash: tripHash, data: data)
    }
    
    
}
