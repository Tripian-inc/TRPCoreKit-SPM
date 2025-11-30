//
//  TimelineStepMapper.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 5.08.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

final class TimelineStepMapper {
    
    func map(_ restModel: TRPTimelineStepInfoModel) -> TRPTimelineStep? {
        
        guard let poi = PoiMapper().map(restModel.poi) else { return nil }
        
        
        return TRPTimelineStep(id: restModel.id,
                               poi: poi,
                               score: restModel.score,
                               planId: restModel.planId,
                               order: restModel.order,
                               startDateTimes: restModel.startDateTimes,
                               endDateTimes: restModel.endDateTimes,
                               stepType: restModel.stepType,
                               alternatives: restModel.alternatives,
                               warningMessage: restModel.warningMessage)
    }
    
    func map(_ restModels: [TRPTimelineStepInfoModel]) -> [TRPTimelineStep] {
        return restModels.compactMap { map($0) }
    }
    
}
