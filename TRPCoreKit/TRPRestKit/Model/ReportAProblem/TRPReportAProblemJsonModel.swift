//
//  TRPReportAProblemJsonModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 19.04.2019.
//  Copyright © 2019 Evren Yaşar. All rights reserved.
//

import Foundation
/// Parent Json parser model for Problem
internal class TRPReportAProblemJsonModel: TRPParentJsonModel {
    
    /// Problem model
    public var data: TRPReportAProblemInfoModel?
    
    private enum CodingKeys: String, CodingKey {
        case data
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        data = try values.decodeIfPresent(TRPReportAProblemInfoModel.self, forKey: .data)
        try super.init(from: decoder)
    }
    
}

/// This model provide you to use full information of Problem.
public struct TRPReportAProblemInfoModel: Decodable {
    
    /// An Int value. Id of problem
    let id: Int
    /// A String value. Category of a problem.
    let problemCategory: String?
    /// A String value. User's message.
    let message: String?
    /// An Int value. Id of poi.
    var poiId: String?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case problemCategory = "problemCategory"
        case message
        case poiId = "poiId"
    }
    
    /// Initializes a new object with decoder
    ///
    /// - Parameter decoder: Json decoder
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(Int.self, forKey: .id)
        self.problemCategory = try values.decodeIfPresent(String.self, forKey: .problemCategory)
        self.message = try values.decodeIfPresent(String.self, forKey: .message)
        self.poiId = try values.decodeIfPresent(String.self, forKey: .poiId)
    }
    
}
