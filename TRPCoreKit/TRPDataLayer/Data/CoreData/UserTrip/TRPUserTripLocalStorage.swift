//
//  TRPUserTripLocalStorage.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public class TRPUserTripLocalStorage: UserTripLocalStorage {
    
    private(set) var file = FileIO.shared
    
    public init() {}
    
     public func fetchMYTrip(completion: @escaping (UserTripResultsValue) -> Void) {
        do {
            let json = try file.read(TRPGenericParser<[TRPUserTripInfoModel]>.self, "mytrip")
            if let result = json.data {
                let converted = UserTripMapper().map(result)
                completion(.success(converted))
            }
        }catch {
            print("[Offline] \(error.localizedDescription)")
            completion(.failure(error))
        }
    }
}
