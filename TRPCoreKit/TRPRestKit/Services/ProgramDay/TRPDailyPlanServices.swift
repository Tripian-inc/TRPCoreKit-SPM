//
//  TRPGetProgramDay.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 28.08.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation
internal class TRPDailyPlanServices: TRPRestServices<TRPDayPlanJsonModel> {
    
    var dayId: Int?
    var startTime: String?
    var endTime: String?
    var stepOrders: [Int]?
    
    internal init(id: Int) {
        self.dayId = id
    }
    
    internal init(id: Int, startTime: String, endTime: String) {
        self.dayId = id
        self.startTime = startTime
        self.endTime = endTime
    }
    
    //TODO: orde eklenecek
    internal init(id: Int, stepOrders orders: [Int]) {
        self.stepOrders = orders
        self.dayId = id
    }
    
    public override func userOAuth() -> Bool {
        return true
    }
    
    override func requestMode() -> TRPRequestMode {
        if startTime != nil && endTime != nil {
            return .put
        }else if stepOrders != nil {
            return .put
        }
        return .get
        
    }
    
    public override func path() -> String {
        var path = TRPConfig.ApiCall.dailyPlan.link
        if let id = dayId {
            path += "/\(id)"
        }
        
        return path
    }
    
    override func bodyParameters() -> [String : Any]? {
        var params: [String: Any] = [:]
        if let startTime = startTime {
            params["startTime"] = startTime
        }
        if let startTime = endTime {
            params["endTime"] = startTime
        }
        if let orders = stepOrders {
            params["stepOrders"] = orders
        }
        if params.count == 0 {
            return nil
        }
        return params
    }

}
