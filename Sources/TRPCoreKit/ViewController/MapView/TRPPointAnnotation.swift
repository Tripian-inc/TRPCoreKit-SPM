//
//  TRPPointAnnotation.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 3.08.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//
import Mapbox

public class TRPPointAnnotation: MGLPointAnnotation {
    var imageName: String?
    var order: Int?
    var poiId: String?
    var isOffer: Bool = false
}
