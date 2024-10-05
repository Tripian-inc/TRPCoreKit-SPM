//
//  TRPPlanPoint.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 12.09.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation

/// Infomation of Plan Poi.
public struct TRPStepInfoModel: Decodable, Hashable {

    /// An Int value. Id of PlanPoi
    public var id: Int
    
    public var poi: TRPPoiInfoModel
    /// An Int value. Order of PlanPoi
    public var order: Int = 0
    
    public var score: Float?
    
    public var hours: TRPHourInfoModel?
    public var alternatives: [String]
    
    private enum CodingKeys: String, CodingKey {
        case id
        case poi
        case score
        case hours
        case order
        case alternatives
    }
    
    /// Initializes a new object with decoder
    ///
    /// - Parameter decoder: Json decoder
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        poi = try values.decode(TRPPoiInfoModel.self, forKey: .poi)
        score = try values.decodeIfPresent(Float.self, forKey: .score)
        hours = try values.decodeIfPresent(TRPHourInfoModel.self, forKey: .hours)
        alternatives = try values.decode([String].self, forKey: .alternatives)
        order = try values.decode(Int.self, forKey: .order)
    }
    
    public static func == (lhs: TRPStepInfoModel, rhs: TRPStepInfoModel) -> Bool {
        return lhs.order < rhs.order
    }
    
    public func hash(into hasher: inout Hasher) {}
    
}

public struct TRPHourInfoModel: Decodable {
    public var from: String?
    public var to: String?
}
