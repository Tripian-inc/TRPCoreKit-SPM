//
//  TRPRecommendation.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 8.05.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation


internal class TRPRecommendation: TRPRestServices<TRPGenericParser<[TRPRecommendationInfoJsonModel]>> {
    
    var setting: TRPRecommendationSettings
    var limit: Int = 15
    
    internal init(settings: TRPRecommendationSettings) {
        self.setting = settings
    }
    
    public override func path() -> String {
        return TRPConfig.ApiCall.recommendations.link
    }
    
    public override func parameters() -> [String: Any]? {
        var params: [String: Any] = [:]

        if setting.cityId == nil && setting.hash == nil {
            return [:]
        }
        
        if let cityId = setting.cityId {
            params["cityId"] = cityId
        }
        
        if let hash = setting.hash {
            params["tripHash"] = hash
        }
        
        if let typeIds = setting.poiCategoryIds {
            params["poiCategories"] = typeIds.toString()
        }
        
        if let adults = setting.adultsCount {
            params["adults"] = adults
        }
        
        if let adultAgeRange = setting.adultAgeRange {
            params["adultAgeAverage"] = adultAgeRange
        }
        
        if let childrenCount = setting.childrenCount {
            params["children"] = childrenCount
        }
        
        if let childrenAgeRange = setting.childrenAgeRange {
            params["childrenAgeAverage"] = childrenAgeRange
        }
        
        if let coord = setting.currentCoordinate {
            params["coordinate"] = coord // int
        }
        
        if let answer = setting.answer {
            params["answers"] = answer.toString()
        }
        
        return params
    }
    
}
