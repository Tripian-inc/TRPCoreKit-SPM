//
//  StepMapper.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 5.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

final class StepMapper {
    
    func map(_ restModel: TRPStepInfoModel, planId: Int? = nil) -> TRPStep? {
        
        guard let poi = PoiMapper().map(restModel.poi) else { return nil }
        
        let hours = TRPHour(from: restModel.hours?.from, to: restModel.hours?.to)
        
        return TRPStep(id: restModel.id,
                       planId: planId,
                       poi: poi,
                       order: restModel.order,
                       score: restModel.score,
                       hours: hours,
                       alternatives: restModel.alternatives)
    }
    
    func map(_ restModels: [TRPStepInfoModel], planId: Int? = nil) -> [TRPStep] {
        return restModels.compactMap { map($0, planId: planId) }
    }
    
}
