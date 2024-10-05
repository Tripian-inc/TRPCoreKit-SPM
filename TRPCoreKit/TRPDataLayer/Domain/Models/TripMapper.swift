//
//  TripMapper.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 5.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

final class TripMapper {
    
    func map(_ restModel: TRPTripModel) -> TRPTrip? {
        
        guard let profile = TripProfileMapper().map(restModel.tripProfile, restModel) else { return nil }
        
        let city = CityMapper().map(restModel.city)
        
        let plans = PlanMapper().map(restModel.plans)
        
        return TRPTrip(id: restModel.id,
                tripHash: restModel.tripHash,
                tripProfile: profile,
                city: city,
                plans: plans)
    }
    
}
