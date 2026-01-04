//
//  StepMapper.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 5.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

final class StepMapper {
    
    func map(_ restModel: TRPStepInfoModel, planId: Int? = nil) -> TRPStep? {
        
        guard let poi = PoiMapper().map(restModel.poi) else { return nil }
        
        let times = TRPHour(from: restModel.times?.from, to: restModel.times?.to)
        
        return TRPStep(id: restModel.id,
                       planId: planId,
                       poi: poi,
                       order: restModel.order,
                       score: restModel.score,
                       times: times,
                       alternatives: restModel.alternatives)
    }
    
    func map(_ restModels: [TRPStepInfoModel], planId: Int? = nil) -> [TRPStep] {
        return restModels.compactMap { map($0, planId: planId) }
    }
    
}
