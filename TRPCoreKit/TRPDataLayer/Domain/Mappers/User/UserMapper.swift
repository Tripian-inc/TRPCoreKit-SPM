//
//  UserMapper.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 4.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

final class UserMapper {
    
    func map(_ restModel: TRPUserInfoModel) -> TRPUser {
        
        return TRPUser(email: restModel.email,
                       firstName: restModel.firstName,
                       lastName: restModel.lastName,
                       dateOfBirth: restModel.dateOfBirth,
                       answers: restModel.answers)
    }
    
}


