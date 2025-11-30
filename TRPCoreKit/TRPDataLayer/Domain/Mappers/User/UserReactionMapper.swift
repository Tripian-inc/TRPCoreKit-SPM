//
//  UserReactionMapper.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 24.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

final class UserReactionMapper {
    
    func map(_ restModel: TRPReactionModel) -> TRPUserReaction {
        
        let reaction: TRPUserReactionType? = restModel.reaction != nil ? TRPUserReactionType(rawValue: restModel.reaction!) : nil
        
        return TRPUserReaction(id: restModel.id,
                               poiId: restModel.poiId,
                               stepId: restModel.stepId,
                               reaction: reaction,
                               comment: restModel.comment,
                               createdAt: restModel.createdAt,
                               updatedAt: restModel.updatedAt,
                               tripHash: restModel.tripHash)
        
    }
   
    
    func map(_ restModels: [TRPReactionModel]) -> [TRPUserReaction] {
        restModels.map { map($0) }
    }
}



