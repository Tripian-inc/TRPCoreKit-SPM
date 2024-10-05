//
//  TripLocalStorage.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 6.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation


public protocol TripLocalStorage {
    func fetchTrip(tripHash: String, completion: @escaping (TripResultValue) -> Void)
    func saveTrip(tripHash: String, data: TRPTrip)
}

public class TRPTripLocalStorage: TripLocalStorage {
    
    private(set) var file = FileIO.shared
    
    public init() {}
 
    public func fetchTrip(tripHash: String, completion: @escaping (TripResultValue) -> Void) {
        do {
            
            let json = try file.read(TRPTrip.self, tripHash)
            
                completion(.success(json))
            
        }catch let error {
            print("[Offline] \(error)")
            completion(.failure(error))
        }
    }
    
    public func saveTrip(tripHash: String, data: TRPTrip) {
        do {
            try file.write(data, tripHash)
        }catch let _error {
            print("[ERROR] \(_error)")
        }
    }
}
