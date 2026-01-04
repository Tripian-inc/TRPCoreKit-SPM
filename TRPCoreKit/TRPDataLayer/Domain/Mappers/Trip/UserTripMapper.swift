//
//  UserTripMapper.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

/// Trip bilgileri için model dönüşümü yapar
final class UserTripMapper {
    
    func map(_ restModel: TRPUserTripInfoModel) -> TRPUserTrip? {
        guard let profile = TripProfileMapper().map(restModel.tripProfile) else {return nil}
        
        let city = CityMapper().map(restModel.city)
        
        let cruise = UserTripCruiseMapper().map(restModel.cruise)
        
        return TRPUserTrip(id: restModel.id,
                           tripHash: restModel.tripHash,
                           tripType: restModel.tripType,
                           tripProfile: profile,
                           cruise: cruise,
                           city: city)
    }
    
    func map(_ restModels: [TRPUserTripInfoModel]) -> [TRPUserTrip] {
        return restModels.compactMap{ map($0) }
    }
    
}

class UserTripCruiseMapper {
    func map(_ restModel: TRPUserTripCruiseModel?) -> TRPUserTripCruise? {
        guard let restModel = restModel else {return nil}
        return TRPUserTripCruise(cruiseId: restModel.cruiseId,
                                 cruiseName: restModel.cruiseName)
    }
}
