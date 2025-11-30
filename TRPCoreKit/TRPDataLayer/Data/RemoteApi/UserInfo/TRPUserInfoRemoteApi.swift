//
//  TRPUserInfoRemoteApi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 4.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit

public class TRPUserInfoRemoteApi: UserInfoRemoteApi {
    
    public init() {}
    
    public func fetchUserInfo(completion: @escaping (UserInfoResultValue) -> Void) {
        TRPRestKit().userInfo { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let userInfo = result as? TRPUserInfoModel {
                let converted = UserMapper().map(userInfo)
                completion(.success(converted))
            }
        }
    }
    
    public func updateUserInfo(firstName: String?,
                               lastName: String?,
                               password: String?,
                               currentPassword: String?,
                               dateOfBirth: String?,
                               answers: [Int]?,
                               completion: @escaping (UserInfoResultValue) -> Void) {
        
        TRPRestKit().updateUserInfo(firstName: firstName,
                                    lastName: lastName,
                                    password: password,
                                    currentPassword: currentPassword,
                                    dateOfBirth: dateOfBirth,
                                    answers: answers) { result, error in
            
            if let error = error {
                completion(.failure(error))
                return
            }
            if let userInfo = result as? TRPUserInfoModel {
                let converted = UserMapper().map(userInfo)
                completion(.success(converted))
            }
        }
        
    }
    
    public func deleteUser(completion: @escaping (DeleteUserResultValue) -> Void) {
        TRPRestKit().deleteUser() { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let result = result as? TRPParentJsonModel {
        
                completion(.success(result.success))
                
            }
        }
    }
    
    public func logout(completion: @escaping (LogoutResultValue) -> Void) {
        TRPRestKit().logout() { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let result = result as? TRPParentJsonModel {
        
                completion(.success(result.success))
                
            }
        }
    }
    
        
}
