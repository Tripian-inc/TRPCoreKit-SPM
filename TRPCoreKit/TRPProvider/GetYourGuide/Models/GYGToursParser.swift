//
//  GYGToursParser.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 1.10.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
internal class GYGToursParser: Decodable {
    
    public var reviews: GYGReviews?
    
    private enum CodingKeys: String, CodingKey {
        case reviews
    }
    
}
