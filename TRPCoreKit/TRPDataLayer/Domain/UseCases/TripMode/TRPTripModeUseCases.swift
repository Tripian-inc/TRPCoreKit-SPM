//
//  TRPTripModeUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
final public class TRPTripModeUseCases: ObserveTripEventStatusUseCase {
    
    private(set) var tripRepository: TripRepository
    private(set) var planRepository: PlanRepository
    private(set) var stepRepository: StepRepository
    private(set) var tripModelRepository: TripModelRepository
    private(set) var poiRepository: PoiRepository
    private var generaterController: PlanGenerateController
    
    public var error: ValueObserver<ErrorResult> = .init(nil)
    public var showLoader: ValueObserver<LoaderResult> = .init(nil)
    public var successfullyUpdated: ValueObserver<EventType> = .init(nil)
    
    public init(tripRepository: TripRepository = TRPTripRepository(),
                planRepository: PlanRepository = TRPPlanRepository(),
                stepRepository: StepRepository = TRPStepRepository(),
                tripModelRepository: TripModelRepository = TRPTripModelRepository(),
                poiRepository: PoiRepository = TRPPoiRepository()
    ) {
        self.tripRepository = tripRepository
        self.planRepository = planRepository
        self.stepRepository = stepRepository
        self.tripModelRepository = tripModelRepository
        self.poiRepository = poiRepository
        
        generaterController = PlanGenerateController()
        generaterController.fetchPlanUseCase = self
    }
    
    private func updatePlanInTrip(plan:TRPPlan) {
        guard let trip = tripModelRepository.trip.value else {
            print("[Error] Trip is nil")
            return
        }
        guard trip.plans.contains(plan) else {return }
        if let index = trip.plans.firstIndex(of: plan) {
            var temp = tripModelRepository.trip.value
            temp!.plans[index] = plan
            tripModelRepository.trip.value = temp
        }
    }
    
    private func deleteTripInPlan(stepId: Int) {
        guard let plan = tripModelRepository.dailyPlan.value else {
            print("[Error] Plan is nil")
            return
        }
        var _plan = plan
        if let stepIndex = _plan.steps.firstIndex(where: {$0.id == stepId}) {
            _plan.steps.remove(at: stepIndex)
            updateDailyPlanInRepository(_plan)
            updatePlanInTrip(plan: _plan)
        }
    }
    
    
    private func refetchDailyPlan() {
        guard let planId = dailyPlan.value?.id else {
            print("[Error] DailyPlan is nil")
            return
        }
        
        executeFetchPlan(id: planId) {[weak self] (result) in
            if case .success(let plan) = result {
                self?.updateDailyPlanInRepository(plan)
            }
        }
    }
    
    private func checkAndUpdateDailyPlan(_ newPlan: TRPPlan) {
        guard let dailyPlan = dailyPlan.value else { return }
        if newPlan == dailyPlan {
            updateDailyPlanInRepository(newPlan)
        }
    }
    
    private func sendShowLoader(_ status: Bool, type: EventType) {
        DispatchQueue.main.async {
            self.showLoader.value = (showLoader: status, type:type)
        }
    }
    
    private func sendErrorLoader(_ error: Error, type: EventType) {
        DispatchQueue.main.async {
            self.error.value = (error: error, type: type)
        }
    }
    
    private func sendSuccellyUpdated(_ type: EventType) {
        DispatchQueue.main.async {
            self.successfullyUpdated.value = type
        }
    }
    
    
    
    /// Accommondation varsa onu PLANIN ilk basamağına ekler
    /// - Parameter dailyPlan: DailyPlan
    /// - Returns: Accommondation eklenmiş plan
    private func addHomeBaseIfExist(_ dailyPlan: TRPPlan) -> TRPPlan {
        
        guard let trip = trip.value, let accommodation = trip.tripProfile.accommodation else { return dailyPlan}
        
        let hotel = PoiMapper().accommodation(accommodation, cityId: trip.city.id)
        let hotelStep = TRPStep(id: 1, poi: hotel, alternatives: [])
        
        var tempPlan = dailyPlan
        tempPlan.steps.insert(hotelStep, at: 0)
        tempPlan.steps.append(hotelStep)
        
        return tempPlan
    }
    
    private func updateDailyPlanInRepository(_ dailyPlan: TRPPlan) {
        
        let planWithAccommondation = addHomeBaseIfExist(dailyPlan)
        
        tripModelRepository.dailyPlan.value = planWithAccommondation
    }
}

extension TRPTripModeUseCases: ObserveTripModeUseCase {
    
    public var trip: ValueObserver<TRPTrip> {
        return tripModelRepository.trip
    }
    
    public var dailyPlan: ValueObserver<TRPPlan> {
        return tripModelRepository.dailyPlan
    }
    
}



extension TRPTripModeUseCases: FetchTripUseCase {
    
    public func executeFetchTrip(tripHash: String, completion: ((Result<TRPTrip, Error>) -> Void)?) {
        
        sendShowLoader(true, type: .fetchTrip)
        
        let onComplete = completion ?? { result in }
        
        
        if ReachabilityUseCases.shared.isOnline {
            tripRepository.fetchTrip(tripHash: tripHash) { [weak self] result in
                self?.sendShowLoader(false, type: .fetchTrip)
                switch result {
                case .success(let trip):
                    self?.tripRepository.saveTrip(tripHash: tripHash, data: trip)
                    self?.sendSuccellyUpdated(.fetchTrip)
                    self?.tripModelRepository.trip.value = trip
                    self?.addPoisIn(trip: trip)
                    onComplete(.success(trip))
                case .failure(let error):
                    self?.sendErrorLoader(error, type: .fetchTrip)
                    onComplete(.failure(error))
                }
            }
        }else {
            tripRepository.fetchLocalTrip(tripHash: tripHash) { [weak self] result in
                self?.sendShowLoader(false, type: .fetchTrip)
                switch result {
                case .success(let trip):
                    self?.sendSuccellyUpdated(.fetchTrip)
                    self?.tripModelRepository.trip.value = trip
                    self?.addPoisIn(trip: trip)
                    onComplete(.success(trip))
                case .failure(let error):
                    self?.sendErrorLoader(error, type: .fetchTrip)
                    onComplete(.failure(error))
                }
            }
        }
    }
    
    private func addPoisIn(trip: TRPTrip){
        var pois = [TRPPoi]()
        trip.plans.forEach { plan in
            pois.append(contentsOf: plan.steps.map({$0.poi}))
        }
        poiRepository.addPois(contentsOf: pois)
    }
    
    private func addPoisIn(plan: TRPPlan){
        poiRepository.addPois(contentsOf: plan.steps.map({$0.poi}))
    }
}


extension TRPTripModeUseCases: FetchPlanUseCase {
    
    public func executeFetchPlan(id: Int,
                                 completion: ((Result<TRPPlan, Error>) -> Void)?) {
        
        sendShowLoader(true, type: .fetchPlan)
        
        let onComplete = completion ?? { result in }
        planRepository.fetchPlan(id: id) { [weak self] result in
            
            self?.sendShowLoader(false, type: .fetchPlan)
            
            switch result {
            case .success(let plan):
                self?.sendSuccellyUpdated(.fetchPlan)
                self?.updatePlanInTrip(plan: plan)
                self?.checkAndUpdateDailyPlan(plan)
                self?.addPoisIn(plan: plan)
                onComplete(.success(plan))
            case .failure(let error):
                self?.sendErrorLoader(error, type: .fetchPlan)
                onComplete(.failure(error))
            }
        }
    }
    
}

extension TRPTripModeUseCases: ChangeDailyPlanUseCase{
    
    public func executeChangeDailyPlan(id: Int,
                                       completion: ((Result<TRPPlan, Error>) -> Void)?) {
        
        if let trip = trip.value{
            if let plan = trip.plans.first(where: { $0.id == id }) {
                if plan.generatedStatus == 0 {
                    generaterController.dailyPlanController(plan) { [weak self] generated, newPlan in
                        completion?(.success(newPlan))
                        self?.updateDailyPlanInRepository(newPlan)
                    }
                }else {
                    
                    completion?(.success(plan))
                    updateDailyPlanInRepository(plan)
                }
            }else {
                print("[Error] \(id) plan is not exist")
            }
        }else {
            print("[Error] Trip is nil")
        }
    }
    
}

extension TRPTripModeUseCases: EditPlanHoursUseCase {
    
    public func executeEditPlanHours(startTime: String, endTime: String, completion: ((Result<TRPPlan, Error>) -> Void)?) {
        
        guard let dailyPlan = dailyPlan.value else {
            print("[Error] Plan is nil")
            return
        }
        
        sendShowLoader(true, type: .changeTime)
        
        let onComplete = completion ?? { result in }
        planRepository.editPlanHours(planId: dailyPlan.id, start: startTime, end: endTime) { [weak self] result in
            
            self?.sendShowLoader(false, type: .changeTime)
            
            switch result {
            case .success(let plan):
                // TODO: - PLAN BOŞ GELDİĞİ İÇİN plan loop mekanizması ile tekrar çekilecek.
                self?.sendSuccellyUpdated(.changeTime)
                
                if plan.generatedStatus == 0 {
                    self?.generaterController.dailyPlanController(plan) { [weak self] generated, newPlan in
                        completion?(.success(newPlan))
                        self?.updateDailyPlanInRepository(newPlan)
                    }
                }else {
                    completion?(.success(plan))
                    self?.updateDailyPlanInRepository(plan)
                }
                
            case .failure(let error):
                self?.sendErrorLoader(error, type: .changeTime)
                onComplete(.failure(error))
            }
        }
        
    }
    
    
}

extension TRPTripModeUseCases: ExportItineraryUseCase {
    public func executeFetchExportItinerary(tripHash: String, completion: ((Result<TRPExportItinerary, any Error>) -> Void)?) {
        
        guard let dailyPlan = dailyPlan.value else {
            print("[Error] Plan is nil")
            return
        }
        
        sendShowLoader(true, type: .changeTime)
        
        let onComplete = completion ?? { result in }
        
        planRepository.exportItinerary(planId: dailyPlan.id, tripHash: tripHash) { [weak self] result in
            
            self?.sendShowLoader(false, type: .changeTime)
            
            switch result {
            case .success(let result):
                self?.sendSuccellyUpdated(.changeTime)
                onComplete(.success(result))
            case .failure(let error):
                self?.sendErrorLoader(error, type: .changeTime)
                onComplete(.failure(error))
            }
        }
        
    }
    
    
}

extension TRPTripModeUseCases: AddStepUseCase {
    
    public func executeAddStep(poiId: String,
                               completion: ((Result<TRPStep, Error>) -> Void)?) {
        guard let planId = tripModelRepository.dailyPlan.value?.id else {
            print("[Error] PlanId is nil")
            return
        }
        
        sendShowLoader(true, type: .addStep)
        
        let onComplete = completion ?? { result in }
        
        stepRepository.addStep(planId: planId, poiId: poiId) {[weak self] result in
            
            self?.sendShowLoader(false, type: .addStep)
            
            switch result {
            case .success(let step):
                self?.sendSuccellyUpdated(.addStep)
                self?.executeFetchPlan(id: planId, completion: nil)
                onComplete(.success(step))
            case .failure(let error):
                self?.sendErrorLoader(error, type: .addStep)
                onComplete(.failure(error))
            }
        }
    }
}

extension TRPTripModeUseCases: DeleteStepUseCase {
    
    public func executeDeletePoi(id: String, completion: ((Result<Bool, Error>) -> Void)?) {
        
        guard let plan = dailyPlan.value else {
            print("[Error] Plan is nil")
            return
        }
        
        guard let step = plan.steps.first(where: {$0.poi.id == id}) else {
            print("[Error] Poi not found")
            return
        }
        
        executeDeleteStep(id: step.id, completion: completion)
    }
    
    public func executeDeleteStep(id: Int,
                                  completion: ((Result<Bool, Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        
        sendShowLoader(true, type: .deleteStep)
        
        stepRepository.deleteStep(id: id) { [weak self] result in
            
            self?.sendShowLoader(false, type: .deleteStep)
            
            switch result {
            case .success(let result):
                self?.sendSuccellyUpdated(.deleteStep)
                //TODO: - DeleteTripInPlan home base bugından dolayı kapatıldı TERAR DÜZENLENECEK
                //self?.deleteTripInPlan(stepId: id)
                self?.refetchDailyPlan()
                onComplete(.success(result))
            case .failure(let error):
                self?.sendErrorLoader(error, type: .deleteStep)
                onComplete(.failure(error))
            }
        }
    }
}

extension TRPTripModeUseCases: EditStepUseCase {
    
    public func execureEditStep(id: Int,
                                poiId: String,
                                completion: ((Result<TRPStep, Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        guard let planId = tripModelRepository.dailyPlan.value?.id else {
            print("[Error] PlanId is nil")
            return
        }
        sendShowLoader(true, type: .editStep)
        stepRepository.editStep(id: id, poiId: poiId) { [weak self] result in
            
            self?.sendShowLoader(false, type: .editStep)
            
            switch result {
            case .success(let step):
                //TODO: dailyplandan değiştirilecek
                self?.sendSuccellyUpdated(.editStep)
                self?.refetchDailyPlan()
                onComplete(.success(step))
            case .failure(let error):
                self?.sendErrorLoader(error, type: .editStep)
                onComplete(.failure(error))
            }
        }
    }
}

extension TRPTripModeUseCases: ReOrderStepUseCase {
    
    public func execureReOrderStep(id: Int,
                                   order: Int,
                                   completion: ((Result<TRPStep, Error>) -> Void)?) {
        
        let onComplete = completion ?? { result in }
        
        sendShowLoader(true, type: .reorderStep)
        
        stepRepository.reOrderStep(id: id, order: order) { [weak self] result in
            
            self?.sendShowLoader(false, type: .reorderStep)
            
            switch result {
            case .success(let step):
                //TODO: dailyplandan yeniden çekilecek
                self?.sendSuccellyUpdated(.reorderStep)
                
                self?.refetchDailyPlan()
                onComplete(.success(step))
            case .failure(let error):
                self?.sendErrorLoader(error, type: .reorderStep)
                onComplete(.failure(error))
            }
        }
    }
}


extension TRPTripModeUseCases: FetchAlternativeWithCategory {
    
    public func executeFetchAlternativeWithCategory(categories: [Int], completion: ((Result<[TRPPoi], Error>, TRPPagination?) -> Void)?) {
        guard let cityId = trip.value?.city.id else {
            print("[Error] City is nil")
            return
        }
        
        guard let trip = trip.value else {
            print("[Error] Plan is nil")
            return
        }
        
        let onComplete = completion ?? { result, pagination in }
        
        var poiIds = [String]()
        
        trip.plans.forEach { plan in
    
            categories.forEach { (categoryId) in
                
                let categorySteps = plan.steps.filter({$0.poi.categories.contains(where: {$0.id == categoryId})})
                categorySteps.forEach { step in
                    poiIds.append(contentsOf: step.alternatives)
                }
            }
            
        }
        
        
        let params = PoiParameters(poiIds: poiIds)
        
        poiRepository.fetchPoi(cityId: cityId, parameters: params) { result, pagination in
            
            switch result {
            case .success(let pois):
                onComplete(.success(pois), pagination)
            case .failure(let error):
                onComplete(.failure(error), pagination)
            }
        }
    }
    
}


extension TRPTripModeUseCases: FetchPlanAlternative {
    
    
    public func executeFetchPlanAlternative(completion: ((Result<[TRPPoi], Error>, TRPPagination?) -> Void)?) {
        guard let cityId = trip.value?.city.id else {
            print("[Error] City is nil")
            return
        }
        
        guard let plan = dailyPlan.value else {
            print("[Error] Plan is nil")
            return
        }
        
        let onComplete = completion ?? { result, pagination in }
        
        var poiIds = [String]()
        
        plan.steps.forEach { step in
            poiIds.append(contentsOf: step.alternatives)
        }
        
        let params = PoiParameters(poiIds: poiIds, limit: 99)
        
        poiRepository.fetchPoi(cityId: cityId, parameters: params) { result, pagination in
            
            switch result {
            case .success(let pois):
                onComplete(.success(pois), pagination)
            case .failure(let error):
                onComplete(.failure(error), pagination)
            }
        }
        
    }
    
}


extension TRPTripModeUseCases: FetchStepAlternative {
    public func executeFetchStepAlternative(stepId: Int, completion: ((Result<[TRPPoi], Error>) -> Void)?) {
        
        guard let cityId = trip.value?.city.id else {
            print("[Error] City is nil")
            return
        }
        
        guard let plan = dailyPlan.value else {
            print("[Error] Plan is nil")
            return
        }
        
        guard let step = plan.steps.first(where: {$0.id == stepId}) else {
            print("[Error] Step not exist in plan")
            return
        }
        
        let onComplete = completion ?? { result in }
        
        let params = PoiParameters(poiIds: step.alternatives)
        poiRepository.fetchPoi(cityId: cityId, parameters: params) { result, _ in
            
            switch result {
            case .success(let pois):
                onComplete(.success(pois))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
        
        
    }
    
    
}




