//
//  ReservationMapper.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 25.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit


final class ReservationMapper {
    
    func map(_ restModel: TRPReservationInfoModel) -> TRPReservation {
       
        let yelp = restModel.yelpModel != nil ? YelpMapper().map(restModel.yelpModel!) : nil
        let gyg = restModel.gygModel != nil ? GYGMapper().map(restModel.gygModel!) : nil
        return TRPReservation(id: restModel.id,
                              key: restModel.key,
                              provider: restModel.provider,
                              tripHash: restModel.tripHash ,
                              poiID: restModel.poiID ,
                              createdAt: restModel.createdAt,
                              updatedAt: restModel.updatedAt,
                              yelpModel: yelp,
                              gygModel: gyg)
    }
   
    func map(_ restModels: [TRPReservationInfoModel]) -> [TRPReservation] {
        restModels.map { map($0) }
    }
}
