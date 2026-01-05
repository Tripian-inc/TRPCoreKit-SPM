//
//  GYGMapper.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 2020-12-30.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

final class GYGMapper {
    
    func map(_ restModel: TRPGygInfoModel) -> TRPGyg {
        let model = TRPGyg()
        model.tourName = restModel.data?.shoppingCart?.tourName ?? "Tour Name"
        if let booking = restModel.data?.shoppingCart?.bookings?.first {
            model.cancellation_policy_text = booking.bookable?.cancellationPolicyText ?? ""
            model.ticketUrl = booking.ticket?.ticketURL ?? ""
            model.bookingHash = booking.bookingHash ?? ""
            model.dateTime = booking.bookable?.datetime ?? ""
        }
        model.image = restModel.data?.shoppingCart?.tourImage ?? ""
        model.cityName = restModel.data?.shoppingCart?.cityName ?? ""
        return model
    }
   
    func map(_ restModels: [TRPGygInfoModel]) -> [TRPGyg] {
        restModels.map { map($0) }
    }
}
