//
//  OfferTimeFrameMapper.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 10.08.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

final class OfferTimeFrameMapper {
    
    func map(_ restModel: TRPOffersTimeFrameModel) -> TRPOfferTimeFrame {
       
        TRPOfferTimeFrame(start: restModel.start, end: restModel.end)
    }
}
