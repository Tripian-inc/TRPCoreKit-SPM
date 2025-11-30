//
//  YelpMapper.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 25.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit


final class YelpMapper {
    
    func map(_ restModel: TRPYelpInfoModel) -> TRPYelp {

        var reservationDetail: TRPYelpReservationDetail?
        
        if let detail = restModel.reservationDetail {
            reservationDetail = TRPYelpReservationDetail(businessID: detail.businessID,
                                                         covers: detail.covers,
                                                         time: detail.time,
                                                         date: detail.date,
                                                         uniqueID: detail.uniqueID,
                                                         phone: detail.phone,
                                                         holdID: detail.holdID,
                                                         firstName: detail.firstName,
                                                         lastName: detail.lastName,
                                                         email: detail.email)
        }
        
        return TRPYelp(confirmURL: restModel.confirmURL,
                       reservationID: restModel.reservationID,
                       restaurantImage: restModel.restaurantImage,
                       restaurantName: restModel.restaurantName,
                       reservationDetail: reservationDetail)
        
    }
   
    
    func map(_ restModels: [TRPYelpInfoModel]) -> [TRPYelp] {
        restModels.map { map($0) }
    }
}
