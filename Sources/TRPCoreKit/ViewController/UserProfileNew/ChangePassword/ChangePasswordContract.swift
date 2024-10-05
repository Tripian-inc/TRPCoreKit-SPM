//
//  ChangePasswordContract.swift
//  Wiserr
//
//  Created by Cem Çaygöz on 6.08.2021.
//

import Foundation

protocol ChangePasswordViewModelProtocol {
    var delegate: ChangePasswordViewModelDelegate? {get set}
    
    func save(password: String, confirmPassword: String)
}

enum ChangePasswordViewModelOutput {
    case showLoading(Bool)
    case showError(Error)
    case showWarning(String)
    case updatedPassword
    case showMessage(String)
}

protocol ChangePasswordViewModelDelegate: AnyObject {
    func handleViewModelOutput(_ output: ChangePasswordViewModelOutput)
}
