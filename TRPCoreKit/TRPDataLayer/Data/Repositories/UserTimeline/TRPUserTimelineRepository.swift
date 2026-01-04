//
//  TRPUserTripRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
final public class TRPUserTimelineRepository: UserTimelineRepository {
    
    public var upcomingTimelines: ValueObserver<[TRPTimeline]> = .init([])
    public var pastTimelines: ValueObserver<[TRPTimeline]> = .init([])
    
    
    private var remoteApi: UserTimelineRemoteApi
    private var localStorage: UserTimelineLocalStorage
    
    
    public init(remoteApi: UserTimelineRemoteApi = TRPUserTimelineRemoteApi(),
                localStorage: UserTimelineLocalStorage = TRPUserTimelineLocalStorage() ) {
        
        self.remoteApi = remoteApi
        self.localStorage = localStorage
    }
    
    public func fetchTimeline(to: String, completion: @escaping (UserTimelineResultsValue) -> Void) {
        remoteApi.fetchTimeline(to: to, completion: completion)
    }
    
    public func fetchTimeline(from: String, completion: @escaping (UserTimelineResultsValue) -> Void) {
        remoteApi.fetchTimeline(from: from, completion: completion)
    }
    
    public func deleteTimeline(tripHash hash: String, completion: @escaping (UserTimelineDeleteResult) -> Void) {
        remoteApi.deleteTimeline(tripHash: hash, completion: completion)
    }
    
    public func fetchLocalTimeline(completion: @escaping (UserTimelineResultsValue) -> Void) {
        localStorage.fetchMYTimeline(completion: completion)
    }
    
}
