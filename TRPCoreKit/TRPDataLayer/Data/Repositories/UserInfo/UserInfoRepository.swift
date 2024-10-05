//
//  UserInfoRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 4.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation


public typealias UserInfoResultValue = (Result<TRPUser, Error>)

public typealias DeleteUserResultValue = (Result<Bool, Error>)
public typealias LogoutResultValue = (Result<Bool, Error>)


public protocol UserInfoRepository {
    
    var userInfo: TRPUser? {get set}
    
    func fetchUserInfo(completion: @escaping (UserInfoResultValue) -> Void)
    
    func updateUserInfo(firstName: String?,
                        lastName: String?,
                        password: String?,
                        dateOfBirth: String?,
                        answers: [Int]?,
                        completion: @escaping (UserInfoResultValue) -> Void)
    
    func deleteUser(completion: @escaping (DeleteUserResultValue) -> Void)
    
    func logout(completion: @escaping (LogoutResultValue) -> Void)
}
