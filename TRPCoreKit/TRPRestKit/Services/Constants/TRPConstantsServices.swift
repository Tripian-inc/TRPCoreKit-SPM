//
//  TRPConstantsServices.swift
//  TRPRestKit
//
//  Created by Rozeri Dağtekin on 7/30/19.
//  Copyright © 2019 Evren Yaşar. All rights reserved.
//

import Foundation

internal class TRPConstantsServices: TRPRestServices<TRPConstantsParentJsonModel> {
    
    internal override init() {}
    
    override func path() -> String {
        return "sdk-constants"
    }
    
    override func parameters() -> [String: Any]? {
        var params: [String: Any] = [:]
        params["platform"] = "ios"
        return params
    }
    override func userOAuth() -> Bool {
        return true
    }
    
}
