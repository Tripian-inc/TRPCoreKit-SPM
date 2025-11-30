//
//  TRPTripRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 5.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

public class TRPTimelineRemoteApi: TimelineRemoteApi {
    
    public init() {}
    
    public func createTimeline(profile: TRPTimelineProfile, completion: @escaping (TimelineResultValue) -> Void) {
        
        guard let timelineSettings = TimelineProfileMapper().makeTimelineSettings(profile: profile) else { return }
        
        TRPRestKit().createTimeline(settings: timelineSettings) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let result = result as? TRPTimelineModel, let converted = TimelineMapper().map(result) {
                completion(.success(converted))
            }
        }
    }
    
    public func createEditTimelineSegment(profile: TRPCreateEditTimelineSegmentProfile, completion: @escaping (TimelineResultStatus) -> Void) {
        
        guard let timelineSettings = TimelineProfileMapper().makeTimelineSegmentSettings(editTimelineProfile: profile, tripHash: profile.tripHash) else { return }
        
        TRPRestKit().createEditTimelineSegment(segmentSettings: timelineSettings) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let result = result as? TRPUpdatedModel {
                completion(.success(result.updated == true))
            } else {
                completion(.success(false))
            }
        }
    }
    
    public func fetchTimeline(tripHash: String, completion: @escaping (TimelineResultValue) -> Void) {
        TRPRestKit().getTimeline(withHash: tripHash) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let result = result as? TRPTimelineModel, let converted = TimelineMapper().map(result) {
                completion(.success(converted))
            }
        }
    }
    
    public func deleteTimeline(tripHash: String, completion: @escaping (TimelineResultStatus) -> Void) {
        TRPRestKit().deleteTimeline(hash: tripHash) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if result is TRPDeleteUserTripInfo {
                completion(.success(true))
            } else {
                completion(.success(false))
            }
        }
    }
    
    public func deleteTimelineSegment(tripHash: String, segmentIndex: Int, completion: @escaping (TimelineResultStatus) -> Void) {
        TRPRestKit().deleteTimelineSegment(hash: tripHash, segmentIndex: segmentIndex) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let result = result as? TRPDeleteUserTripInfo {
                completion(.success(result.recordId > -1))
            } else {
                completion(.success(false))
            }
        }
    }
}
