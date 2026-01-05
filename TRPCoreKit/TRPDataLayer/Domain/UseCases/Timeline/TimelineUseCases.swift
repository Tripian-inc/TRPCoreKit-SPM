//
//  TripUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public protocol FetchTimelineUseCases {
    
    func executeFetchTimeline(tripHash: String, completion: ((Result<TRPTimeline, Error>) -> Void)?)
       
}


public protocol CreateTimelineUseCases {
    
    func executeCreateTimeline(profile: TRPTimelineProfile, completion: ((Result<TRPTimeline, Error>) -> Void)?)
    
}

public protocol DeleteTimelineSegmentUseCase {
    
    func executeDeleteTimelineSegment(tripHash: String, segmentIndex: Int, completion: ((Result<Bool, Error>) -> Void)? )
}


public protocol CreateTimelineSegmentUseCases {
    
    func executeCreateSegmentTimeline(profile: TRPCreateEditTimelineSegmentProfile, completion: ((Result<Bool, Error>) -> Void)?)
    
}

public protocol EditTimelineUseCases {
    
    func executeEditTimeline(profile: TRPCreateEditTimelineProfile, completion: ((Result<TRPTimeline, Error>) -> Void)?)
    func executeEditTimelineSegment(profile: TRPCreateEditTimelineSegmentProfile, completion: ((Result<Bool, Error>) -> Void)?)
    
}

