//
//  ButterflyCollectionVM.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2.05.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit
import TRPDataLayer

public class ButterflyCollectionVM: TableViewViewModelProtocol {
    
    public typealias T = ButterflyCellStatus
    public weak var delegate: ViewModelDelegate?
    public var title: String = ""
    private var steps: [TRPStep] = [] {
        didSet {
            stepsToCellController(steps)
        }
    }
    
    public var cellViewModels: [ButterflyCellStatus] = [] {
        didSet {
            delegate?.viewModel(dataLoaded: true)
        }
    }
    
    public var numberOfCells: Int {
        return cellViewModels.count
    }
    public var plans: [TRPPlan]? = nil
    
    
    //USE CASES
    public var fetchReactionUseCase: FetchUserReactionUseCase?
    public var addReactionUseCase: AddUserReactionUseCase?
    public var updateReactionUseCase: UpdateUserReactionUseCase?
    public var deleteReactionUseCase: DeleteUserReactionUseCase?
    
    
    init(plans: [TRPPlan]? = nil) {
        self.plans = plans
    }
    
    public func getCellViewModel(at indexPath: IndexPath) -> ButterflyCellStatus {
        return cellViewModels[indexPath.row]
    }
    
    public func addSteps(_ items: [TRPStep]) {
        let unique = uniquesArray(currentItems: steps, newItems: items)
        steps.append(contentsOf: unique)
    }
    
    public func getImageUrl(model: ButterflyCellStatus) -> URL? {
        let link = model.step.poi.image.url
        guard let mlink = TRPImageResizer.generate(withUrl: link, standart: .myTrip) else { return nil }
        if let url = URL(string: mlink) {
            return url
        }
        return nil
    }
    
    func getDay(stepId: Int) -> Int? {
        guard let plans = plans else {return nil}
        var dayOrder = 0
        for day in plans {
            dayOrder += 1
            if day.steps.contains(where: {$0.id == stepId}) {
                return dayOrder
            }
        }
        return nil
    }
    
    func isFirstInSomeCategoryAndDay(step: TRPStep) -> Bool {
        guard let planId = step.planId else {return false}
        
        guard let refPositionInArray = steps.firstIndex(of: step) else {return false}
        var first = true
        for(index, item) in cellViewModels.enumerated() {
            if let itemPlanId = item.step.planId, itemPlanId == planId {
                
                if refPositionInArray > index {
                    first = false
                }
                
            }
        }
        return first
    }
    
    func isFirstInSomeCategoryAndDay(cellModel: ButterflyCellStatus) -> Bool {
        guard let cellIndex = cellViewModels.firstIndex(of: cellModel) else {return false}
        guard let planId = cellModel.step.planId else {return false}
        
        var first = true
        for(index, item) in cellViewModels.enumerated() {
            if let itemPlanId = item.step.planId, itemPlanId == planId {
                if cellIndex > index {
                    first = false
                }
            }
        }
        
        return first
    }
}

//MARK: - Button Controller
extension ButterflyCollectionVM {
    
    public func undoPressed(_ model: ButterflyCellStatus){
        if model.isProgress {return}
        model.isProgress = true
        model.isUninterest = false
        if let reactionId = model.reactionId {
            deleteReaction(id: reactionId)
        }
        //updateStepWithAlternative(stepId: model.step.id, newPoiId: model.step.poi.id)
    }
    
    public func thumbsDownPressed(_ model: ButterflyCellStatus) {
        if model.isProgress {return}
        model.isUninterest = true
        model.isProgress = true
        userReaction(stepId: model.step.id, poiId: model.step.poi.id, reaction: .thumbsDown)
        /*if let firstAlternative = model.step.alternatives.first {
            updateStepWithAlternative(stepId: model.step.id, newPoiId: firstAlternative)
        }*/
    }
    
    public func thumbsUpPressed(_ model: ButterflyCellStatus) {
        if model.isProgress {return}
        model.isProgress = true
        model.isLiked = true
        userReaction(stepId: model.step.id, poiId: model.step.poi.id, reaction: .thumbsUp)
    }
    
    public func thumbsUpUnCheckPressed(_ model: ButterflyCellStatus) {
        if model.isProgress {return}
        model.isProgress = true
        model.isLiked = false
        if let reactionID = model.reactionId {
            deleteReaction(id: reactionID)
        }
    }
    
    public func tellUsWhyAlert(_ model: ButterflyCellStatus, userAnswer: TellUsWhy) {
        guard let reactionId = model.reactionId else {return}
        var type: TRPUserReactionComment = .iHaveAlreadyVisited
        if userAnswer == .iDontLikePlace {
            type = .iDontLikePlace
        }
        removeCellPressed(model)
        updateReaction(id: reactionId, reaction: .thumbsDown, comment: type)
    }
    
    
    public func removeCellPressed(_ model: ButterflyCellStatus) {
        guard let index = cellViewModels.firstIndex(of: model) else {return}
        cellViewModels.remove(at: index)
        
    }
}


//MARK: - Step Controller
extension ButterflyCollectionVM {
    
    func stepsToCellController(_ steps: [TRPStep]) {
        let converted = stepToCellStatus(steps)
        let uniqueCell = uniquesArray(currentItems: cellViewModels, newItems: converted)
        cellViewModels.append(contentsOf: uniqueCell)
    }
    
    private func stepToCellStatus(_ steps: [TRPStep]) -> [ButterflyCellStatus] {
        var tempData = [ButterflyCellStatus]()
        for step in steps {
            tempData.append(ButterflyCellStatus(step: step))
        }
        return tempData
    }
    
}

//MARK: - Network
extension ButterflyCollectionVM {
    
    public func userReaction(stepId: Int, poiId: String, reaction: TRPUserReactionType){
        
        addReactionUseCase?.executeAddUserReaction(poiId: poiId,
                                                   stepId: stepId,
                                                   reaction: reaction,
                                                   comment: nil,
                                                   completion: { [weak self] result in
            switch result {
            case .success(let result):
                self?.updateModel(stepId: stepId, reactionId: result.id, reaction: reaction)
            case .failure(let error):
                self?.delegate?.viewModel(error: error)
            }
            
        })
        
    }
    
    public func updateReaction(id: Int, reaction: TRPUserReactionType? , comment: TRPUserReactionComment) {
        
        updateReactionUseCase?.executeUpdateUserReaction(id: id, reaction: reaction, comment: comment.rawValue, completion: { result in
            switch result {
            case .success(let reaction):
                print("REACTION \(reaction)")
            case .failure(let error):
                print("Error \(error.localizedDescription)")
            }
        })
        
    }
    
    public func deleteReaction(id: Int) {
        
        deleteReactionUseCase?.executeDeleteUserReaction(id: id, completion: {[weak self] result in
            switch result {
            case .success(_):
                guard let cellModel = self?.cellViewModels.first(where: {$0.reactionId == id}) else {return}
                cellModel.isProgress = false
            case .failure(let error):
                self?.delegate?.viewModel(error: error)
            }
        })
       
    }
    
}

//MARK: - HELPER
extension ButterflyCollectionVM {
    
    private func updateModel(stepId: Int, reactionId: Int, reaction: TRPUserReactionType) {
        guard let cellModel = cellViewModels.first(where: {$0.step.id == stepId}) else {return}
        cellModel.isProgress = false
        cellModel.reactionId = reactionId
    }
    
    private func uniquesArray<T: Equatable>(currentItems: [T], newItems: [T]) -> [T] {
        var tempItems = [T]()
        for new in newItems {
            if !currentItems.contains(new) {
                tempItems.append(new)
            }
        }
        return tempItems
    }
    
}

public enum TellUsWhy: String {
    case iHaveAlreadyVisited = "I have already visited"
    case iDontLikePlace = "I don't like place"
}






