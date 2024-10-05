//
//  TRPDeleteStepService.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 6.03.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation
final class TRPDeleteStepService: TRPRestServices<TRPParentJsonModel> {
    let stepId: Int
    
    init(stepId: Int) {
        self.stepId = stepId
    }
    
    override func userOAuth() -> Bool {
        return true
    }
    
    override func requestMode() -> TRPRequestMode {
        return .delete
    }
    
    override func path() -> String {
        return TRPConfig.ApiCall.step.link + "/\(stepId)"
    }
}
