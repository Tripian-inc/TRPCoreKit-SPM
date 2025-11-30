//
//  TRPNearbyResult.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 15.05.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation
internal class TRPStepAlternativesServices: TRPRestServices<TRPPlanPointAlternativeJsonModel> {
    
    private var hash: String?
    private var planId: Int?
    private var stepId: Int?
    
    /// Bir Tripe(dün günlere ait alternativeler)
    /// - Parameter hash: Trip hash
    public init(hash: String) {
        self.hash = hash
    }
    
    /// Bir güne ait tüm alternativeler
    /// - Parameter planId: Gunun Id si
    public init(planId: Int) {
        self.planId = planId
    }
    
    /// Bir adıma(poi ye ait tüm alternativeler
    /// - Parameter stepId: Stepin(poinin) idsi
    public init(stepId: Int) {
        self.stepId = stepId
    }
    
    
    public override func path() -> String {
        return TRPConfig.ApiCall.stepAlternative.link
    }
    
    public override func userOAuth() -> Bool {
        return true
    }
    
    public override func parameters() -> [String: Any]? {
        var params: [String: Any] = [:]
        if let hash = hash {
            params["tripHash"] = hash
        } else if let planId = planId {
            params["planId"] = planId
        } else if let stepId = stepId {
            params["stepId"] = stepId
        }
        return params
    }
    
}
