//
//  StayAddressCellModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 12.06.2021.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

struct StayAddressCellModel {
    var title: String
    var subTitle: String
}

extension StayAddressCellModel {
    init(place: TRPGooglePlace) {
        self.title = place.mainAddress
        self.subTitle = place.secondaryAddress
    }
}
