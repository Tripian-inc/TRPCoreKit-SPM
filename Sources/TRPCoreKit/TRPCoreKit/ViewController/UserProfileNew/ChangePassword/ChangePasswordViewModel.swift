//
//  ChangePasswordViewModel.swift
//  Wiserr
//
//  Created by Cem Çaygöz on 6.08.2021.
//

import Foundation
import TRPDataLayer

final class ChangePasswordViewModel: ChangePasswordViewModelProtocol {
    var delegate: ChangePasswordViewModelDelegate?
    public var updateUserInfoUseCase: UpdateUserInfoUseCase?
    
    func save(password: String, confirmPassword: String) {
        if checkPasswords(password: password, confirmPassword: confirmPassword) {
            updateUser(password)
        }
    }
    
    func handler(_ output: ChangePasswordViewModelOutput) {
        delegate?.handleViewModelOutput(output)
    }
    
    private func checkPasswords(password: String, confirmPassword: String) -> Bool{
        if password.isEmpty {
            handler(.showWarning("Password is empty"))
            return false
        }
        if password != confirmPassword {
            handler(.showWarning("Passwords do not match"))
            return false
        }
        return true
    }
}

extension ChangePasswordViewModel {
    
    private func updateUser(_ password: String) {
        handler(.showLoading(true))
            
        updateUserInfoUseCase?.executeUpdateUserInfo(password: password, completion: { [weak self] result in
            self?.handler(.showLoading(false))
            switch result {
            case .success(_):
                self?.handler(.showMessage("Your information is successfully updated!"))
                self?.handler(.updatedPassword)
            case .failure(let error):
                self?.handler(.showError(error))
            }
        })
    }
}
