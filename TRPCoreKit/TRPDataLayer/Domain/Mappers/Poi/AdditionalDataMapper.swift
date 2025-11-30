//
//  AdditionalDataMapper.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 23.03.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import TRPRestKit

public final class AdditionalDataMapper {
    func map(_ restModel: TRPAdditionalDataModel?) -> TRPAdditionalData? {
        guard let restModel else { return nil }
        return TRPAdditionalData(bookingUrl: restModel.bookingUrl)
    }
}
