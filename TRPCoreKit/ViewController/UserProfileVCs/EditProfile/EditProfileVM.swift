//
//  EditProfileVM.swift
//  TRPUserProfileKit
//
//  Created by Evren Yaşar on 16.09.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation



protocol EditProfileVMDelegate:AnyObject {
    func editProfileVM(showPreloader:Bool)
    func editProfileVM(error: Error)
    func editProfileVM(dataLoaded: Bool)
    func editProfileVM(message: String)
    func editProfileVMUserProfile(data:[Int])
}

public class EditProfileVM {
    
    var myMenu: [ProfileMenu] = []
    var userInfo = [(String,String)]()
    weak var delegate: EditProfileVMDelegate?
    var selectedItemIds = [Int]()
    
    public var fetchUserInfoUseCase: FetchUserInfoUseCase?
    public var updateUserInfoUseCase: UpdateUserInfoUseCase?
    
    
    init() {
        myMenu.append(ProfileMenu(id: 1,name: "First Name", menuType: .textField))
        myMenu.append(ProfileMenu(id: 2,name: "Last Name", menuType: .textField))
        myMenu.append(ProfileMenu(id: 3,name: "Age", menuType: .textField))
        myMenu.append(ProfileMenu(id: 4,name: "My Preferences", menuType: .normal))
    }
    
    func getDataCount() -> Int {
        return myMenu.count
    }
    
    func getItem(indexPath: IndexPath) -> ProfileMenu {
        return myMenu[indexPath.row]
    }
    
    func start() {
        fetchUserInfoUseCase?.executeFetchUserInfo(completion: { [weak self] result in
            guard let strongSelf = self else {return}
            strongSelf.userInfo.removeAll()
            
            switch result {
            case .success(let info):
                if let firstName = info.firstName{
                    strongSelf.userInfo.append((userInfoNames.firstName.rawValue, firstName))
                }
                if let lastName = info.lastName{
                    strongSelf.userInfo.append((userInfoNames.lastName.rawValue, lastName))
                }
//                if let age = info.profile?.age {
//                    strongSelf.userInfo.append((userInfoNames.age.rawValue, "\(age)")) //Age sonrasinda buraya eklenebilir, yeniden update atmaya gerek kalmasin diye ekliyorum.
//                }
                strongSelf.userInfo.append((userInfoNames.email.rawValue, info.email))
                strongSelf.delegate?.editProfileVM(dataLoaded: true)
            case .failure(let error):
                strongSelf.delegate?.editProfileVM(error: error)
            }
        })
       
    }
    
    func getUserInfo(_ val: Int) -> String{
        guard val < userInfo.count else {return ""}
        return userInfo[val-1].1  //first(where: {$0.0.lowercased().contains(val.lowercased().prefix(4))})?.1 ?? ""
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
    
    func updateUserInfo(firstName: String?,
                        lastName: String?,
                        dateOfBirth: String?) -> Void {
        self.delegate?.editProfileVM(showPreloader: true)
        
        updateUserInfoUseCase?.executeUpdateUserInfo(firstName: firstName,
                                                     lastName: lastName,
                                                     dateOfBirth: dateOfBirth,
                                                     completion: { [weak self] result in
            self?.delegate?.editProfileVM(showPreloader: false)
            switch result {
            case .failure(let error):
                self?.delegate?.editProfileVM(error: error)
            case .success(_):
                self?.delegate?.editProfileVM(message: "Your information is successfully updated!")
                self?.delegate?.editProfileVM(dataLoaded: true)
            }
        })
       
    }
}
