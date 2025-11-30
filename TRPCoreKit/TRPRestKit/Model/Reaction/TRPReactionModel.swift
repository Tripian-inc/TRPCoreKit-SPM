//
//  TRPReactionModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 2.05.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation
public struct TRPReactionModel: Decodable {
    
    public var id: Int
    public var poiId: String
    public var stepId: Int
    public var reaction: String?
    public var comment: String?
    public var createdAt: String?
    public var updatedAt: String?
    public var tripHash: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case poiId = "poiId"
        case stepId = "stepId"
        case reaction
        case comment
        case createdAt = "createdAt"
        case updatedAt = "updatedAt"
        case tripHash = "tripHash"
    }
    
}
