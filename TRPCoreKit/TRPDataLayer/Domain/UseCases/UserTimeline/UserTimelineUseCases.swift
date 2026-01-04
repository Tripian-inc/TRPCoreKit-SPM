//
//  UserTimelineUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public protocol FetchUserUpcomingTimelineUseCase {
    
    func executeUpcomingTimeline(completion: ((Result<[TRPTimeline], Error>) -> Void)? )
}

public protocol FetchUserPastTimelineUseCase {
    
    func executePastTimeline(completion: ((Result<[TRPTimeline], Error>) -> Void)? )
}

public protocol DeleteUserTimelineUseCase {
    
    func executeDeleteTimeline(tripHash: String, completion: ((Result<Bool, Error>) -> Void)? )
}

public protocol ObserveUserUpcomingTimelinesUseCase {
    
    var upcomingTimelines: ValueObserver<[TRPTimeline]> { get }
}

public protocol ObserveUserPastTimelinesUseCase {
    
    var pastTimelines: ValueObserver<[TRPTimeline]> { get }
}

