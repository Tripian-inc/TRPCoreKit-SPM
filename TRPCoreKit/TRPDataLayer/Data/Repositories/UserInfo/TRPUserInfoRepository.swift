//
//  TRPUserInfoRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 4.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
final public class TRPUserInfoRepository: UserInfoRepository {
    
    public var userInfo: TRPUser?
    private(set) var remoteApi: UserInfoRemoteApi
    private(set) var localStorage: UserInfoLocalStorage
    
    public init(remoteApi: UserInfoRemoteApi = TRPUserInfoRemoteApi(),
                localStorage: UserInfoLocalStorage = TRPUserInfoLocalStorage()){
        self.remoteApi = remoteApi
        self.localStorage = localStorage
    }
    
    public func fetchUserInfo(completion: @escaping (UserInfoResultValue) -> Void) {
        remoteApi.fetchUserInfo(completion: completion)
    }
    
    public func updateUserInfo(firstName: String?, lastName: String?, password: String?, dateOfBirth: String?, answers: [Int]?, completion: @escaping (UserInfoResultValue) -> Void) {
        remoteApi.updateUserInfo(firstName: firstName,
                                 lastName: lastName,
                                 password: password,
                                 dateOfBirth: dateOfBirth,
                                 answers: answers,
                                 completion: completion)
    }
    
    public func deleteUser(completion: @escaping (DeleteUserResultValue) -> Void) {
        remoteApi.deleteUser(completion: completion)
    }
    
    public func logout(completion: @escaping (LogoutResultValue) -> Void) {
        remoteApi.logout(completion: completion)
    }

    
}
