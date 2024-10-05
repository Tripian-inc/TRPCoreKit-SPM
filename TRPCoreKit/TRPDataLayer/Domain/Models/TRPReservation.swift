//
//  TRPReservation.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 25.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public struct TRPReservation {
    public let id: Int
    public let key: String
    //let value: Any?
    public let provider: String
    public let tripHash: String?
    public let poiID: String?
    public let createdAt: String?
    public var updatedAt: String?
    public var yelpModel: TRPYelp?
    public var gygModel: TRPGyg?
}
