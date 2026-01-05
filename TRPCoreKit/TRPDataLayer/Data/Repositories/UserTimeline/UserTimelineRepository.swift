//
//  UserTripRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public typealias UserTimelineResultsValue = (Result<[TRPTimeline], Error>)
public typealias UserTimelineDeleteResult = (Result<Bool, Error>)

public protocol UserTimelineRepository {
    
    var upcomingTimelines: ValueObserver<[TRPTimeline]> {get set}
    
    var pastTimelines: ValueObserver<[TRPTimeline]> {get set}
    
    func fetchTimeline(to: String,
                   completion: @escaping (UserTimelineResultsValue) -> Void)
    
    func fetchTimeline(from: String,
                   completion: @escaping (UserTimelineResultsValue) -> Void)
    
    func deleteTimeline(tripHash hash: String,
                    completion: @escaping (UserTimelineDeleteResult) -> Void)
    
    func fetchLocalTimeline(completion: @escaping (UserTimelineResultsValue) -> Void)
}
