//
//  TRPProvider.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 2.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public class TRPProvider {
    
    public static var shared = TRPProvider()
    private(set) var gygApiKey: String?
    private(set) var travelTimeApiKey: String?
    
    public func setApiKeys(gyg: String? = nil, travelTime: String? = nil) {
        if let gyg {
            setGygApiKey(gyg)
        }
        if let travelTime {
            setTravelTimeApiKey(travelTime)
        }
    }
    
    /// Api keyi döndüren methodudur.
    /// Eğer api key Info.Plist üzerinden döndürülürmesi gerekirse diye eklendi.
    func getGygApiKey() -> String {
        return TRPProvider.shared.gygApiKey ?? ""
    }
    
    func setGygApiKey(_ key: String) {
        TRPProvider.shared.gygApiKey = key
    }
    func getTravelTimeApiKey() -> String {
        return TRPProvider.shared.travelTimeApiKey ?? ""
    }
    
    func setTravelTimeApiKey(_ key: String) {
        TRPProvider.shared.travelTimeApiKey = key
    }
}
