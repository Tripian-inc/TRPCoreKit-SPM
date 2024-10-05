//
//  Mock-SelectedPlace.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 18.09.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation
struct SelectedPlaceModel {
    let id: Int
    let name: String
    let iconName: String
    let order: Int
    let coord: [Double]
    static func build(id:Int, name:String, iconName:String, order: Int, coord: [Double]) -> SelectedPlaceModel {
        return SelectedPlaceModel(id: id, name: name, iconName: iconName, order: order, coord: coord)
    }
    
}
