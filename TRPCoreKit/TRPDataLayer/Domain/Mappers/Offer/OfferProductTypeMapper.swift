//
//  OfferProductTypeMapper.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 10.08.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

final class OfferProductTypeMapper {
    func map(_ restModel: TRPOffersProductTypeModel) -> TRPOfferProductType {
        
        let recieveMethod: OfferProductTypeRecieveMethod = OfferProductTypeRecieveMethod(rawValue: restModel.receiveMethod) ?? .takeOut
        
        return TRPOfferProductType(id: restModel.id,
                                   name: restModel.name,
                                   receiveMethod: recieveMethod)
    }
}
