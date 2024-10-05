//
//  CreateTripPersonalizeTripViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 14.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation
import TRPDataLayer

class CreateTripPersonalizeTripViewModel: CreateTripQuestionsViewModel {
    
    public weak var delegate: ViewModelDelegate?
    
    public func start() {
        fetchTripQuestions()
    }
    
    func shouldAllowSelectionAt(_ section: Int) -> Bool {
        return getSectionModel(section: section).selectMultiple
    }
    
    func getSingleSelectedItemIndexIn(section: Int) -> Int? {
        for (index, quesion) in sectionModels[section].answers.enumerated() {
            if selectedItems.contains(quesion.id) {
                return index
            }
        }
        
        return nil
    }
    
    
    public func selectedAnswers(at indexPath: IndexPath) {
        let answer = sectionModels[indexPath.section].answers[indexPath.row]
        
        if !selectedItems.contains(answer.id) {
            addSelectedItem(id: answer.id)
            delegate?.viewModel(dataLoaded: true)
            if let sub = answer.subAnswers, let firstAnswer = sub.first {
                //eğer eklenmişse bir daha ekelemz
                if sectionModels[indexPath.section].answers.contains(where: {$0.id == firstAnswer.id}) {return}
                
                for (i, item) in sub.enumerated() {
                    sectionModels[indexPath.section].answers.insert(item, at: indexPath.row + 1 + i)
                    //addSelectedItem(id: item.id)
                }
            }
        }else {
            removeSelectedItem(id: answer.id)
            if answer.isSubAnswers == false && answer.subAnswers != nil && !answer.subAnswers!.isEmpty {
                answer.subAnswers!.forEach({ removeSelectedItem(id: $0.id) })
                var tempAnswer = [SelectableAnswer]()
                for currentAnswer in sectionModels[indexPath.section].answers {
                    if !answer.subAnswers!.contains(where: {$0.id == currentAnswer.id}) {
                        tempAnswer.append(currentAnswer)
                    }
                }
                
                sectionModels[indexPath.section].answers = tempAnswer
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
}

extension CreateTripPersonalizeTripViewModel {
    
    func fetchTripQuestions() {
        delegate?.viewModel(showPreloader: true)
        tripQuestionUseCase?.executeTripQuestions(completion: { [weak self] result in
            guard let strongSelf = self else {return}
            strongSelf.delegate?.viewModel(showPreloader: false)
            switch(result) {
            case .success(let questions):
                let sortedQuestions = questions.sorted { $0.order < $1.order }
                let convertedModel = sortedQuestions.compactMap{ strongSelf.convertQuestionModelToSelectableModel($0) }
                strongSelf.sectionModels = strongSelf.setOnlyExploreQuestions(convertedModel )
                strongSelf.checkSubAnswersForEditTrip()
                strongSelf.delegate?.viewModel(dataLoaded: true)
            case .failure(let error):
                strongSelf.delegate?.viewModel(error: error)
            }
        })
    }
    
//    private func convertInfoModelToSelectableModel(_ model: TRPQuestion) -> SelectableQuestionModelNew? {
//        let name = model.name
//        let skippable = model.skippable
//        let multiple = model.selectMultiple
//
//        guard let answers = model.answers else {return nil}
//        let answer = answerToSelectable(answers)
//        return SelectableQuestionModelNew(id: model.id,
//                                       headerTitle: name,
//                                       answers: answer,
//                                       skipable: skippable,
//                                       selectMultiple: multiple)
//    }
    
    private func setOnlyExploreQuestions(_ selectableQuestion: [SelectableQuestionModelNew]) -> [SelectableQuestionModelNew] {
        
        guard selectableQuestion.contains(where: {$0.id == exploreQuestionId}) else {
            return selectableQuestion
        }
        
        var cleaned = [SelectableQuestionModelNew]()
        selectableQuestion.forEach { model in
            if model.id == exploreQuestionId  {
                cleaned.append(model)
            }
        }
        return cleaned
    }
    
}

extension CreateTripPersonalizeTripViewModel {
//
//    private func implementTripProfile(_ tripProfile: TRPTripProfile?) {
//        guard let profile = tripProfile else {return}
//        self.selectedItems = profile.allAnswers ?? []
//    }
//
    override func checkSubAnswersForEditTrip() {
        super.checkSubAnswersForEditTrip()
        delegate?.viewModel(dataLoaded: true)
//        guard !selectedItems.isEmpty else {return}
//        var tempQuestion = [SelectableQuestionModelNew]()
//        for section in selectableQuestions {
//            var tempSection = section
//            tempSection.answers = []
//            for answer in section.answers {
//                tempSection.answers.append(answer)
//                if selectedItems.contains(where: {$0 == answer.id}), answer.isSubAnswers == false, let subAnswers = answer.subAnswers {
//                    tempSection.answers.append(contentsOf: subAnswers)
//                }
//            }
//            tempQuestion.append(tempSection)
//        }
//        selectableQuestions = tempQuestion
//        delegate?.viewModel(dataLoaded: true)
    }
//
}

//extension CreateTripPersonalizeTripViewModel {
//
//    public func setTripProperties() {
//        guard let tripProfile = tripProfile else {return}
//        if tripProfile.tripAnswers == nil {
//            tripProfile.tripAnswers = []
//        }
//        tripProfile.tripAnswers?.append(contentsOf: selectedItems)
//    }
//}
