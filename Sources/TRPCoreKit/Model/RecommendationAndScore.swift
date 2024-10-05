//
//  RecommendationAndScore.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 8.04.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public struct RecommendationAndScore: Comparable {
    
    let poiId: String
    let score: Double
    
    public static func < (lhs: RecommendationAndScore, rhs: RecommendationAndScore) -> Bool {
        return lhs.score > rhs.score
    }
}
