//
//  TRPUserInfoUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 4.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public class TRPUserInfoUseCases {

    private(set) var repository: UserInfoRepository

    public init(repository: UserInfoRepository = TRPUserInfoRepository()) {
        self.repository = repository
    }
    
}

extension TRPUserInfoUseCases: FetchUserInfoUseCase {
    
    public func executeFetchUserInfo(completion: ((Result<TRPUser, Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        
        if let userInfo = repository.userInfo {
            onComplete(.success(userInfo))
            return
        }
        
        repository.fetchUserInfo { [weak self] result in
            switch(result) {
            case .success(let userInfo):
                self?.repository.userInfo = userInfo
                onComplete(.success(userInfo))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
    
}

extension TRPUserInfoUseCases: UserAnswersUseCase {
    
    public func executeUserAnswers(completion: ((Result<[Int], Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        //TODO: Kullanıcı bilgileri tekrardan çekilecek mi?
        if let answers = repository.userInfo?.answers {
            onComplete(.success(answers))
        }else {
            print("[Error] UserInfo couldn't fetch. ")
        }
    }
    
}

extension TRPUserInfoUseCases: UpdateUserInfoUseCase {
    
    public func executeUpdateUserInfo(dateOfBirth: String, completion: ((Result<TRPUser, Error>) -> Void)?) {
        executeUpdateUserInfo(firstName: nil, lastName: nil, password: nil, dateOfBirth: dateOfBirth, answers: nil, completion: completion)
    }
    
    public func executeUpdateUserInfo(answers: [Int], completion: ((Result<TRPUser, Error>) -> Void)?) {
        executeUpdateUserInfo(firstName: nil, lastName: nil, password: nil, dateOfBirth: nil, answers: answers, completion: completion)
    }
    
    public func executeUpdateUserInfo(firstName: String?, lastName: String?, dateOfBirth: String?, completion: ((Result<TRPUser, Error>) -> Void)?) {
        executeUpdateUserInfo(firstName: firstName, lastName: lastName, password: nil, dateOfBirth: dateOfBirth, answers: nil, completion: completion)
    }
    
    public func executeUpdateUserInfo(password: String, completion: ((Result<TRPUser, Error>) -> Void)?) {
        executeUpdateUserInfo(firstName: nil, lastName: nil, password: password, dateOfBirth: nil, answers: nil, completion: completion)
    }
    
    public func executeUpdateUserInfo(firstName: String? = nil,
                                      lastName: String? = nil,
                                      password: String? = nil,
                                      currentPassword: String? = nil,
                                      dateOfBirth: String? = nil,
                                      answers: [Int]? = nil,
                                      completion: ((Result<TRPUser, Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        
        repository.updateUserInfo(firstName: firstName, lastName: lastName, password: password, currentPassword: currentPassword, dateOfBirth: dateOfBirth, answers: answers) { [weak self] result in
            
            switch(result) {
            case .success(let userInfo):
                self?.repository.userInfo = userInfo
                onComplete(.success(userInfo))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
        
    }
    
    
}

extension TRPUserInfoUseCases: DeleteUserUseCase {
    public func deleteUser(completion: ((Result<Bool, Error>) -> Void)?) {
        
        let onComplete = completion ?? { result in }
        
        repository.deleteUser() { result in
            switch result {
            case .success(let status):
                onComplete(.success(status))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
}

extension TRPUserInfoUseCases: LogoutUseCase {
    public func logout(completion: ((Result<Bool, Error>) -> Void)?) {
        
        let onComplete = completion ?? { result in }
        
        repository.logout() { result in
            switch result {
            case .success(let status):
                onComplete(.success(status))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
    
    
}
