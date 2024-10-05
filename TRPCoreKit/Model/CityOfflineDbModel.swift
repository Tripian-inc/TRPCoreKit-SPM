//
//  CityOfflineDbModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 8.08.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation
struct CityOfflineDbModel {
    let cityId: Int
    let isPlacesDownload: Bool
    
    init(cityId:Int, isPlacesDownload:Bool) {
        self.cityId = cityId
        self.isPlacesDownload = isPlacesDownload
    }
}
