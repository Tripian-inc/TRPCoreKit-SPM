//
//  TRPAccommodation.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 6.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

public struct TRPAccommodation: Codable {
    
    public var name: String?
    public var referanceId: String?
    public var address: String?
    public var coordinate: TRPLocation
    
    public init(name: String?, referanceId: String?, address: String?, coordinate: TRPLocation) {
        self.name = name
        self.referanceId = referanceId
        self.address = address
        self.coordinate = coordinate
    }
}
