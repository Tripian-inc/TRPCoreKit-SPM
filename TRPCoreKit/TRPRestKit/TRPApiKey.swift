//
//  TRPApiKey.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 16.12.2019.
//  Copyright © 2019 Evren Yaşar. All rights reserved.
//

import Foundation
class TRPApiKey {
    
    internal static var shared = TRPApiKey()
    private(set) var apiKey: String?
    
    /// Api keyi döndüren methodudur.
    /// Eğer api key Info.Plist üzerinden döndürülürmesi gerekirse diye eklendi.
    static func getApiKey() -> String {
        //if TRPApiKey.shared.apiKey == nil {
        //   TRPApiKey.shared.apiKey = TRPApiKeyController.getKey(.trpApiKey)
        //}
        let errorMessage = "Api key must not be empty. Please add your api key to TRPClient.start(enviroment:,apiKey:)"
        if TRPApiKey.shared.apiKey == nil {
            Log.e(errorMessage)
        }else if TRPApiKey.shared.apiKey!.count == 0 {
            Log.e(errorMessage)
        }
        
        return TRPApiKey.shared.apiKey ?? ""
    }
    
    static func setApiKey(_ key: String) {
        TRPApiKey.shared.apiKey = key
    }
    
}
