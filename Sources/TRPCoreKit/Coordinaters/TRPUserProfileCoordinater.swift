//
//  TRPUserProfileCoordinater.swift
//  TRPUserProfileKit
//
//  Created by Evren Yaşar on 17.09.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import UIKit
import TRPRestKit
import TRPUIKit
import TRPFoundationKit
import TRPDataLayer

public protocol TRPUserProfileCoordinaterDelegate:AnyObject {
    func trpUserProfileSignOut()
    func trpUserDelete()
}

public class TRPUserProfileCoordinater {
    
    private let navigationController: UINavigationController
    public var appInfo: [String:String]? = nil
    public weak var delegate: TRPUserProfileCoordinaterDelegate?
    private var travelCompanionList: TravelCompanionsListVC?
    
    private var tripCreateCoordinater: TRPCreateTripCoordinater?
    
    //Use Cases
    public var questionUseCases: TRPQuestionsUseCases?
    public var userInfoUseCases: TRPUserInfoUseCases?
    public var companionUseCases: TRPCompanionUseCases?
    
    
    public init(_ navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    public func start() {
        openProfileVC()
    }
    
    deinit {
        print("TRPUserCoordinater deinit")
    }
    
}


// MARK: - ProfileVC
extension TRPUserProfileCoordinater: UserProfileViewControllerDelegate {
    
    fileprivate func openProfileVC() {
        let viewController = UIStoryboard.makeUserProfileViewController()
        viewController.userProfileDelegate = self
        let viewModel = UserProfileViewModel()
        viewModel.fetchUserInfoUseCase = userInfoUseCases
        viewModel.logoutUseCase = userInfoUseCases
        
        viewModel.delegate = viewController
        viewController.viewModel = viewModel
        
        navigationController.pushViewController(viewController, animated: true)
//        viewModel.start()
    }
    
    func userProfileHandle(_ output: UserProfileOpenViewOutput) {
        switch output {
        case .personalInfo:
            openPersonalInfo()
        case .companion:
            openTravelCompanions()
        case .logOut:
            profileVCSignOut()
//        case .changePassword:
//            navigationController?.present(makeChangePasswordCoordinator(), animated: true, completion: nil)
        }
    }
    
//    func profileVCOpenView(selectedItem: ProfileMenu) {
//        if selectedItem.id == 2{ //Edit Profile
//            openEditProfile()
//        }
//        else if selectedItem.id == 3{ //Travel Companions
//            openTravelCompanions()
//        }
//    }
    
    func profileVCSignOut() {
        delegate?.trpUserProfileSignOut()
    }
    
    func profileVCUserPreferances(data: [Int]) {
        
    }
}

//MARK: - Personal Information
extension TRPUserProfileCoordinater: PersonalInfoCoordinatorDelegate {
    private func openPersonalInfo() {
        navigationController.pushViewController(makePersonalCoordinator(), animated: true)
    }
    
    private func makePersonalCoordinator() -> PersonalInfoViewController {
        let viewController = UIStoryboard.makePersonalInfoViewController()
        let viewModel = PersonalInfoViewModel()
        viewModel.delegate = viewController
        viewModel.coordinatorDelegate = self
        viewController.viewModel = viewModel
        viewModel.updateUserInfoUseCase = userInfoUseCases
        viewModel.fetchUserInfoUseCase = userInfoUseCases
        viewModel.trpUserQuestionsUseCases = questionUseCases
        viewModel.deleteUserUseCase = userInfoUseCases
//        viewModel.trpUserInfoUseCases = trpUserInfoUseCases
        return viewController
    }
    
    func openChangePassword() {
        navigationController.present(makeChangePasswordCoordinator(), animated: true)
    }
    
    func userDelete() {
        delegate?.trpUserDelete()
    }
    
    private func makeChangePasswordCoordinator() -> ChangePasswordViewController {
        let viewController = UIStoryboard.makeChangePasswordViewController()
        let viewModel = ChangePasswordViewModel()
        viewModel.delegate = viewController
        viewController.viewModel = viewModel
        viewModel.updateUserInfoUseCase = userInfoUseCases
        return viewController
    }
}

//MARK: - Companions
extension TRPUserProfileCoordinater {
    
//    private func travelCompanion() {
//        companionUseCases?.executeFetchCompanion(completion: nil)
//    }
//
//    private func openCompanion() {
//
//        guard let nav = navigationController else {return}
//        travelCompanion()
//        let tripianNav = UINavigationController()
//        tripianNav.modalPresentationStyle = .fullScreen
//        tripianNav.navigationBar.setWiserrBar()
//        tripCreateCoordinater = TRPCreateTripCoordinater(navigationController: tripianNav)
//        tripCreateCoordinater?.companionUseCases = companionUseCases
//        tripCreateCoordinater?.startTravelCompanion(fromSDK: true)
//        nav.present(tripianNav, animated: true, completion: nil)
//    }
}

// MARK: - EditProfileVC
extension TRPUserProfileCoordinater: EditProfileVCDelegate {
    
    fileprivate func openEditProfile() {
        let viewModel = EditProfileVM()
        viewModel.updateUserInfoUseCase = userInfoUseCases
        viewModel.fetchUserInfoUseCase = userInfoUseCases
        
        let viewController = EditProfileVC(viewModel: viewModel)
        viewModel.delegate = viewController
        viewController.delegate = self
        
        navigationController.pushViewController(viewController, animated: true)
    }
    
    public func editProfileVCOpenView(selectedItem: ProfileMenu) {
        //Fixme: - hatalı kod .normal yerine tripi gelmi.
        if selectedItem.menuType == .normal{
            openProfileAnswers()
        }
    }
    
    public func editProfileVCUserProfile(data: [Int]) {}
    
}

extension TRPUserProfileCoordinater:UserPreferenceVCDelegate {
  
    fileprivate func openProfileAnswers() {
        let viewModel = UserPreferenceViewModel()
        viewModel.fetchProfileQuestionsUseCase = questionUseCases
        viewModel.userAnswerUseCase = userInfoUseCases
        viewModel.updateUserInfoUseCase = userInfoUseCases
        
        let viewController = UserPreferenceVC(viewModel: viewModel)
        viewController.delegate = self
        viewModel.delegate = viewController
        viewModel.start()
        navigationController.pushViewController(viewController, animated: true)
    }
    
    func userPreferanceVCSelectedUserPreferance(data: [Int]) {
        
    }
    
}

// MARK: - TravelCompanions
extension TRPUserProfileCoordinater {
    
    
    private func openTravelCompanions() {
        let tripianNav = UINavigationController()
        tripianNav.modalPresentationStyle = .fullScreen
        tripCreateCoordinater = TRPCreateTripCoordinater(navigationController: tripianNav)
        tripCreateCoordinater?.companionUseCases = companionUseCases
        tripCreateCoordinater?.startTravelCompanion(fromProfile: true)
        navigationController.present(tripianNav, animated: true, completion: nil)
    }
//    fileprivate func openTravelCompanions() {
//        let viewModel = TravelCompanionsVM()
//        viewModel.fetchCompanionUseCase = companionUseCases
//        viewModel.observeCompanionUseCase = companionUseCases
//        viewModel.deleteCompanionUseCase = companionUseCases
//
//        travelCompanionList = TravelCompanionsListVC(viewModel: viewModel)
//        viewModel.delegate = travelCompanionList
//        viewModel.start()
//        travelCompanionList!.delegate = self
//        navigationController.pushViewController(travelCompanionList!, animated: true)
//    }
    
//    public func openCompanionDetailView(parentVC: UIViewController, withCompanion: TRPCompanion) {
//        openCompanionDetailVC(parentVC: parentVC, type: .updateCompanion, companion: withCompanion)
//    }
//
//    public func openAddCompanionView(parentVC: UIViewController) {
//        openCompanionDetailVC(parentVC: parentVC, type: .addCompanion)
//    }
    
}

extension TRPUserProfileCoordinater: CompanionDetailVCDelegate  {
    
    func openCompanionDetailVC(parentVC: UIViewController, type: CompanionDetailType, companion: TRPCompanion? = nil) {
        let viewModel = CompanionDetailVM()
        viewModel.addCompanionUseCase = companionUseCases
        viewModel.updateCompanionUseCase = companionUseCases
        viewModel.fetchCompanionQuestionUseCase = questionUseCases
        
        let viewController = UIStoryboard.makeCompanionDetailViewController() as CompanionDetailVC
        
        viewController.viewModel = viewModel
        viewModel.detailType = type
        viewModel.delegate = viewController
        viewController.delegate = self
                
        if type == .updateCompanion {
            guard let companion = companion else {return}
            viewModel.currentCompanion = companion
        }
        viewModel.start()
        parentVC.present(viewController, animated: false, completion: nil)
    }
    
    public func companionDetailVCAdded(_ companion: TRPCompanion) {
        EvrAlertView.showAlert(contentText: "Successfully added.".toLocalized(), type: .success)
    }
    
    public func companionDetailVCUpdated() {
        EvrAlertView.showAlert(contentText: "Successfully updated.".toLocalized(), type: .success)
    }
    
}


extension TRPUserProfileCoordinater {
    private func setNavigationStyleFor(_ nav: UINavigationController) {
        nav.navigationBar.barStyle = .blackTranslucent
        nav.navigationBar.barTintColor = TRPAppearanceSettings.Common.navigationBarTintColor
        nav.navigationBar.tintColor = TRPAppearanceSettings.Common.navigationTintColor
        nav.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: TRPAppearanceSettings.Common.navigationTitleTextColor]
    }
}
