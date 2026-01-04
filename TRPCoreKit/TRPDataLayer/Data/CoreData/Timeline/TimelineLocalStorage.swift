//
//  TripLocalStorage.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 6.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

public protocol TimelineLocalStorage {
    func fetchTimeline(tripHash: String, completion: @escaping (TimelineResultValue) -> Void)
    func saveTimeline(tripHash: String, data: TRPTimeline)
}

public class TRPTimelineLocalStorage: TimelineLocalStorage {
    
    private(set) var file = FileIO.shared
    
    public init() {}
 
    public func fetchTimeline(tripHash: String, completion: @escaping (TimelineResultValue) -> Void) {
        do {
            
            let json = try file.read(TRPTimeline.self, tripHash)
            
                completion(.success(json))
            
        }catch let error {
            print("[Offline] \(error)")
            completion(.failure(error))
        }
    }
    
    public func saveTimeline(tripHash: String, data: TRPTimeline) {
        do {
            try file.write(data, tripHash)
        }catch let _error {
            print("[ERROR] \(_error)")
        }
    }
}
