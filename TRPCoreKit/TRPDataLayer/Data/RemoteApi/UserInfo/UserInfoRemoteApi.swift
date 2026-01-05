//
//  UserInfoRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 4.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol UserInfoRemoteApi {
    func fetchUserInfo(completion: @escaping (UserInfoResultValue) -> Void)
    
    func updateUserInfo(firstName: String?,
                        lastName: String?,
                        password: String?,
                        currentPassword: String?,
                        dateOfBirth: String?,
                        answers: [Int]?,
                        completion: @escaping (UserInfoResultValue) -> Void)
    
    func deleteUser(completion: @escaping (DeleteUserResultValue) -> Void)
    
    func logout(completion: @escaping (LogoutResultValue) -> Void)
}
