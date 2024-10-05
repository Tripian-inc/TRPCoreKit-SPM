//
//  CreateTripPickedInformationViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 12.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation



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
            insertBeenBeforeAnswer(answer: getCellModel(at: indexPath))
            delegate?.viewModel(dataLoaded: true)
        } else if cellType == .restaurant {
            delegate?.restaurantPreferSelected(questionModel: getCellModelForRestaurantPrefer(at: indexPath))
        } else if cellType == .radio {
            selectedAnswer(indexPath: indexPath)
            delegate?.viewModel(dataLoaded: true)
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
        insertSelectedItem(answer)
    }
    
    func insertBeenBeforeAnswer(answer: SelectableAnswer) {
        let alreadySelected = isSelectedAnswer(id: answer.id)
        cleanBeenBeforeAnswers()
        if !alreadySelected {
            insertSelectedItem(answer)
        }
    }
    
    private func cleanBeenBeforeAnswers() {
        beenBeforeQuestionAnswerIds.forEach({
            self.removeSelectedItem(id: $0)
        })
    }
    
    private func selectedAnswer(indexPath: IndexPath) {
        let model = getCellModel(at: indexPath)
        let questionModel = getSectionModel(section: indexPath.section)
        let alreadySelected = isSelectedAnswer(id: model.id)
        if !questionModel.selectMultiple {
            removeAllSelectedItemsForSection(section: questionModel)
        }
        removeSelectedItem(id: model.id)
        if !alreadySelected {
            insertSelectedItem(model)
        }
    }
    
    private func cleanRestaurantPreferAnswers(question: SelectableQuestionModelNew) {
        question.answers.forEach({
            self.removeSelectedRestaurantAnswer(question: question, answer: $0)
        })
    }
    
    private func removeSelectedRestaurantAnswer(question: SelectableQuestionModelNew, answer: SelectableAnswer) {
        selectedRestaurantAnswers.removeValue(forKey: question.id)
        removeSelectedItem(id: answer.id)
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
        if let travelTypeQuestion = questions.first(where: {$0.id == 19}),
           let model = convertQuestionModelToSelectableModel(travelTypeQuestion, cellType: .radio)
        {
            self.sectionModels.append(model)
        }
        guard questions.contains(where: {$0.id == lunchQuestionId}), questions.contains(where: {$0.id == dinnerQuestionId}) else {
            return
        }
        var restaurantPreferModel = SelectableQuestionModelNew(id: restaurantPreferId, headerTitle: TRPLanguagesController.shared.getLanguageValue(for: "trips.createNewTrip.restaurantQuestion.title"), cellType: .restaurant)
        
        
        if let lunchQuestion = questions.first(where: {$0.id == lunchQuestionId}),
            let lunchModel = convertQuestionModelToSelectableModel(lunchQuestion, cellType: .restaurant, headerTitle: TRPLanguagesController.shared.getLanguageValue(for: "trips.createNewTrip.restaurantQuestion.lunchBrunch")) {
            restaurantPreferModel.subModels.append(lunchModel)
        }
        if let dinnerQuestion = questions.first(where: {$0.id == dinnerQuestionId}),
           let dinnerModel = convertQuestionModelToSelectableModel(dinnerQuestion, cellType: .restaurant, headerTitle: TRPLanguagesController.shared.getLanguageValue(for: "trips.createNewTrip.restaurantQuestion.dinner")) {
            restaurantPreferModel.subModels.append(dinnerModel)
        }
        self.sectionModels.append(restaurantPreferModel)
    }
    
}

extension CreateTripPickedInformationViewModel {
 
    override func checkSubAnswersForEditTrip() {
        super.checkSubAnswersForEditTrip()
        if let restaurantSection = sectionModels.first(where: { $0.id == restaurantPreferId }) {
            restaurantSection.subModels.forEach { model in
                model.answers.forEach({
                    if self.isSelectedAnswer(id: $0.id) {
                        self.insertSelectedRestaurantAnswer(question: model, answer: $0)
                    }
                })
            }
        }
        delegate?.viewModel(dataLoaded: true)
    }
    
}
