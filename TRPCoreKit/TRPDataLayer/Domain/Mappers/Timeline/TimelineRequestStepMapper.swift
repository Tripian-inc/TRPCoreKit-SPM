//
//  TimelineStepMapper.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 5.08.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

final class TimelineStepRequestMapper {
    
    func makeCreateStep(step: TRPTimelineStepCreate) -> TRPTimelineStepCreateModel {
        
        return TRPTimelineStepCreateModel(planId: step.planId,
                                          poiId: step.poiId,
                                          stepType: step.stepType,
                                          customPoi: makeCustomPoi(customPoi: step.customPoi),
                                          startTime: step.startTime,
                                          endTime: step.endTime,
                                          order: step.order)
    }
    
    func makeEditStep(step: TRPTimelineStepEdit) -> TRPTimelineStepEditModel {
        
        return TRPTimelineStepEditModel(stepId: step.stepId,
                                        poiId: step.poiId,
                                        stepType: step.stepType,
                                        customPoi: makeCustomPoi(customPoi: step.customPoi),
                                        startTime: step.startTime,
                                        endTime: step.endTime,
                                        order: step.order)
    }
    
    private func makeCustomPoi(customPoi: TRPTimelineStepCustomPoi?) -> TRPTimelineStepCustomPoiModel? {
        guard let customPoi else { return nil}
        return TRPTimelineStepCustomPoiModel(name: customPoi.name,
                                             coordinate: customPoi.coordinate,
                                             address: customPoi.address,
                                             description: customPoi.description,
                                             tags: customPoi.tags,
                                             phone: customPoi.phone,
                                             web: customPoi.web,
                                             categoryId: customPoi.categoryId)
    }
    
}
