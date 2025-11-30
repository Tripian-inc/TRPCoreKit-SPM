//
//  TripModelRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol TimelineModelRepository {
    
    
    /// Tüm Trip(1.2.3. gün)
    var timeline: ValueObserver<TRPTimeline> {get set}
    
    
    /// Secilen gün
    var dailySegment: ValueObserver<TRPTimelinePlan> {get set}
    
    var allSegmentGenerated: ValueObserver<Bool> { get set}
    
    var generationError: ValueObserver<Error?> { get set}
    
}

