//
//  TRPTripModelRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
final public class TRPTimelineModelRepository: TimelineModelRepository {
    
    public var timeline: ValueObserver<TRPTimeline> = .init(nil)
    
    public var dailySegment: ValueObserver<TRPTimelinePlan> = .init(nil)
    
    public var allSegmentGenerated: ValueObserver<Bool> = .init(false)
    
    public var generationError: ValueObserver<Error?> = .init(nil)
    
    public init() {}
}
