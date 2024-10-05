//
//  TRPUserReactionType.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 24.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public enum TRPUserReactionType: String {
    case thumbsUp = "Thumbs Up"
    case thumbsDown = "Thumbs Down"
    case neutral = "Neutral"
}

public enum TRPUserReactionComment: String {
    case iHaveAlreadyVisited = "I_HAVE_ALREADY_VISITED"
    case iDontLikePlace = "I_DONT_LIKE_PLACE"
}
