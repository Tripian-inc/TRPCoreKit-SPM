//
//  TripQuestionViewModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 23.06.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPDataLayer


protocol TripQuestionViewModelDelegate: ViewModelDelegate  { }

enum QuestionHeaderType {
    case small
    case normal
}

public struct SelectableQuestionModel {
    var id: Int
    var questionCategory: String
    var answers  = [SelectableAnswer]()
    var skipable = false
    var selectMultiple = false
    var isPace = false
    var headerType: QuestionHeaderType = .normal
}

public struct SelectableAnswer {
    var id: Int
    var name: String
    var subAnswers: [SelectableAnswer]?
    var isSubAnswers: Bool = false
    var description: String?
}


class TripQuestionViewModel {
    
    public weak var delegate: TripQuestionViewModelDelegate?
    private(set) var selectableQuestions = [SelectableQuestionModel]()
    private var paceQuestion: SelectableQuestionModel?
    
    private var selectedItems: [Int] = []
    
    private(set) var selectedPace: TRPPace = .normal
    private var tripProfile: TRPTripProfile?
    
    private let slowPace = SelectableAnswer(id:TRPPace.slow.id(), name: TRPPace.slow.displayName())
    private let normalPace = SelectableAnswer(id:TRPPace.normal.id(), name:TRPPace.normal.displayName())
    private let fastPace = SelectableAnswer(id:TRPPace.fast.id(), name:TRPPace.fast.displayName())
    
    public var tripQuestionUseCase: FetchTripQuestionsUseCase?
    let lunchQuestionId = 11
    let dinnerQuestionId = 1111
    
    
    
    
    init(tripProfile: TRPTripProfile, oldTripProfile: TRPTripProfile? = nil) {
        self.tripProfile = tripProfile
        implementTripProfile(oldTripProfile)
    }
    
    public func start() {
        fetchTripQuestions()
    }
    
    public func getCurrentStep() -> String {
        return "3"
    }
    
    func getSectionCount() -> Int {
        return selectableQuestions.count
    }
    
    func getSectionModel(section: Int) -> SelectableQuestionModel {
        selectableQuestions[section]
    }
    
    func getCellCount(section: Int) -> Int {
        selectableQuestions[section].answers.count
    }
    
    func getCellModel(at indexPath: IndexPath) -> SelectableAnswer {
        return selectableQuestions[indexPath.section].answers[indexPath.row]
    }
    
    func shouldAllowSelectionAt(_ section: Int) -> Bool {
        return getSectionModel(section: section).selectMultiple
    }
    
    func getSingleSelectedItemIndexIn(section: Int) -> Int? {
        for (index, quesion) in selectableQuestions[section].answers.enumerated() {
            if selectedItems.contains(quesion.id) {
                return index
            }
        }
        
        return nil
    }
    
    
    public func addPaceQuesions() {
       /* paceQuestion = SelectableQuestionModel(questionCategory: "Daily Pace",
                                               options: [slowPace, normalPace, fastPace],
                                               skipable: false,
                                               selectMultiple: false,
                                               isPace: true) */
        
    }
    
    
    public func selectedAnswers(at indexPath: IndexPath) {
        let answer = selectableQuestions[indexPath.section].answers[indexPath.row]
        
        if !selectedItems.contains(answer.id) {
            addSelectedItem(id: answer.id)
            delegate?.viewModel(dataLoaded: true)
            if let sub = answer.subAnswers, let firstAnswer = sub.first {
                //eğer eklenmişse bir daha ekelemz
                if selectableQuestions[indexPath.section].answers.contains(where: {$0.id == firstAnswer.id}) {return}
                
                for (i, item) in sub.enumerated() {
                    selectableQuestions[indexPath.section].answers.insert(item, at: indexPath.row + 1 + i)
                    //addSelectedItem(id: item.id)
                }
            }
        }else {
            removeSelectedItem(id: answer.id)
            if answer.isSubAnswers == false && answer.subAnswers != nil && !answer.subAnswers!.isEmpty {
                answer.subAnswers!.forEach({ removeSelectedItem(id: $0.id) })
                var tempAnswer = [SelectableAnswer]()
                for currentAnswer in selectableQuestions[indexPath.section].answers {
                    if !answer.subAnswers!.contains(where: {$0.id == currentAnswer.id}) {
                        tempAnswer.append(currentAnswer)
                    }
                }
                
                selectableQuestions[indexPath.section].answers = tempAnswer
            }
        }
        delegate?.viewModel(dataLoaded: true)
    }
    

    private func addSelectedItem(id: Int) {
        if !selectedItems.contains(id) {
            selectedItems.append(id)
        }
    }
    
    public func removeSelectedItem(id: Int) {
        if selectedItems.contains(id) {
            selectedItems.remove(element: id)
        }
    }
    
    public func isSelectedQuesion(id: Int) -> Bool {
        return selectedItems.contains(id)
    }
    
    public func setPace(_ value: String) {
        selectedPace = TRPPace(rawValue: value) ?? TRPPace.normal
    }
    
    
    //Silinecek zaten id ile çalışıyro.
    public func setPaceWith(id: Int) {
        switch id {
        case slowPace.id:
            selectedPace = .slow
        case normalPace.id:
            selectedPace = .normal
        case fastPace.id:
            selectedPace = .fast
        default:
            ()
        }
    }
}




extension TripQuestionViewModel {
    
    func fetchTripQuestions() {
        delegate?.viewModel(showPreloader: true)
        tripQuestionUseCase?.executeTripQuestions(completion: { [weak self] result in
            guard let strongSelf = self else {return}
            strongSelf.delegate?.viewModel(showPreloader: false)
            switch(result) {
            case .success(let questions):
                let sortedQuestions = questions.sorted { $0.order < $1.order }
                let convertedModel = sortedQuestions.compactMap{ strongSelf.convertInfoModelToSelectableModel($0) }
                //Pace kapatıldı
                //strongSelf.selectableQuestions = strongSelf.addPaceQuesionIfExist(convertedModel )
                strongSelf.selectableQuestions = strongSelf.lunchAndDinnerController(convertedModel )
                strongSelf.checkSubAnswersForEditTrip()
                strongSelf.delegate?.viewModel(dataLoaded: true)
            case .failure(let error):
                strongSelf.delegate?.viewModel(error: error)
            }
        })
    }
    
    //Pace varsa soruların en sonuna ekler.
    private func addPaceQuesionIfExist(_ selectableQuestion: [SelectableQuestionModel]) -> [SelectableQuestionModel]{
        guard let paceQuestion = paceQuestion else {return selectableQuestion}
        var questions = selectableQuestion
        questions.append(paceQuestion)
        return questions
    }
    
    private func convertInfoModelToSelectableModel(_ model: TRPQuestion) -> SelectableQuestionModel? {
        let name = model.name
        let skippable = model.skippable
        let multiple = model.selectMultiple
        
        guard let options = model.answers else {return nil}
        let option = optionToAnswer(options)
        return SelectableQuestionModel(id: model.id,
                                       questionCategory: name,
                                       answers:  option,
                                       skipable: skippable,
                                       selectMultiple: multiple)
    }
    
    private func optionToAnswer(_ options: [TRPQuestionAnswer]) -> [SelectableAnswer] {
        var option = [SelectableAnswer]()
        for op in options {
            var sub: [SelectableAnswer]?
            
            if let subObtion = op.subAnswers {
                sub = subObtion.map({SelectableAnswer(id:$0.id, name:$0.name, subAnswers: nil, isSubAnswers: true, description: $0.description)})
            }
            option.append(SelectableAnswer(id:op.id, name:op.name, subAnswers: sub, description: op.description))
        }
        return option
    }
    
    /// Eğer Lunch ve Dinner varsa bunları silerek farklı bi yapıya dönüştürür.
    /// - Parameter selectableQuestion: Full sorular
    /// - Returns: editlenmiş sorular
    private func lunchAndDinnerController(_ selectableQuestion: [SelectableQuestionModel]) -> [SelectableQuestionModel]{
        
        guard selectableQuestion.contains(where: {$0.id == lunchQuestionId}), selectableQuestion.contains(where: {$0.id == dinnerQuestionId}) else {
            return selectableQuestion
        }
        
        var cleaned = [SelectableQuestionModel]()
        selectableQuestion.forEach { model in
            if model.id != lunchQuestionId && model.id != dinnerQuestionId {
                cleaned.append(model)
            }
        }
        
        //Add fake title
        let onlyTitle = SelectableQuestionModel(id: 99999, questionCategory: "What type of restaurants do you prefer?")
        cleaned.append(onlyTitle)
        
        //Add dinner
        if let dinner = selectableQuestion.first(where: {$0.id == dinnerQuestionId}) {
            let dinnerModel = SelectableQuestionModel(id: dinner.id,
                                                      questionCategory: " Dinner",
                                                      answers: dinner.answers,
                                                      skipable: dinner.skipable,
                                                      selectMultiple: dinner.selectMultiple,
                                                      headerType: .small)
            cleaned.append(dinnerModel)
        }
        
        //Add Lunch
        if let lunch = selectableQuestion.first(where: {$0.id == lunchQuestionId}) {
            let lucnhModel = SelectableQuestionModel(id: lunch.id,
                                                      questionCategory: " Lunch/Brunch",
                                                      answers: lunch.answers,
                                                      skipable: lunch.skipable,
                                                      selectMultiple: lunch.selectMultiple,
                                                      headerType: .small)
            cleaned.append(lucnhModel)
        }
        
        return cleaned
    }
    
    
    
    
    
}

extension TripQuestionViewModel {
    
    private func implementTripProfile(_ tripProfile: TRPTripProfile?) {
        guard let profile = tripProfile else {return}
        self.selectedItems = profile.allAnswers ?? []
    }
 
    private func checkSubAnswersForEditTrip() {
        guard !selectedItems.isEmpty else {return}
        var tempQuestion = [SelectableQuestionModel]()
        for section in selectableQuestions {
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
        selectableQuestions = tempQuestion
        delegate?.viewModel(dataLoaded: true)
    }
    
}

extension TripQuestionViewModel {
    
    private func clearPaceInAnsers(_ selectedAnsers: [Int]) -> [Int] {
        var tripAnswers = [Int]()
        for item in selectedAnsers {
            let isExistInPace = paceQuestion?.answers.contains(where: { (answer) -> Bool in
                return answer.id == item
            })
            if let isExist = isExistInPace, isExist{
                ()
            }else {
                tripAnswers.append(item)
            }
            
        }
        return tripAnswers
    }
    
    public func setTripProperties() {
        guard let tripProfile = tripProfile else {return}
        tripProfile.tripAnswers = clearPaceInAnsers(selectedItems)
        tripProfile.pace = selectedPace
    }
}
