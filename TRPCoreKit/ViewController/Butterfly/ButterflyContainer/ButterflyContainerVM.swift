//
//  ButterflyContainerVM.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 1.05.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation




public enum ButterflyCellType {
    case explain, top10, butterfly
}

public struct ButterflyCellModel {
    let type: ButterflyCellType
    let data: AnyObject
    
    init(type: ButterflyCellType, data: AnyObject) {
        self.type = type
        self.data = data
    }
}

public protocol ButterflyContainerVMDelegate: ViewModelDelegate {
    func butterflyContainerVMStepsEmpty()
}

public class ButterflyContainerVM: TableViewViewModelProtocol {
    
    public typealias T = ButterflyCellModel
    
    private(set) var tripHash: String
    public var cellViewModels: [ButterflyCellModel] = []
    private var attractionCollection: ButterflyCollectionModel?
    private var restaurantCollection: ButterflyCollectionModel?
    private var cafesCollection: ButterflyCollectionModel?
    private var nightLifeCollection: ButterflyCollectionModel?
    public weak var delegate: ButterflyContainerVMDelegate?
    
    
    private(set) var dailyPlans: [TRPPlan]? {
        didSet {
            if let data = dailyPlans  {
                let restaurant = getCellDatas(dailyPlans: data, types: [TRPPoiCategory.restaurants.getId()])
                let cafes = getCellDatas(dailyPlans: data, types: [TRPPoiCategory.cafes.getId(),TRPPoiCategory.bakery.getId()])
                
                let attractionTypes = AddPlaceMenu.attractions.addPlaceType().subTypes
                let attractions = getCellDatas(dailyPlans: data, types: attractionTypes)
                let nightLife = getCellDatas(dailyPlans: data, types: [TRPPoiCategory.nightLife.getId(), TRPPoiCategory.bar.getId()])
                ourPickDataController(collectionModel: attractionCollection, steps: attractions, order: 1)
                ourPickDataController(collectionModel: restaurantCollection, steps: restaurant, order: 2)
                ourPickDataController(collectionModel: cafesCollection, steps: cafes, order: 3)
                ourPickDataController(collectionModel: nightLifeCollection, steps: nightLife, order: 4)
            }
        }
    }
    
    
    //USE CASES
    public var tripObserverUseCase: ObserveTripCheckAllPlanUseCase?
    
    private var reactionUseCases: TRPUserReactionUseCases = {
        return TRPUserReactionUseCases()
    }()
    
    public init(tripHash: String) {
        self.tripHash = tripHash
    }
    
    func start() {
        let attractionModel = ButterflyCollectionModel(title: "Attraction", cellClass: ButterflyAttractionCell.self, viewModel: ButterflyCollectionVM())
        let restaurantModel = ButterflyCollectionModel(title: "Restaurants", cellClass: ButterflyRestaurantCell.self, viewModel: ButterflyCollectionVM())
        let cafesModel = ButterflyCollectionModel(title: "Cafes", cellClass: ButterflyRestaurantCell.self, viewModel: ButterflyCollectionVM())
        let nightlifeModel = ButterflyCollectionModel(title: "Nightlife", cellClass: ButterflyRestaurantCell.self, viewModel: ButterflyCollectionVM())
        
        attractionCollection = attractionModel
        restaurantCollection = restaurantModel
        cafesCollection = cafesModel
        nightLifeCollection = nightlifeModel
        
        applyUseCases(viewModel: attractionCollection!.viewModel)
        applyUseCases(viewModel: restaurantCollection!.viewModel)
        applyUseCases(viewModel: cafesCollection!.viewModel)
        applyUseCases(viewModel: nightLifeCollection!.viewModel)
        
        
        DispatchQueue.main.async {
            self.delegate?.viewModel(dataLoaded: true)
        }
        let explainText = "Based on the preferences you've indicated, we recommend you the following spots."
        cellViewModels.append(ButterflyCellModel(type: .explain, data: explainText as AnyObject))
        addObservers()
    }
    
    public var numberOfCells: Int {
        return cellViewModels.count
    }
    
    public func getCellViewModel(at indexPath: IndexPath) -> ButterflyCellModel {
        return cellViewModels[indexPath.row]
    }
    
    public func removeCell(at indexPath: IndexPath) {
        cellViewModels.remove(at: indexPath.row)
        self.delegate?.viewModel(dataLoaded: true)
    }
    
    private func getCellDatas(dailyPlans: [TRPPlan], types: [Int]) -> [TRPStep]{
        var temp = [TRPStep]()
        for plan in dailyPlans {
            for step in plan.steps {
                for type in types {
                    if step.poi.categories.first(where: {$0.id == type}) != nil {
                        temp.append(step)
                    }
                }
            }
        }
        var sortSteps = temp
        
        sortSteps.sort { (leftStep, rightStep) -> Bool in
            guard let leftScore = leftStep.score, let rightScore = rightStep.score else {return false}
            guard let leftPlanId = leftStep.planId, let rightPlanId = rightStep.planId else {return false}
            return leftPlanId == rightPlanId && leftScore > rightScore
        }
        return sortSteps
    }
    
    private func applyUseCases(viewModel: ButterflyCollectionVM) {
        viewModel.deleteReactionUseCase = reactionUseCases
        viewModel.addReactionUseCase = reactionUseCases
        viewModel.fetchReactionUseCase = reactionUseCases
        viewModel.updateReactionUseCase = reactionUseCases
    }
    
    deinit {
        removeObservers()
    }
}

extension ButterflyContainerVM: ObserverProtocol {
    
    func addObservers() {
        tripObserverUseCase?.trip.addObserver(self, observer: { [weak self] trip in
            self?.dailyPlans = trip.plans
        })
    }
    
    func removeObservers() {
        tripObserverUseCase?.trip.removeObserver(self)
    }
    
}

//MARK: - Logic
extension ButterflyContainerVM {
    
    
    private func ourPickDataController(collectionModel: ButterflyCollectionModel?, steps:[TRPStep], order: Int) {
        guard let collectionModel = collectionModel, steps.count != 0 else {return}
        
        let newCellModel = ButterflyCellModel(type: .butterfly, data: collectionModel as AnyObject)
        
        let isCollectionExist = cellViewModels.contains { (cellModel) -> Bool in
            if let ourPickModel = cellModel.data as? ButterflyCollectionModel {
                return ourPickModel == collectionModel
            }
            return false
        }
        
        if !isCollectionExist {
            cellViewModels.append(newCellModel)
            /*if order > cellViewModels.count {
             cellViewModels.append(newCellModel)
             }else {
             cellViewModels.insert(newCellModel, at: order)
             }*/
            DispatchQueue.main.async {
                self.delegate?.viewModel(dataLoaded: true)
            }
        }
        if let plans = dailyPlans {
            collectionModel.viewModel.plans = plans
            
            collectionModel.viewModel.addSteps(steps)
        }
        
    }
    
    private func fetchingTripDatasCompleted() {
        DispatchQueue.main.async {
            if self.isTripStepEmpty() {
                self.delegate?.butterflyContainerVMStepsEmpty()
            }
        }
    }
    
    private func isTripStepEmpty() -> Bool {
        guard let dailyPlan = dailyPlans else {return true}
        var empty = true
        for plan in dailyPlan {
            if !plan.steps.isEmpty {
                empty = false
            }
        }
        return empty
    }
    
    
}

extension ButterflyContainerVM {
    
    private func isTripNotEmpty() -> Bool {
        guard let plans = dailyPlans else {return false}
        for plan in plans {
            if !plan.steps.isEmpty {
                return true
            }
        }
        return false
    }
}



public struct ButterflyCollectionModel {
    public let title: String
    public let cellClass: AnyClass
    public let viewModel: ButterflyCollectionVM
}

extension ButterflyCollectionModel: Equatable {
    
    public static func == (lhs: ButterflyCollectionModel, rhs: ButterflyCollectionModel) -> Bool {
        return lhs.title == rhs.title
    }
    
}
