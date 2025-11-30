//
//  TRPType.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 7.05.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation
internal class TRPPoiCategoryService: TRPRestServices<TRPPoiCategoryJsonModel> {
    
    var limit: Int = 150
    var page: Int = 1
    var version = 2
    
    internal override init() {}
   
    public override func path() -> String {
        return TRPConfig.ApiCall.poiCategory.link
    }
    
    override func parameters() -> [String: Any]? {
        return getParameters()
    }
    
    private func getParameters() -> [String: Any] {
        var parameters: [String: Any] = [:]
        parameters["limit"] = limit
        parameters["page"] = page
        parameters["version"] = version
        return parameters
    }
    
}
