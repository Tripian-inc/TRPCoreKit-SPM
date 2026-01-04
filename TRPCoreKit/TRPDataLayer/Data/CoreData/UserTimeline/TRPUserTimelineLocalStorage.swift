//
//  TRPUserTripLocalStorage.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit
public class TRPUserTimelineLocalStorage: UserTimelineLocalStorage {
    
    private(set) var file = FileIO.shared
    
    public init() {}
    
    public func fetchMYTimeline(completion: @escaping (UserTimelineResultsValue) -> Void) {
        do {
            let json = try file.read(TRPGenericParser<[TRPTimelineModel]>.self, "mytimeline")
            if let result = json.data {
                let converted = TimelineMapper().map(result)
                completion(.success(converted))
            }
        }catch {
            print("[Offline] \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
}
