//
//  UserTripRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol UserTimelineRemoteApi {
    
    func fetchTimeline(to: String,
                   completion: @escaping (UserTimelineResultsValue) -> Void)
    
    func fetchTimeline(from: String,
                   completion: @escaping (UserTimelineResultsValue) -> Void)
    
    func deleteTimeline(tripHash: String,
                   completion: @escaping (UserTimelineDeleteResult) -> Void)
}
