//
//  CreateTripPickedInformationViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 12.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit
import TRPDataLayer

protocol CreateTripPickedInformationViewModelDelegate: ViewModelDelegate {
    func restaurantPreferSelected(questionModel: SelectableQuestionModelNew)
}
class CreateTripPickedInformationViewModel: CreateTripQuestionsViewModel {
    
//    private(set) var selectableQuestions = [SelectableQuestionModel]()
    public weak var delegate: CreateTripPickedInformationViewModelDelegate?
    
    public override var selectedItems: [Int] {
        didSet {
            delegate?.viewModel(dataLoaded: true)
        }
    }
    
    private var selectedRestaurantAnswers: [Int: SelectableAnswer] = [:]
    private var beenBeforeQuestionAnswerIds: [Int] = []
    
    public func start() {
        fetchTripQuestions()
    }
    
    func getCellCountForRestaurantPrefer(section: Int) -> Int {
        return sectionModels[section].subModels.count
    }
    
    func getCellType(section: Int) -> SelectableQuestionCellType {
        return sectionModels[section].cellType
    }
    
    func getCellModelForRestaurantPrefer(at indexPath: IndexPath) -> SelectableQuestionModelNew {
        return sectionModels[indexPath.section].subModels[indexPath.row]
    }
    
    func cellSelected(indexPath: IndexPath) {
        let cellType = getCellType(section: indexPath.section)
        if cellType == .withDescription {
            let model = getCellModel(at: indexPath)
            if self.selectedItems.contains(model.id) {
                cleanBeenBeforeAnswers()
            } else {
                insertBeenBeforeAnswer(answer: model)
            }
            delegate?.viewModel(dataLoaded: true)
        } else {
            let model = getCellModelForRestaurantPrefer(at: indexPath)
            delegate?.restaurantPreferSelected(questionModel: model)
        }
    }
    
    func getSelectedRestaurantAnswer(questionId: Int) -> String {
        guard let selectedAnswer = selectedRestaurantAnswers[questionId] else {
            return ""
        }
        return selectedAnswer.name
    }
    
    func insertSelectedRestaurantAnswer(question: SelectableQuestionModelNew, answer: SelectableAnswer) {
        cleanRestaurantPreferAnswers(question: question)
        selectedRestaurantAnswers[question.id] = answer
        selectedItems.append(answer.id)
    }
    
    func insertBeenBeforeAnswer(answer: SelectableAnswer) {
        cleanBeenBeforeAnswers()
        selectedItems.append(answer.id)
    }
    
    private func cleanBeenBeforeAnswers() {
        beenBeforeQuestionAnswerIds.forEach({
            self.selectedItems.remove(element: $0)
        })
    }
    
    private func cleanRestaurantPreferAnswers(question: SelectableQuestionModelNew) {
        question.answers.forEach({
            self.removeSelectedRestaurantAnswer(question: question, answer: $0)
        })
    }
    
    private func removeSelectedRestaurantAnswer(question: SelectableQuestionModelNew, answer: SelectableAnswer) {
        selectedRestaurantAnswers.removeValue(forKey: question.id)
        selectedItems.remove(element: answer.id)
    }
}
extension CreateTripPickedInformationViewModel {
    
    func fetchTripQuestions() {
        delegate?.viewModel(showPreloader: true)
        tripQuestionUseCase?.executeTripQuestions(completion: { [weak self] result in
            guard let strongSelf = self else {return}
            strongSelf.delegate?.viewModel(showPreloader: false)
            switch(result) {
            case .success(let questions):
                let sortedQuestions = questions.sorted { $0.order < $1.order }
                strongSelf.convertInfoModelToSelectableModels(sortedQuestions)
                strongSelf.checkSubAnswersForEditTrip()
                strongSelf.delegate?.viewModel(dataLoaded: true)
            case .failure(let error):
                strongSelf.delegate?.viewModel(error: error)
            }
        })
    }
    
    private func convertInfoModelToSelectableModels(_ questions: [TRPQuestion]) {
        if let beenBeforeQuestion = questions.first(where: {$0.id == beenBeforeQuestionId}),
           let model = convertQuestionModelToSelectableModel(beenBeforeQuestion, cellType: .withDescription)
        {
            beenBeforeQuestionAnswerIds = beenBeforeQuestion.answers?.compactMap({$0.id}) ?? []
            self.sectionModels.append(model)
        }
        guard questions.contains(where: {$0.id == lunchQuestionId}), questions.contains(where: {$0.id == dinnerQuestionId}) else {
            return
        }
        var restaurantPreferModel = SelectableQuestionModelNew(id: restaurantPreferId, headerTitle: "What type of restaurants do you prefer?", cellType: .restaurant)
        
        
        if let lunchQuestion = questions.first(where: {$0.id == lunchQuestionId}),
            let lunchModel = convertQuestionModelToSelectableModel(lunchQuestion, cellType: .restaurant, headerTitle: "Lunch/Brunch") {
            restaurantPreferModel.subModels.append(lunchModel)
        }
        if let dinnerQuestion = questions.first(where: {$0.id == dinnerQuestionId}),
           let dinnerModel = convertQuestionModelToSelectableModel(dinnerQuestion, cellType: .restaurant, headerTitle: "Dinner") {
            restaurantPreferModel.subModels.append(dinnerModel)
        }
        self.sectionModels.append(restaurantPreferModel)
    }
    
}

extension CreateTripPickedInformationViewModel {
 
    override func checkSubAnswersForEditTrip() {
        super.checkSubAnswersForEditTrip()
//        guard !selectedItems.isEmpty else {return}
//        var tempQuestion = [SelectableQuestionModelNew]()
//        for section in sectionModels {
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
//        sectionModels = tempQuestion
        if let restaurantSection = sectionModels.first(where: { $0.id == restaurantPreferId }) {
            restaurantSection.subModels.forEach { model in
                model.answers.forEach({
                    if self.isSelectedQuesion(id: $0.id) {
                        self.insertSelectedRestaurantAnswer(question: model, answer: $0)
                    }
                })
            }
        }
        delegate?.viewModel(dataLoaded: true)
    }
    
}
