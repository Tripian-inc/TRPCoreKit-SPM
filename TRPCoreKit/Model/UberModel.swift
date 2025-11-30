//
//  UberModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 8.06.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

public struct UberModel {
    public var pickupLocation: TRPLocation
    public var pickupName: String
    public var pickupAddress: String
    public var dropoffLocation: TRPLocation
    public var dropOffName: String
    public var dropOffAddress: String
}
