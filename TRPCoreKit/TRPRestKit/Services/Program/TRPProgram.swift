//
//  TRPProgram.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 25.08.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation
internal class TRPProgram: TRPRestServices<TRPGenericParser<TRPTripModel>> {
    
    var setting: TRPTripSettings?
    
    internal override init() {}
    
    internal init(setting: TRPTripSettings) {
        self.setting = setting
    }
    
    public override func path() -> String {
        var link = TRPConfig.ApiCall.trip.link
        if let hash = setting?.hash {
            link += "/\(hash)"
        }
        return link
    }
    
    override func requestMode() -> TRPRequestMode {
        if setting?.hash != nil {
            return .put
        }
        return TRPRequestMode.post
    }
    
    override func userOAuth() -> Bool {
        return true
    }
    
    public override func bodyParameters() -> [String: Any]? {
        var params: [String: Any] = [:]
        
        guard let setting = setting else {
            return params
        }
        params["cityId"] = setting.cityId
        params["arrivalDatetime"] = setting.arrivalTime.timeForServer
        params["departureDatetime"] = setting.departureTime.timeForServer
        params["numberOfAdults"] = setting.adultsCount
        
        if let children = setting.childrenCount {
            params["numberOfChildren"] = children
        }
        
        params["answers"] = setting.getAllAnswers()
        
        if let coord = setting.coordinate {
            params["coordinate"] = "{\"lat\":\(coord.lat),\"lng\"\(coord.lon)}"
        }
        if let accommodationAddress = setting.accommodationAdress, let accomJson = accommodationAddress.json() {
            params["accommodation"] = accomJson
//        }else {
//            params["accommodation"] =  NSNull()
        }
        
        if let companions = setting.selectedCompanionIds {
            params["companionIds"] = companions
        }

        if let pace = setting.pace {
            params["pace"] = pace.uppercased()
        }
        
        let generate = setting.doNotGenerate == true ? 1 : 0
        params["doNotGenerate"] = generate
        
        if let theme = setting.theme, !theme.isEmpty {
            params["theme"] = theme
        }
        
        if let excludeHash = setting.excludeHash {
            params["excludeHash"] = excludeHash
        }
        
        if let additionalData = setting.additionalData {
            params["additionalData"] = additionalData
        }
        print("CreateTrip Params \(params)")
        return params
    }
    
}
