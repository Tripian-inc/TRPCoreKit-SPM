//
//  GYGOutline.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 23.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public struct GYGOutline: Codable {
    public let rating, numberOfReviews: Int
    public let share: Double

    enum CodingKeys: String, CodingKey {
        case rating
        case numberOfReviews = "number_of_reviews"
        case share
    }
}
