//
//  UserProfileMapper.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 4.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

final class UserProfileMapper {
    
    func map(_ restModel: TRPUserProfileInfoModel) -> TRPUserProfile {
        TRPUserProfile(age: restModel.age, answers: restModel.answers)
    }
}
