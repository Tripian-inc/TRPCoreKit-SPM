//
//  GYGReviewOrder.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 2021-01-03.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import Foundation

public struct GYGReviewOrder {
    
    public var title: String?
    public var optionTitle: String?
    public var bookable: GYGBookable?
    public var price: Double?
    public var people: [GYGCategory]?
    public var status: String?
    public var dateTime: String?
}
