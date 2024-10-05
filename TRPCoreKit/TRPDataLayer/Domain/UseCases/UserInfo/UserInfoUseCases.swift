//
//  UserInfoUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 4.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol FetchUserInfoUseCase {
    
    func executeFetchUserInfo(completion: ((Result<TRPUser, Error>) -> Void)? )
}

public protocol UserAnswersUseCase {
    
    func executeUserAnswers(completion: ((Result<[Int], Error>) -> Void)? )
}

public protocol UpdateUserInfoUseCase {
    
    func executeUpdateUserInfo(firstName: String?,
                               lastName: String?,
                               password: String?,
                               dateOfBirth: String?,
                               answers: [Int]?,
                               completion: ((Result<TRPUser, Error>) -> Void)? )
    
    func executeUpdateUserInfo(firstName: String?,
                               lastName: String?,
                               dateOfBirth: String?,
                               completion: ((Result<TRPUser, Error>) -> Void)? )
    
    func executeUpdateUserInfo(answers: [Int],
                               completion: ((Result<TRPUser, Error>) -> Void)? )
    
    func executeUpdateUserInfo(dateOfBirth: String,
                               completion: ((Result<TRPUser, Error>) -> Void)? )
    
    func executeUpdateUserInfo(password: String,
                               completion: ((Result<TRPUser, Error>) -> Void)? )
}

public protocol DeleteUserUseCase {
    func deleteUser(completion: ((Result<Bool, Error>) -> Void)?)
}

public protocol LogoutUseCase {
    func logout(completion: ((Result<Bool, Error>) -> Void)?)
}
