//
//  TimelineMapper.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 08.08.2025.
//  Copyright © 2025 Cem Çaygöz. All rights reserved.
//

import Foundation
import TRPRestKit

final class TimelineMapper {
    
    func map(_ restModel: TRPTimelineModel) -> TRPTimeline? {
        
        let profile = TimelineProfileMapper().map(restModel.tripProfile) 
        
        let city = CityMapper().map(restModel.city)
        
        let plans = TimelinePlanMapper().map(restModel.plans, profileSegments: profile?.segments)
        
        return TRPTimeline(id: restModel.id,
                           tripHash: restModel.tripHash,
                           tripProfile: profile,
                           city: city,
                           plans: plans)
    }
    
    func map(_ restModels: [TRPTimelineModel]) -> [TRPTimeline] {
        return restModels.compactMap{ map($0) }
    }
    
}
