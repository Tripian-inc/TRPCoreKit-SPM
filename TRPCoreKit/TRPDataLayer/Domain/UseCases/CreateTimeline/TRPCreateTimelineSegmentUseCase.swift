//
//  TRPCreateTripUseCase.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 6.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
final public class TRPCreateTimelineSegmentUseCase {
    
    private(set) var repository: TimelineRepository
    
    public init(repository: TimelineRepository = TRPTimelineRepository()) {
        self.repository = repository
    }
    
}

extension TRPCreateTimelineSegmentUseCase: CreateTimelineSegmentUseCases {
    public func executeCreateSegmentTimeline(profile: TRPCreateEditTimelineSegmentProfile, completion: ((Result<Bool, any Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        
        repository.createEditTimelineSegment(profile: profile, completion: onComplete)
    }
    
}
