//
//  TRPStepServices.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 5.03.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation

final class TRPCustomStepServices: TRPRestServices<TRPGenericParser<TRPStepInfoModel>> {
    
    private var name: String?
    private var address: String?
    private var description: String?
    private var web: String?
    private var latitude: Double?
    private var longitude: Double?
    private var photoUrl: String?
    private var planId: Int
    
    
    
    //Add Step
    init(planId: Int, name: String?, address: String?, description: String?, photoUrl: String?, web: String?, latitude: Double?, longitude: Double?) {
        self.planId = planId
        self.name = name
        self.address = address
        self.description = description
        self.photoUrl = photoUrl
        self.web = web
        self.latitude = latitude
        self.longitude = longitude
    }
    
    override func requestMode() -> TRPRequestMode {
        return .post
    }
    
    override func userOAuth() -> Bool {
        return true
    }
    
    override func bodyParameters() -> [String: Any]? {
        var params: [String: Any] = [:]
        params["planId"] = planId
        var customPoiParams: [String: Any] = [:]
        if let name = name {
            customPoiParams["name"] = name
        }
        if let address = address {
            customPoiParams["address"] = address
        }
        if let description = description {
            customPoiParams["description"] = description
        }
        if let photoUrl = photoUrl {
            customPoiParams["photos"] = [["is_featured": false, "url": photoUrl]]
        }
        if let web = web {
            customPoiParams["web"] = web
        }
        if let longitude = longitude, let latitude = latitude {
            customPoiParams["coordinate"] = ["lat": latitude, "lng": longitude]
        }
        params["customPoi"] = customPoiParams
        params["stepType"] = "poi"
        return params
    }
    
    override func path() -> String {
        return TRPConfig.ApiCall.step.link
    }
    
}
