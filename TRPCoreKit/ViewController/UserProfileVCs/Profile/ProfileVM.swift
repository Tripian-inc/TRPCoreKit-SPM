//
//  ProfileVM.swift
//  TRPUserProfileKit
//
//  Created by Evren Yaşar on 16.09.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation



protocol ProfileVMDelegate:AnyObject {
    func profileVM(showPreloader:Bool)
    func profileVM(error:Error)
    func profileVM(dataLoaded:Bool)
    func profileVM(message:String)
    func profileVMUserPreferences(_ data: [Int])
}


public class ProfileVM {
    
    var myMenu: [ProfileMenu] = []
    var userInfo = [(String,String)]()
    
    weak var delegate: ProfileVMDelegate?
    var selectedItemIds = [Int]()
    var appInfo = [String:String]()
    
    public var fetchUserInfoUseCase: FetchUserInfoUseCase?
    public var updateUserInfoUseCase: UpdateUserInfoUseCase?
    
    public init(appInfo: [String:String]? = nil) {
        
        self.appInfo = appInfo ?? [:]
        myMenu.append(ProfileMenu(id: 1,name: "Your E-mail", menuType: .label))
        myMenu.append(ProfileMenu(id: 2,name: "Edit Profile", menuType: .normal, icon:"profile_edit"))
        myMenu.append(ProfileMenu(id: 3,name: "Travel Companions", menuType: .button, icon:"profile_companion"))
        myMenu.append(ProfileMenu(id: 4,name: "Change Password", menuType: .button, icon:"profile_password"))
        myMenu.append(ProfileMenu(id: 5,name: "Help Desk", menuType: .normal, icon:"profile_help_desk"))
        myMenu.append(ProfileMenu(id: 7,name: "About App", menuType: .normal, icon:"profile_about"))
        myMenu.append(ProfileMenu(id: 6,name: "Sign Out", menuType: .normal, icon:"profile_logout"))
    }
    
    func getDataCount() -> Int {
        return myMenu.count
    }
    
    func getItem(indexPath: IndexPath) -> ProfileMenu {
        return myMenu[indexPath.row]
    }
    
    func start() {
        delegate?.profileVM(showPreloader: true)
        
        fetchUserInfoUseCase?.executeFetchUserInfo { [weak self] result in
            self?.delegate?.profileVM(showPreloader: false)
            switch(result) {
            case .success(let userInfo):
                self?.userInfo.append((userInfoNames.email.rawValue, userInfo.email))
                self?.delegate?.profileVM(dataLoaded: true)
            case .failure(let error):
                self?.delegate?.profileVM(error: error)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func getUserInfo(_ val: String) -> String{
        return userInfo.first(where: {$0.0 == val})?.1 ?? ""
    }
    
    func isItemSelected(id: Int) -> Bool {
        return selectedItemIds.contains(id)
    }
    
    func itemIsSelected(id: Int) {
        if selectedItemIds.contains(id) == false {
            selectedItemIds.append(id)
        }
        
    }
    
    func itemIsDeselected(id: Int) {
        if selectedItemIds.contains(id) {
            if let index = selectedItemIds.firstIndex(of: id) {
                selectedItemIds.remove(at: index)
            }
        }
    }
    
    func updatePassword(pass: String) -> Void {
        delegate?.profileVM(showPreloader: true)
        
        updateUserInfoUseCase?.executeUpdateUserInfo(password: pass, completion: { [weak self] result in
            self?.delegate?.profileVM(showPreloader: false)
            switch result {
            case .success(_):
                self?.delegate?.profileVM(message: "Your information is successfully updated!")
            case .failure(let error):
                self?.delegate?.profileVM(error: error)
            }
        })
        
        
    }
}

enum userInfoNames : String, CaseIterable {
    case password,firstName,lastName,age,answers,saveChanges,email,edit,signout,helpdesk
}

public enum ProfileMenuType {
    case title, normal,textField,label,button,checklist
}



public struct ProfileMenu {
    let id: Int
    let menuType: ProfileMenuType
    let name: String
    var icon: String?
    
    init(id: Int, name: String? = "", menuType: ProfileMenuType, icon: String? = nil) {
        self.id = id
        self.menuType = menuType
        self.name = name ?? ""
        self.icon = icon
    }
}

