//
//  UserProfileViewModel.swift
//  Wiserr
//
//  Created by Evren Yaşar on 2021-04-19.
//

import Foundation
import TRPDataLayer

final class UserProfileViewModel: UserProfileViewModelProtocol {
    
    var delegate: UserProfileViewModelDelegate?
    
    public var fetchUserInfoUseCase: FetchUserInfoUseCase?
    public var logoutUseCase: LogoutUseCase?
    
    func start() {
        fetchUserInfo()
    }
    
    func fetchUserInfo() {
        handleOutput(.showLoading(true))
        fetchUserInfoUseCase?.executeFetchUserInfo { [weak self] result in
            self?.handleOutput(.showLoading(false))
            switch(result) {
            case .success(let userInfo):
                guard let firstName = userInfo.firstName?.capitalizingFirstLetter(), let lastName = userInfo.lastName?.capitalizingFirstLetter() else{
                    self?.handleOutput(.userName(""))
                    return
                }
                let fullName = "Hi, \(firstName) \(lastName)"
                self?.handleOutput(.userName(fullName))
            case .failure(let error):
                self?.handleOutput(.showError(error))
            }
        }
    }
    
    func logOut() {
        handleOutput(.showLoading(true))
        logoutUseCase?.logout { [weak self] result in
            self?.handleOutput(.showLoading(false))
//            switch(result) {
//            case .success(_):
//                self?.handleOutput(.logOut)
//            case .failure(let error):
//                self?.handleOutput(.showError(error))
//            }
            self?.handleOutput(.logOut)
        }
    }
    
    private func handleOutput(_ output: UserProfileViewModelOutput) {
        delegate?.handleViewModelOutput(output)
    }
}
