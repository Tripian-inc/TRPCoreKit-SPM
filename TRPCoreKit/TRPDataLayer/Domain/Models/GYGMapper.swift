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
//        model.tourName = restModel.data?.shoppingCart?.tourName ?? "Tour Name"
//        model.cancellation_policy_text = restModel.data?.shoppingCart?.bookings?.first?.bookable?.cancellationPolicyText ?? ""
//        model.image = restModel.data?.shoppingCart?.tourImage ?? ""
//        model.ticketUrl = restModel.data?.shoppingCart?.bookings?.first?.ticket?.ticketURL ?? ""
//        model.cityName = restModel.data?.shoppingCart?.cityName ?? ""
//        model.bookingHash = restModel.data?.shoppingCart?.bookings?.first?.bookingHash ?? ""
        return model
    }
   
    func map(_ restModels: [TRPGygInfoModel]) -> [TRPGyg] {
        restModels.map { map($0) }
    }
}
