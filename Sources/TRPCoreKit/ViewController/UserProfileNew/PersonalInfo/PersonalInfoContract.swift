//
//  PersonalInfoContract.swift
//  Wiserr
//
//  Created by Evren Yaşar on 2021-05-14.
//

import Foundation

protocol PersonalInfoViewModelProtocol {
    var delegate: PersonalInfoViewModelDelegate? {get set}
    func start()
}

enum PersonalInfoViewModelOutput {
    case showLoading(Bool)
    case showError(Error)
    case updatePersonalInfo(PersonalUIModel)
    case showMessage(String)
    case reload
}

protocol PersonalInfoViewModelDelegate: ViewModelDelegate {
    func handleViewModelOutput(_ output: PersonalInfoViewModelOutput)
}

protocol PersonalInfoCoordinatorDelegate: AnyObject {
    func openChangePassword()
    func userDelete()
}
