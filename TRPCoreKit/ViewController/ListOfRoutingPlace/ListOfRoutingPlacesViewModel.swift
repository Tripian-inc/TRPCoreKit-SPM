//
//  ListOfRoutingPlacesViewModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 1.12.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation
import CoreLocation
import MapboxDirections
import TRPRestKit
import TRPFoundationKit

protocol ListOfRoutingPoisViewModelDelete: ViewModelDelegate {
    func showEmptyMessage(_ message: String)
    func clearEmptyMessage()
}

public class ListOfRoutingPoisViewModel {
    
    private var steps: [TRPStep] = [] {
        didSet {
            delegate?.viewModel(dataLoaded: true)
        }
    }
    
    private var stepInfoData = [StepInfoForListOfRouting]() {
        didSet {
            delegate?.viewModel(dataLoaded: true)
        }
    }
    
    private var driveInfoData = [DriveInfoForListOfRouting]() {
        didSet {
            delegate?.viewModel(dataLoaded: true)
        }
    }
    private var reactions = [TRPUserReaction]() {
        didSet {
            delegate?.viewModel(dataLoaded: true)
        }
    }
    
    weak var delegate: ListOfRoutingPoisViewModelDelete?
    
    public var fetchReactionUseCase: FetchUserReactionUseCase?
    public var addReactionUseCase: AddUserReactionUseCase?
    public var updateReactionUseCase: UpdateUserReactionUseCase?
    public var deleteReactionUseCase: DeleteUserReactionUseCase?
    public var removeStepUseCase: DeleteStepUseCase?
    public var observeUserReaction: ObserveUserReactionUseCase?
    public var tripModelObserverUseCase: ObserveTripModeUseCase?
//    public var reOrderStepUseCase: ReOrderStepUseCase?
    public var editPlanUseCase: EditPlanUseCase?
    public var editStepUseCase: EditStepUseCase?
    public var fetchStepAlternative: FetchStepAlternative?
     var mapRouteUseCases: MapRouteUseCases?
    
    public init(){}
     
    public func start() {
        addObservers()
        if let hash = tripModelObserverUseCase?.trip.value?.tripHash {
            fetchReactions(tripHash:hash)
        }
    }
    
    public func fetchReactions(tripHash: String) {
        fetchReactionUseCase?.executeFetchUserReaction(tripHash: tripHash, completion: { result in
            switch result {
            case .failure(let error):
                print("Error \(error.localizedDescription)")
            default: ()
            }
        })
    }
    
    
    
    public var isHotelExist: Bool {
        for step in steps {
            if step.poi.placeType  == .hotel {
                return true
            }
        }
        return false
    }
    
    var dataCount: Int {
        return steps.count
    }
    
    func getStep(index: IndexPath) -> TRPStep {
        return steps[index.row]
    }
    
    func showThumbsReactions(index: IndexPath) -> Bool {
        guard  let score = getStep(index: index).score else {
            return false
        }
        return !score.isZero
    }
    
    func getCellHeight(index: IndexPath) -> CGFloat {
        let info = getStep(index: index)
        var height: CGFloat = 144
        
        //Hotel
        if info.poi.placeType == .hotel {
            height = 120
        }
        
        //Status
        if info.poi.status == false {
            height = 120
        }
        
        if getStepDistanceContent(index: index).userCar && TRPAppearanceSettings.Providers.uber{
            height += 10
        }
        return height
    }
    
    func getStepDistanceContent(index: IndexPath) -> (readableDistance: String?, readableTime: String?, userCar: Bool) {
        
        if steps.count == stepInfoData.count + 1 && stepInfoData.count > index.row {
            let distance = Float(stepInfoData[index.row].distance / 1000)
            let readableDistance = Float(round(10 * distance)/10)
            var readableTime = Int(stepInfoData[index.row].time / 60)
            var useCar = false
            if readableDistance > 1.9 {
                useCar = true
            } else {
                readableTime = Int(readableDistance * 12)
            }
            return ("\(readableDistance)", "\(readableTime)",useCar)
        }
        return (nil,nil,false)
    }
    
    /// Listede gösterilecek Tüm poileri(Steplerin) ayarlandığı methodur.
    /// - Parameter steps: Türm Step(Poiler)
    func setData(steps: [TRPStep]) {
        self.steps = steps
    }
    
    func setStepInfoData(_ data: [StepInfoForListOfRouting]) {
        stepInfoData = data
    }
    
    func isExistAlternative(step: TRPStep) -> Bool {
        return !step.alternatives.isEmpty
    }
    
    // Manuel sort esnasında Distance bilgileri geç güncellendiği için bu metoda eski stepleri temizler. 
    func cleanStepInfoData() {
        stepInfoData = []
    }
 
    
    func createUberInfo(indexPath:IndexPath) -> UberModel? {
//        if(indexPath.row + 1 <= steps.count){
//            let pick = steps[indexPath.row].poi
//            let drop = steps[indexPath.row + 1].poi
//            
//            return UberModel(pickupLocation: pick.coordinate,
//                      pickupName: pick.name,
//                      pickupAddress: pick.address ?? "",
//                      dropoffLocation: drop.coordinate,
//                      dropOffName: drop.name,
//                      dropOffAddress: drop.address ?? "")
//        }
        return nil
    }
    
    public func getPlaceImage(indexPath:IndexPath) -> URL? {
        let url = getStep(index: indexPath).poi.image?.url
        guard let link = TRPImageResizer.generate(withUrl: url, standart: .small2) else {
            return nil
        }
        if let url = URL(string: link) {
            return url
        }
        return nil
    }
    
    public func removePoiInRoute(stepId:Int) {
        
            delegate?.viewModel(showPreloader: true)
            removeStepUseCase?.executeDeleteStep(id: stepId, completion: { [weak self] result in
                self?.delegate?.viewModel(showPreloader: false)
            
                if case .failure(let error) = result {
                    self?.delegate?.viewModel(error: error)
                }
            })
        
    }
 
    public func createUberDeepLink(_ model: UberModel, canOpenLink: Bool) -> URL? {
        guard let clientId = TRPApiKeyController.getKey(TRPApiKeys.trpUberClient) else {
            Log.d("Uber client id is empty")
            return nil
        }
        var startLink: String = ""
        if canOpenLink {
            startLink = "uber://?"
        } else {
            startLink = "https://m.uber.com/?"
        }
        let url =  "\(startLink)client_id=\(clientId)&action=setPickup&pickup[latitude]=\(model.pickupLocation.lat)&pickup[longitude]=\(model.pickupLocation.lon)&pickup[nickname]=\(model.pickupName.encodeUrl() ?? "Pickup")&dropoff[latitude]=\(model.dropoffLocation.lat)&dropoff[longitude]=\(model.dropoffLocation.lon)&dropoff[nickname]=\(model.dropOffName.encodeUrl() ?? "DropOff")&product_id=a1111c8c-c720-46c3-8534-2fcdd730040d"
        
        return URL(string: url)
    }
    
    func getCustomPoiUrl(poi: TRPPoi) -> URL? {
        if let startDate = tripModelObserverUseCase?.dailyPlan.value?.date {
            return poi.getCustomPoiUrl(planDate: startDate)
        }
        return nil
    }
    
    deinit {
        removeObservers()
        Log.deInitialize()
    }
}

//MARK: - REACTİONS
extension ListOfRoutingPoisViewModel {
    
    public func getReactions(step: TRPStep) -> TRPUserReactionType? {
        if let reaction =  reactions.first(where: {$0.stepId == step.id}) {
            return reaction.reaction
        }
        return nil
    }
    
    public func sendThumbUpReaction(step: TRPStep) {
        delegate?.viewModel(showPreloader: true)
        addReactionUseCase?.executeAddUserReaction(poiId: step.poi.id, stepId: step.id, reaction: .thumbsUp, comment: nil, completion: { [weak self] result in
            self?.delegate?.viewModel(showPreloader: false)
            switch result {
            case .success(let status):
                print("ThumbUp \(status)")
            case .failure(let error):
                self?.delegate?.viewModel(error: error)
            }
        })
    }
    
    public func sendThumbDownReaction(step: TRPStep) {
        delegate?.viewModel(showPreloader: true)
        addReactionUseCase?.executeAddUserReaction(poiId: step.poi.id, stepId: step.id, reaction: .thumbsDown, comment: nil, completion: { [weak self] result in
            self?.delegate?.viewModel(showPreloader: false)
            switch result {
            case .success(let status):
                print("ThumbDown \(status)")
            case .failure(let error):
                self?.delegate?.viewModel(error: error)
            }
        })
    }
    
    func getStepAlternatives(_ step: TRPStep, completion: @escaping (_ pois:[TRPPoi]) -> Void) {
        fetchStepAlternative?.executeFetchStepAlternative(stepId: step.id, completion: { result in
            switch result {
            case .success(let pois):
                completion(pois)
            case .failure(let error):
                print("[Error] \(error.localizedDescription)")
            }
        })
    }
    
    public func sendUndo(step: TRPStep) {
        delegate?.viewModel(showPreloader: true)
        if let reaction = reactions.first(where: {$0.stepId == step.id}) {
            deleteReactionUseCase?.executeDeleteUserReaction(id: reaction.id, completion: { [weak self] result in
                self?.delegate?.viewModel(showPreloader: false)
                print("Undo Result \(result)")
            })
        }
    }
    
    public func stepReOrder(step: TRPStep, newOrder: Int) {
        guard let editPlanUseCase else {return}
        delegate?.viewModel(showPreloader: true)
        steps.remove(element: step)
        steps.insert(step, at: newOrder)
        var stepIds = steps.map({$0.id})
        if isHotelExist {
            stepIds.remove(at: 0)
        }
        editPlanUseCase.executeEditPlanStepOrder(stepOrders: stepIds, completion: {  [weak self] result in
            self?.delegate?.viewModel(showPreloader: false)
            if case .failure(let error) = result {
                self?.delegate?.viewModel(error: error)
            }
        })
    }
}

//MARK: - Change Step Time
extension ListOfRoutingPoisViewModel {
    func changeStepTime(step: TRPStep?) {
        guard let editStepUseCase,
              let step,
              let from = step.times?.from,
              let to = step.times?.to else {return}
        delegate?.viewModel(showPreloader: true)
        editStepUseCase.execureEditStepHour(id: step.id, startTime: from, endTime: to, completion: { [weak self] result in
            self?.delegate?.viewModel(showPreloader: false)
            if case .failure(let error) = result {
                self?.delegate?.viewModel(error: error)
            }
        })
    }
}

//MARK: - Observer Protocol
extension ListOfRoutingPoisViewModel: ObserverProtocol {
    func addObservers() {
        observeUserReaction?.values.addObserver(self, observer: { [weak self] reactions in
            self?.reactions = reactions
        })
        mapRouteUseCases?.stepInfoData.addObserver(self, observer: { [weak self] stepsWithRoute in
            self?.stepInfoData = stepsWithRoute
        })
        tripModelObserverUseCase?.dailyPlan.addObserver(self, observer: { [weak self] dailyPlan in
            guard let strongSelf = self else {return}
            if dailyPlan.generatedStatus != 0 {
                strongSelf.delegate?.viewModel(showPreloader: false)
            }
            if strongSelf.isDailyPlanEmptyOrOnlyHome(dailyPlan) {
                
                if let trip = strongSelf.tripModelObserverUseCase?.trip.value {
                    if let statusMessage = dailyPlan.statusMessage {
                        if dailyPlan.generatedStatus < 0 {
                            strongSelf.delegate?.showEmptyMessage(statusMessage)
                        }
                    } else {
                        if trip.isFirstPlan(planId: dailyPlan.id) && dailyPlan.generatedStatus == -1 {
                            strongSelf.delegate?.showEmptyMessage(TRPLanguagesController.shared.getLanguageValue(for: "no_recommendations_arrival"))
                        } else if trip.isLastPlan(planId: dailyPlan.id) && dailyPlan.generatedStatus == -1 {
                            strongSelf.delegate?.showEmptyMessage(TRPLanguagesController.shared.getLanguageValue(for: "no_recommendations_departure"))
                        } else if dailyPlan.generatedStatus == 1{
                            strongSelf.delegate?.showEmptyMessage(TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.error.emptyMesssage"))
                        } else {
                            strongSelf.delegate?.clearEmptyMessage()
                        }
                    }
                }
            }
            strongSelf.steps = dailyPlan.steps
        })
    }
    
    private func isDailyPlanEmptyOrOnlyHome(_ plan: TRPPlan) -> Bool {
        if plan.steps.count == 0 {
            return true
        }
        if plan.steps.count == 1, let first = plan.steps.first?.poi, first.placeType == .hotel {
            return true
        }
        return false
    }
    
    func removeObservers() {
        observeUserReaction?.values.removeObserver(self)
        tripModelObserverUseCase?.dailyPlan.removeObserver(self)
        tripModelObserverUseCase?.trip.removeObserver(self)
        mapRouteUseCases?.stepInfoData.removeObserver(self)
    }
    
    
}
