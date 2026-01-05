//
//  TRPUserTripRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit
final public class TRPUserTimelineRemoteApi: UserTimelineRemoteApi {

    public init() {}
    
    public func fetchTimeline(to: String, completion: @escaping (UserTimelineResultsValue) -> Void) {
        TRPRestKit().userTimelines(to: to) { (result, error, pagination) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let result = result as? [TRPTimelineModel] {
                let converted = TimelineMapper().map(result)
                completion(.success(converted))
            }
        }
    }
    
    public func fetchTimeline(from: String, completion: @escaping (UserTimelineResultsValue) -> Void) {
        TRPRestKit().userTimelines(from: from) { (result, error, pagination) in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let result = result as? [TRPTimelineModel] {
                let converted = TimelineMapper().map(result)
                completion(.success(converted))
            }
        }
    }
    
    
    public func deleteTimeline(tripHash: String, completion: @escaping (UserTimelineDeleteResult) -> Void) {
        TRPRestKit().deleteTimeline(hash: tripHash) { (result, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
//            if let result = result as? TRPDeleteUserTripInfo {
                completion(.success(true))
//            } else {
//                completion(.success(false))
//            }
        }
    }
}
