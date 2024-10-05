//
//  TRPUserReaction.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 24.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public struct TRPUserReaction {
    
    public var id: Int
    public var poiId: String
    public var stepId: Int
    public var reaction: TRPUserReactionType?
    public var comment: String?
    public var createdAt: String?
    public var updatedAt: String?
    public var tripHash: String?
    
}
