//
//  AccommondationMapper.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 6.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit
import TRPFoundationKit

final class AccommondationMapper {
    
    func map(_ restModel: TRPAccommodationInfoModel) -> TRPAccommodation {
        
        let coordinate = TRPLocation(lat: restModel.coordinate.lat,
                                     lon: restModel.coordinate.lon)
        
        return TRPAccommodation(name: restModel.name,
                         referanceId: restModel.referanceId,
                         address: restModel.address, coordinate: coordinate)
    }
   
}
