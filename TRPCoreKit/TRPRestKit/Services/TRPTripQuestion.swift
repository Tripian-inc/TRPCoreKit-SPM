//
//  TRPQuestion.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 8.05.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation

/// Indicates question type
///
/// - trip: question about Trip.
/// - profile: question about user profile.
public enum TRPQuestionCategory: String {
    // Question about Trip.
    case trip
    // Question about user profile.
    case profile
    //Question about companion.
    case companion 
}

internal class TRPQuestionService: TRPRestServices<TRPQuestionJsonModel> {
    
    private var cityId: Int?
    public var tripType = TRPQuestionCategory.trip
    public var language: String?
    
    internal init(cityId: Int) {
        self.cityId = cityId
    }
    
    internal init(tripType: TRPQuestionCategory) {
        self.tripType = tripType
    }
 
    public override func path() -> String {
        return TRPConfig.ApiCall.questions.link
    }
    
    public override func parameters() -> [String: Any]? {
        var dic: [String: Any] = [:]
        if let cityId = cityId {
            dic["cityId"] = "\(cityId)"
            dic["category"] = "\(tripType.rawValue)"
            if let lang = language {
                dic["languageCode"] = "\(lang)"
            }
            
            return dic
        }
        dic["category"] = "\(tripType.rawValue)"
        return dic
    }
    
    
    public override func userOAuth() -> Bool {
        return true
    }
}
