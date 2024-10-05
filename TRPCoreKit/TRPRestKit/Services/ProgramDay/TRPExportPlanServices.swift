//
//  TRPExportPlanServices.swift
//  TRPRestKit
//
//  Created by Cem Çaygöz on 4.04.2023.
//  Copyright © 2023 Evren Yaşar. All rights reserved.
//

import Foundation

internal class TRPExportPlanServices: TRPRestServices<TRPGenericParser<TRPExportPlanJsonModel>> {
    
    private let planId: Int
    private let tripHash: String
    
    internal init(planId: Int, tripHash: String) {
        self.planId = planId
        self.tripHash = tripHash
    }
    
    public override func path() -> String {
        return TRPConfig.ApiCall.exportItinerary.link
    }
    
    override func userOAuth() -> Bool {
        return true
    }
    
    override func requestMode() -> TRPRequestMode {
        return .post
    }
    
    override func bodyParameters() -> [String: Any]? {
        
        var params = [String: Any]()
        params["planId"] = planId
        params["tripHash"] = tripHash
        return params
    }
    
}
