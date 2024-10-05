//
//  PersonalInfoViewModel.swift
//  Wiserr
//
//  Created by Evren Yaşar on 2021-05-14.
//

import Foundation



struct PersonalPreference {
    var id:Int
    var name:String
    
    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

final class PersonalInfoViewModel: PersonalInfoViewModelProtocol {
    weak var delegate: PersonalInfoViewModelDelegate?
    var coordinatorDelegate: PersonalInfoCoordinatorDelegate?
    var fetchUserInfoUseCase: FetchUserInfoUseCase?
    var updateUserInfoUseCase: UpdateUserInfoUseCase?
    var deleteUserUseCase: DeleteUserUseCase?
    var trpUserQuestionsUseCases: TRPQuestionsUseCases?
    var trpUserInfoUseCases: TRPUserInfoUseCases?
    
    var selectedItemIds = [Int]()
    var questionsMenu: [QuestionsMenu] = []
    
    func start() {
        fetchUserInfo()
        fetchUserQuestions()
    }
    
    func save(firstName: String, lastName: String, dateOfBirth: String) {
        updateUser(firstName: firstName, lastName: lastName, dateOfBirth: dateOfBirth)
    }
    
    func handler(_ output: PersonalInfoViewModelOutput) {
        delegate?.handleViewModelOutput(output)
    }
    
    func openChangePassword() {
        coordinatorDelegate?.openChangePassword()
    }
    
    func getItem(indexPath: IndexPath) -> QuestionsMenu {
        return questionsMenu[indexPath.row]
    }
    
    func rowCount() -> Int {
        return questionsMenu.count
    }
    
    func itemIsSelected(id: Int) {
        if !selectedItemIds.contains(id) {
            selectedItemIds.append(id)
        }
    }
    
    func itemIsDeselected(id: Int) {
        selectedItemIds.remove(element: id)
    }
    
    func deleteAccount() {
        deleteUser()
    }
}

extension PersonalInfoViewModel {
    private func fetchUserInfo() {
        handler(.showLoading(true))
        fetchUserInfoUseCase?.executeFetchUserInfo(completion: { [weak self] result in
            guard let strongSelf = self else {return}
            strongSelf.handler(.showLoading(false))
            switch result {
            case .success(let user):
                let uiModel = PersonalUIModel(user)
                strongSelf.selectedItemIds.append(contentsOf: uiModel.answers)
                strongSelf.handler(.updatePersonalInfo(uiModel))
                strongSelf.handler(.reload)
            case .failure(let error):
                strongSelf.handler(.showError(error))
            }
        })
    }
    
    private func updateUser(firstName: String, lastName: String, dateOfBirth: String) {
        handler(.showLoading(true))
        
        updateUserInfoUseCase?.executeUpdateUserInfo(firstName: firstName,
                                                     lastName: lastName,
                                                     password: nil,
                                                     dateOfBirth: dateOfBirth,
                                                     answers: self.selectedItemIds,
                                                     completion: { [weak self] result in
            self?.handler(.showLoading(false))
            switch result {
            case .failure(let error):
                self?.handler(.showError(error))
            case .success(_):
                self?.handler(.showMessage("Your information is successfully updated!"))
            }
        })
    }
    
    private func deleteUser() {
        handler(.showLoading(true))
        deleteUserUseCase?.deleteUser(completion: { [weak self] result in
            self?.handler(.showLoading(false))
            switch result {
            case .failure(let error):
                self?.handler(.showError(error))
            case .success(_):
                TRPUserPersistent.remove()
                self?.coordinatorDelegate?.userDelete()
            }
        })
    }
}

extension PersonalInfoViewModel {
    private func fetchUserQuestions() {
        trpUserQuestionsUseCases?.executeProfileQuestions() { [weak self] result in
            guard let strongSelf = self else {return}
            strongSelf.handler(.showLoading(false))
            
            switch(result) {
            case .success(let questions):
                for child in questions {
                    let name = child.name
                    var userPrefs = [PersonalPreference]()
                    for op in child.answers ?? [] {
                        userPrefs.append(PersonalPreference(id: op.id, name: op.name))
                    }
                    
                    strongSelf.questionsMenu.append(QuestionsMenu(menuId: child.id, name: name ,questionPrefs: userPrefs,selectMultiple: child.selectMultiple,skippable: child.skippable))

                    strongSelf.handler(.reload)
                    
                }
            case .failure(let error):
                strongSelf.handler(.showError(error))
            }
        }
    }
}

public struct QuestionsMenu {
    let menuId: Int
    let name: String
    var questionPrefs: [PersonalPreference]?
    var selectMultiple: Bool?
    var skippable: Bool?
    
    init(menuId: Int, name: String, questionPrefs: [PersonalPreference]? = [], selectMultiple: Bool? = false, skippable: Bool? = false) {
        self.menuId = menuId
        self.name = name
        self.questionPrefs = questionPrefs
        self.skippable = skippable
        self.selectMultiple = selectMultiple
    }
}
