//
//  UserPreferenceViewModel.swift
//  TRPUserProfileKit
//
//  Created by Evren Yaşar on 18.09.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation



struct UserPreferenceModel {
    var id:Int
    var name:String
    
    init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}
public protocol UserPreferenceVMDelegate:AnyObject {
    func userPreferenceVM(dataLoaded:Bool)
    func userPreferenceVM(showPreloader:Bool)
    func userPreferenceVM(error:Error)
    func userPreferenceVM(message:String)
    func userPreferanceVM(data: [Int])
}

public class UserPreferenceViewModel {
    
    typealias section = (String, [UserPreferenceModel])
    var selectedItemIds = [Int]()
    var data = [section]()
    weak var delegate: UserPreferenceVMDelegate?
    
    
    public var fetchProfileQuestionsUseCase: FetchProfileQuestionsUseCase?
    public var userAnswerUseCase: UserAnswersUseCase?
    public var updateUserInfoUseCase: UpdateUserInfoUseCase?
    
    public init() {}
    
    func fetchDataFromServer() {
        delegate?.userPreferenceVM(showPreloader: true)
        fetchProfileQuestionsUseCase?.executeProfileQuestions { [weak self] result in
            guard let strongSelf = self else {return}
            strongSelf.delegate?.userPreferenceVM(showPreloader: false)
            
            switch(result) {
            case .success(let questions):
                for child in questions {
                    var userPrefs = [UserPreferenceModel]()
                    for op in child.answers ?? [] {
                        userPrefs.append(UserPreferenceModel(id: op.id, name: op.name))
                    }
                    strongSelf.data.append(section(child.name, userPrefs))
                    strongSelf.delegate?.userPreferenceVM(dataLoaded: true)
                }
            case .failure(let error):
                strongSelf.delegate?.userPreferenceVM(error: error)
            }
        }
        
    }
    
    
    func start() {
        fetchDataFromServer()
        
        userAnswerUseCase?.executeUserAnswers(completion: { [weak self] result  in
            guard let strongSelf = self else {return}
            
            switch result {
            case .success(let answers):
                strongSelf.selectedItemIds = answers
                strongSelf.delegate?.userPreferanceVM(data: answers)
                strongSelf.delegate?.userPreferenceVM(dataLoaded: true)
            case .failure(let error):
                strongSelf.delegate?.userPreferenceVM(error: error)
            }
        })
    }
    
    func sectionCount() -> Int {
        return data.count
    }
    
    func sectionTitle(_ sectionId :Int) -> String {
        return data[sectionId].0
    }
    
    func numberOfRowInSection(_ section: Int) -> Int {
        return data[section].1.count
    }
    
    func cellInfo(_ indexPath: IndexPath) -> UserPreferenceModel {
        return data[indexPath.section].1[indexPath.row]
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
    
    func updateAnswer() -> Void {
        self.delegate?.userPreferenceVM(showPreloader: true)
        
        updateUserInfoUseCase?.executeUpdateUserInfo(answers: selectedItemIds, completion: { [weak self] result in
            self?.delegate?.userPreferenceVM(showPreloader: false)
            switch result {
            case .success(_):
                self?.delegate?.userPreferenceVM(message: "Successfully updated.")
            case .failure(let error):
                self?.delegate?.userPreferenceVM(error: error)
            }
        })
    }
    
}
