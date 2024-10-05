//
//  CompanionDetailVM.swift
//  TRPAddTravelCompanionsKit
//
//  Created by Evren Yaşar on 25.09.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//
import Foundation
import TRPRestKit
import TRPUIKit
import TRPDataLayer

//struct UserPreference {
//    var id:Int
//    var name:String
//    
//    init(id: Int, name: String) {
//        self.id = id
//        self.name = name
//    }
//}

public enum MenuType {
    case title, normal,textField,label,button,checklist
}


public protocol CompanionDetailVMDelegate: AnyObject {
    func companionDetailShowMessage(_ message: String)
    func companionsDetailCompanionAdded(_ companion: TRPCompanion)
    func companionsDetailCompanionUpdated()
    func companionsDetaionVM(showPreloader:Bool)
    func companionsDetaionVM(error:Error)
    func companionsDetaionVM(dataLoaded:Bool)
}

public class CompanionDetailVM {
    //MARK: - Variables
    var sectionModels: [CompanionDetailSectionModel] = []
    public weak var delegate: CompanionDetailVMDelegate?
    
    private final let titleSectionId = 889900
    private final let nameSectionId = 1
    private final let ageSectionId = 2
    private final let titleSectionName = "Title"
    private final let nameSectionName = "Name"
    private final let ageSectionName = "Age"
    var titleQuestions: [PersonalPreference] = [
        .init(id: 889911, name: "Family member"),
        .init(id: 889912, name: "Friend"),
        .init(id: 889913, name: "Work colleague")
    ]
    
    public var detailType: CompanionDetailType = .addCompanion
    public var currentCompanion: TRPCompanion?
    
    public var fetchCompanionQuestionUseCase: FetchCompanionQuestionsUseCase?
    public var addCompanionUseCase: AddCompanionUseCase?
    public var updateCompanionUseCase: UpdateCompanionUseCase?
    
    var selectedTitleItemIds = [Int]()
    var selectedQuestionItemIds = [Int]()
    
    public init() {
        addTitleInQuestions()
        addTextFields()
    }
    
    func start() {
        fetchTripQuestions()
        setCurrentCompanion()
    }
    
    
    var isUpdateType: Bool {
        return detailType == .updateCompanion
    }
    
    func getSelectedItemIds(menuId: Int) -> [Int]{
        guard menuId == titleSectionId else {
            return selectedQuestionItemIds
        }
        return selectedTitleItemIds
    }
    
//    func isItemSelected(id: Int) -> Bool {
//        return selectedItemIds.contains(id)
//    }
    
    func itemIsSelected(id: Int, menuId: Int) {
        if menuId == titleSectionId {
            if !selectedTitleItemIds.contains(id) {
                selectedTitleItemIds.append(id)
            }
        } else {
            if !selectedQuestionItemIds.contains(id) {
                selectedQuestionItemIds.append(id)
            }
        }
    }
    
    func itemIsDeselected(id: Int, menuId: Int) {
        if menuId == titleSectionId {
            if selectedTitleItemIds.contains(id) {
                if let index = selectedTitleItemIds.firstIndex(of: id) {
                    selectedTitleItemIds.remove(at: index)
                }
            }
        } else {
            if selectedQuestionItemIds.contains(id) {
                if let index = selectedQuestionItemIds.firstIndex(of: id) {
                    selectedQuestionItemIds.remove(at: index)
                }
            }
        }
    }
    
    func isNumberEditable(menuId: Int) -> Bool {
        return menuId == ageSectionId
    }
    
    func setCompanionName(name: String) {
        currentCompanion?.name = name
    }
    
    func setCompanionAge(age: Int) {
        currentCompanion?.age = age
    }
    
    func getSelectedTitle() -> PersonalPreference? {
        for child in titleQuestions {
            if selectedTitleItemIds.contains(child.id) {
                return child
            }
        }
        return nil
    }
    
    func saveChanges() {
        if isUpdateType {
            updateCompanion()
        } else {
            addCompanion()
        }
    }
    
    func getCompanionName() -> String {
        guard let currentCompanion = currentCompanion else {return ""}
        return currentCompanion.name
    }
    
}

//Setup
extension CompanionDetailVM {
    
    private func setCurrentCompanion() {
        if isUpdateType {
            setForUpdate()
        } else {
            currentCompanion = TRPCompanion(id: 1, name: "", answers: [], title: nil, age: nil)
        }
    }
    
    private func addTextFields(){
        let nameCell = CompanionDetailMenu(menuId: nameSectionId, name: "Type name", menuType: .textField, value: "", companionPrefs: [PersonalPreference(id: 1, name: "Name")])
        let nameSection = CompanionDetailSectionModel(title: nameSectionName, cells: [nameCell])
        sectionModels.append(nameSection)
        let ageCell = CompanionDetailMenu(menuId: ageSectionId, name: "Type age", menuType: .textField, value: "", companionPrefs: [PersonalPreference(id: 2, name: "Age")])
        let ageSection = CompanionDetailSectionModel(title: ageSectionName, cells: [ageCell])
        sectionModels.append(ageSection)
    }
    
    private func addTitleInQuestions() {
        let cell = CompanionDetailMenu(menuId: titleSectionId,
                                       name: "Title",
                                       menuType: .checklist,
                                       value: "",
                                       companionPrefs: titleQuestions,
                                       selectMultiple: false,
                                       skippable: false)
        let section = CompanionDetailSectionModel(title: titleSectionName, cells: [cell])
        sectionModels.append(section)
    }
}

//TableView Functions
extension CompanionDetailVM {
    
    
    func getSectionCount() -> Int{
        return sectionModels.count
    }
    
    func getCellCount(section: Int) -> Int{
        return sectionModels[section].cells.count
    }
    
    func getSectionTitle(section: Int) -> String {
        return sectionModels[section].title
    }
    
    func getCellModel(at indexPath: IndexPath) -> CompanionDetailMenu {
        return sectionModels[indexPath.section].cells[indexPath.row]
    }
    
//    func getItem(indexPath: IndexPath) -> CompanionDetailMenu {
//        return companionDetailMenu[indexPath.row]
//    }
//
//    func rowCount() -> Int {
//        return companionDetailMenu.count
//    }
//
//    func sectionType(_ indexPath: IndexPath) -> MenuType {
//        return companionDetailMenu[indexPath.section].menuType
//    }
//
//
//    func cellInfo(_ indexPath: IndexPath) -> PersonalPreference {
//        return companionDetailMenu[indexPath.section].companionPrefs?[indexPath.row] ?? PersonalPreference(id: 0, name: "wrong")
//    }
}

//UseCases
extension CompanionDetailVM {
    
    
    private func fetchTripQuestions() {
        
        delegate?.companionsDetaionVM(showPreloader: true)
        
        fetchCompanionQuestionUseCase?.executeCompanionQuestions(completion: { [weak self] result in
            guard let strongSelf = self else {return}
            strongSelf.delegate?.companionsDetaionVM(showPreloader: false)
            
            switch(result) {
            case .success(let questions):
                strongSelf.addCompanionQuestionToModels(questions)
            case .failure(let error):
                strongSelf.delegate?.companionsDetaionVM(error: error)
            }
        })
        
    }
    
    private func addCompanionQuestionToModels(_ questions: [TRPQuestion]) {
        for child in questions {
            let name = child.name
            var userPrefs = [PersonalPreference]()
            for op in child.answers ?? [] {
                userPrefs.append(PersonalPreference(id: op.id, name: op.name))
            }
            
            let questionCell = CompanionDetailMenu(menuId: child.id,
                                                   name: name,
                                                   menuType: .checklist,
                                                   value: "",
                                                   companionPrefs: userPrefs,
                                                   selectMultiple: child.selectMultiple,
                                                   skippable: child.skippable)
//            var sectionModel = sectionModels.first(where: {$0.title == name})
//            if sectionModel != nil {
//                sectionModel?.cells.append(questionCell)
//            } else {
                let questionSection = CompanionDetailSectionModel(title: name, cells: [questionCell])
                sectionModels.append(questionSection)
//            }
            
        }
        delegate?.companionsDetaionVM(dataLoaded: true)
//        companionDetailMenu.append(CompanionDetailMenu(menuId: child.id, name: name, menuType: .checklist, value: "",companionPrefs: userPrefs,selectMultiple: child.selectMultiple,skippable: child.skippable))
    }
    
    func addCompanion() {
        //self.delegate?.viewModel(showPreloader: true)
        self.delegate?.companionsDetaionVM(showPreloader: true)
        
        guard let currentCompanion = currentCompanion, let title = getSelectedTitle()?.name else {
            return
        }
        
        addCompanionUseCase?.executeAddCompanion(name: currentCompanion.name,
                                                 title: title,
                                                 answers: selectedQuestionItemIds,
                                                 age: currentCompanion.age ?? 0,
                                                 completion: { [weak self] result in
            guard let strongSelf = self else {return}
            strongSelf.delegate?.companionsDetaionVM(showPreloader: false)
            switch result {
            case .success(let companion):
                strongSelf.delegate?.companionsDetailCompanionAdded(companion)
            case .failure(let error):
                strongSelf.delegate?.companionsDetaionVM(error: error)
            }
        })
        
    }
}

//Update Companion
extension CompanionDetailVM {
    
    func setForUpdate() {
        guard let currentCompanion = currentCompanion else {return}
        
        if !currentCompanion.answers.isEmpty{
            setSelectedQuestionAnswers(currentCompanion.answers)
        }
        
        if let title = currentCompanion.title {
            setSelectedTitle(title)
        }
        
        let name = currentCompanion.name
        setName(name)
        
        if let age = currentCompanion.age{
            setAge(age)
        }
    }
    
    func setName(_ name: String){
        self.setValue(name, for: nameSectionName)
    }
    
    func setAge(_ age: Int){
        self.setValue("\(age)", for: ageSectionName)
    }
    
    private func setValue(_ value: String, for sectionTitle: String) {
        if let nameSectionRow = self.sectionModels.firstIndex(where: {$0.title == sectionTitle}) {
            self.sectionModels[nameSectionRow].cells[0].value = value
        }
    }
    
    func setSelectedTitle(_ title: String) {
        titleQuestions.forEach { (pref) in
            if pref.name.lowercased() == title.lowercased() {
                self.itemIsSelected(id: pref.id, menuId: titleSectionId)
            }
        }
    }
       
    func setSelectedQuestionAnswers(_ selectedAnswers: [Int]){
        self.selectedQuestionItemIds = selectedAnswers
        self.delegate?.companionsDetaionVM(dataLoaded: true)
    }
    
    func updateCompanion() -> Void {
        delegate?.companionsDetaionVM(showPreloader: true)
        
        guard let currentCompanion = currentCompanion, let title = getSelectedTitle()?.name else {
            return
        }
        
        updateCompanionUseCase?.executeUpdateCompanion(id: currentCompanion.id,
                                                    name: currentCompanion.name,
                                                    title: title,
                                                    answers: selectedQuestionItemIds,
                                                    age: currentCompanion.age,
                                                    completion: { [weak self] result in
            
            guard let strongSelf = self else {return}
            strongSelf.delegate?.companionsDetaionVM(showPreloader: false)
            switch result {
            case .success(_):
                strongSelf.delegate?.companionsDetailCompanionUpdated()
            case .failure(let error):
                strongSelf.delegate?.companionsDetaionVM(error: error)
            }
        })
    }
    
}

struct CompanionDetailSectionModel {
    var title: String
    var cells: [CompanionDetailMenu]
}

public struct CompanionDetailMenu {
    let menuId: Int
    let menuType: MenuType
    let name: String
    var value: String?
    var companionPrefs: [PersonalPreference]?
    var selectMultiple: Bool?
    var skippable: Bool?
    
    init(menuId: Int, name: String, menuType: MenuType, value: String? = "", companionPrefs: [PersonalPreference]? = [], selectMultiple: Bool? = false, skippable: Bool? = false) {
        self.menuId = menuId
        self.menuType = menuType
        self.name = name
        self.value = value
        self.companionPrefs = companionPrefs
        self.skippable = skippable
        self.selectMultiple = selectMultiple
    }
}

