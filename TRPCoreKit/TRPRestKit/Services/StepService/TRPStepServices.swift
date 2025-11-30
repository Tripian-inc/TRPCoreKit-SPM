//
//  TRPStepServices.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 5.03.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation

final class TRPStepServices: TRPRestServices<TRPGenericParser<TRPStepInfoModel>> {
    
    enum ServiceType {
        case edit, add
    }
    
    private var stepId: Int?
    private var poiId: String?
    private var order: Int?
    private var planId: Int?
    private var startTime: String?
    private var endTime: String?
    private let serviceType: ServiceType
    
    //Edit Step
    init(stepId: Int, poiId: String? = nil, order: Int? = nil, startTime: String? = nil, endTime: String? = nil) {
        self.stepId = stepId
        self.poiId = poiId
        self.order = order
        self.startTime = startTime
        self.endTime = endTime
        self.serviceType = .edit
    }
    
    //Add Step
    init(planId: Int, poiId: String, order: Int? = nil) {
        self.planId = planId
        self.poiId = poiId
        self.order = order
        self.serviceType = .add
    }
    
    override func requestMode() -> TRPRequestMode {
        if serviceType == .add {
            return .post
        }
        return .put
    }
    
    override func userOAuth() -> Bool {
        return true
    }
    
    override func bodyParameters() -> [String: Any]? {
        var params: [String: Any] = [:]
        if serviceType == .add {
            guard let planId = planId, let poiId = poiId else {return nil}
            params["planId"] = planId
            params["poiId"] = poiId
            if let order = order {
                params["order"] = order
            }
        } else if serviceType == .edit {
            if let poiId = poiId {
                params["poiId"] = poiId
            }
            if let order = order {
                params["order"] = order
            }
            if let startTime = startTime {
                params["startTime"] = startTime
            }
            if let endTime = endTime {
                params["endTime"] = endTime
            }
        }
        return params
    }
    
    override func path() -> String {
        var path = TRPConfig.ApiCall.step.link
        if let stepId = stepId {
            path += "/\(stepId)"
        }
        return path
    }
    
}
