//
//  CityLocalStorage.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public protocol CityLocalStorage {
    func fetchLocalCity(id: Int, completion: @escaping (CityResultValue) -> Void)
}

public class TRPCityLocalStorage: CityLocalStorage {
    
    private(set) var file = FileIO.shared

    public init() {}
    
    public func fetchLocalCity(id: Int, completion: @escaping (CityResultValue) -> Void) {
        
    }
}
