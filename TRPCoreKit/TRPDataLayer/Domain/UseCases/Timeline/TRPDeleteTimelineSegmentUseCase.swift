//
//  TRPDeleteTimelineSegmentUseCase.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 26.08.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

final public class TRPDeleteTimelineSegmentUseCase {
    
    private(set) var repository: TimelineRepository
    
    
    public init(repository: TimelineRepository = TRPTimelineRepository()) {
        self.repository = repository
    }
}

extension TRPDeleteTimelineSegmentUseCase: DeleteTimelineSegmentUseCase {
    public func executeDeleteTimelineSegment(tripHash: String, segmentIndex: Int, completion: ((Result<Bool, any Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        repository.deleteTimelineSegment(tripHash: tripHash, segmentIndex: segmentIndex, completion: onComplete)
    }
    
    
}
