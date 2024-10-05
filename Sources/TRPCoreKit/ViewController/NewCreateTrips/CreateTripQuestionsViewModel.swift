//
//  CreateTripQuestionsViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 14.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation
import TRPDataLayer

class CreateTripQuestionsViewModel {
    
    let lunchQuestionId = 11
    let dinnerQuestionId = 1111
    let beenBeforeQuestionId = 4
    let restaurantPreferId = 99999
    let exploreQuestionId = 6
    
    var isEditing: Bool = false
    
    internal var tripProfile: TRPTripProfile?
    public var tripQuestionUseCase: FetchTripQuestionsUseCase?
    
    var sectionModels: [SelectableQuestionModelNew] = []
    
    internal var selectedItems: [Int] = []
    
    init(tripProfile: TRPTripProfile, oldTripProfile: TRPTripProfile? = nil) {
        self.tripProfile = tripProfile
        implementTripProfile(oldTripProfile)
    }
    
    public func getSectionCount() -> Int {
        return sectionModels.count
    }
    
    public func getSectionModel(section: Int) -> SelectableQuestionModelNew {
        sectionModels[section]
    }
    
    public func getSectionTitle(section: Int) -> String {
        sectionModels[section].headerTitle
    }
    
    
    public func getCellCount(section: Int) -> Int {
        sectionModels[section].answers.count
    }
    
    public func getCellModel(at indexPath: IndexPath) -> SelectableAnswer {
        return sectionModels[indexPath.section].answers[indexPath.row]
    }
    
    public func isSelectedQuesion(id: Int) -> Bool {
        return selectedItems.contains(id)
    }
}

extension CreateTripQuestionsViewModel {
    
    internal func convertQuestionModelToSelectableModel(_ model: TRPQuestion, cellType: SelectableQuestionCellType = .withDescription, headerTitle: String? = nil) -> SelectableQuestionModelNew? {
        let name = headerTitle ?? model.name
        let skippable = model.skippable
        let multiple = model.selectMultiple
        guard let answers = model.answers else {return nil}
        let selectableAnswers = answerToSelectable(answers)
        return SelectableQuestionModelNew(id: model.id,
                                          headerTitle: name,
                                          answers:  selectableAnswers,
                                          skipable: skippable,
                                          selectMultiple: multiple,
                                          cellType: cellType)
        
    }
    
    internal func answerToSelectable(_ answers: [TRPQuestionAnswer]) -> [SelectableAnswer] {
        var selectableAnswers = [SelectableAnswer]()
//        let sortedAnswers = answers.sorted { $0.id < $1.id}
        for answer in answers {
            var sub: [SelectableAnswer]?
            
            if let subAnswers = answer.subAnswers {
                sub = subAnswers.map({SelectableAnswer(id:$0.id, name:$0.name, subAnswers: nil, isSubAnswers: true, description: $0.description)})
            }
            selectableAnswers.append(SelectableAnswer(id: answer.id, name: answer.name, subAnswers: sub, description: answer.description))
        }
        return selectableAnswers
    }
}

extension CreateTripQuestionsViewModel {
    
    func implementTripProfile(_ tripProfile: TRPTripProfile?) {
        guard let profile = tripProfile else {return}
        self.selectedItems = profile.allAnswers ?? []
        self.isEditing = true
    }
 
    @objc func checkSubAnswersForEditTrip() {
        guard !selectedItems.isEmpty else {return}
        var tempQuestion = [SelectableQuestionModelNew]()
        for section in sectionModels {
            var tempSection = section
            tempSection.answers = []
            for answer in section.answers {
                tempSection.answers.append(answer)
                if selectedItems.contains(where: {$0 == answer.id}), answer.isSubAnswers == false, let subAnswers = answer.subAnswers {
                    tempSection.answers.append(contentsOf: subAnswers)
                }
            }
            tempQuestion.append(tempSection)
        }
        sectionModels = tempQuestion
    }
    
}


extension CreateTripQuestionsViewModel {
    
    public func setTripProperties() {
        guard let tripProfile = tripProfile else {return}
        if tripProfile.tripAnswers == nil {
            tripProfile.tripAnswers = []
        }
        tripProfile.tripAnswers?.append(contentsOf: selectedItems)
        tripProfile.tripAnswers = tripProfile.tripAnswers?.unique()
    }
}


public struct SelectableQuestionModelNew {
    var id: Int
    var headerTitle: String
    var answers  = [SelectableAnswer]()
    var skipable = false
    var selectMultiple = false
    var isPace = false
    var cellType: SelectableQuestionCellType = .restaurant
    var subModels = [SelectableQuestionModelNew]()
}
public enum SelectableQuestionCellType {
    case withDescription, restaurant, checkbox
}
