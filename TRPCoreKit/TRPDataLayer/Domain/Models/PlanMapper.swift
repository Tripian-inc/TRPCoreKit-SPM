//
//  PlanMapper.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 5.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

final class PlanMapper {
    
    func map(_ restModel: TRPPlansInfoModel) -> TRPPlan {
        
        let steps = StepMapper().map(restModel.steps, planId: restModel.id)
        
        return TRPPlan(id: restModel.id,
                date: restModel.date,
                startTime: restModel.startTime,
                endTime: restModel.endTime,
                steps: steps,
                generatedStatus: restModel.generatedStatus)
    }
    
    func map(_ restModels: [TRPPlansInfoModel]) -> [TRPPlan] {
        return restModels.compactMap { map($0) }
    }
    
}
