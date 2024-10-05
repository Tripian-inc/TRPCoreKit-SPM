//
//  UserProfileContract.swift
//  Wiserr
//
//  Created by Evren Yaşar on 2021-04-19.
//

import Foundation
protocol UserProfileViewModelProtocol {
    
    var delegate: UserProfileViewModelDelegate? {get set}
    
    func start()
}

enum UserProfileViewModelOutput {
    case showLoading(Bool)
    case showError(Error)
    case userName(String)
    case logOut
}

protocol UserProfileViewModelDelegate: AnyObject {
    func handleViewModelOutput(_ output: UserProfileViewModelOutput)
}

enum UserProfileOpenViewOutput {
    case companion
    case personalInfo
    case logOut
}

protocol UserProfileViewControllerDelegate: AnyObject {
    func userProfileHandle(_ output: UserProfileOpenViewOutput)
}

protocol UserProfileViewModelCoordinatorDelegate: AnyObject {
    func userProfileOpenPoiFromOfferHistory(_ poiId: String)
    func logOut()
}
