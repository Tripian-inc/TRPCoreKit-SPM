//
//  TRPType.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 7.05.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation
internal class TRPPoiCategoryService: TRPRestServices<TRPPoiCategoryJsonModel> {
    
    internal override init() {}
   
    public override func path() -> String {
        return TRPConfig.ApiCall.poiCategory.link
    }
    
}
