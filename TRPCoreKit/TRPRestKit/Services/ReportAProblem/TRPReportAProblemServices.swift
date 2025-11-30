//
//  TRPReportAProblemServices.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 25.03.2019.
//  Copyright © 2019 Evren Yaşar. All rights reserved.
//

import Foundation
internal class TRPReportAProblemServices: TRPRestServices<TRPReportAProblemJsonModel> {
    
    let categoryName: String
    var message: String?
    var poiId: String?
    
    internal init(categoryName: String,
                  message msg: String? = nil,
                  poiId poi: String? = nil) {
        self.categoryName = categoryName
        self.message = msg
        self.poiId = poi
    }
    
    override func path() -> String {
        return "reportaproblem"
    }
    
    override func parameters() -> [String: Any]? {
        var params: [String: Any] = [:]
        params["problemCategory"] = categoryName
        
        if let message = message {
            params["message"] = message
        }
        if let poiId = poiId {
            params["poiId"] = poiId
        }
        return params
    }
    
    override func requestMode() -> TRPRequestMode {
        return .post
    }
    
    override func userOAuth() -> Bool {
        return true
    }
    
}
