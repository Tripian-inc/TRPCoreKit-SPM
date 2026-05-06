//
//  TRPTourSlot.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 04.05.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import Foundation

public struct TRPTourSlot: Codable, Hashable {
    public let date: String       // "yyyy-MM-dd"
    public let time: String       // "HH:mm"
    public let price: Double?

    public init(date: String, time: String, price: Double?) {
        self.date = date
        self.time = time
        self.price = price
    }
}
