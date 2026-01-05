//
//  PoiLocationMapper.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

final class PoiLocationMapper {
    
    func map(_ restModel: TRPPoiLocationInfoModel) -> TRPPoiLocation {
        return TRPPoiLocation(
            id: restModel.id ?? 0,
            name: restModel.name ?? "",
            locationType: restModel.locationType ?? "",
            country: restModel.country ?? "",
            continent: restModel.continent ?? ""
        )
    }
    
    func map(_ restModels: [TRPPoiLocationInfoModel]) -> [TRPPoiLocation] {
        return restModels.map { map($0) }
    }
}
