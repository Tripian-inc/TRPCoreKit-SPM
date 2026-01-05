//
//  PoiLocalStorage.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 17.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

public protocol PoiLocalStorage {
    func fetchLocalPoi(completion: @escaping (PoiResultsValue) -> Void)
}

public class TRPPoiLocalStorage: PoiLocalStorage {
    private(set) var file = FileIO.shared
    
    public init() {}
    
    public func fetchLocalPoi(completion: @escaping (PoiResultsValue) -> Void) {
        do {
            let city = CruiseDataHolderUseCase.shared.cityId ?? 0
            //TODO: - CİTYID GELECEK
            let json = try file.read(TRPGenericParser<[TRPPoiInfoModel]>.self, "city_\(city)", true)
            if let result = json.data {
                let converted = PoiMapper().map(result)
                completion((.success(converted), nil))
            }
        }catch let error {
            print("[Offline] \(error)")
            completion((.failure(error), nil))
        }
    }
}
