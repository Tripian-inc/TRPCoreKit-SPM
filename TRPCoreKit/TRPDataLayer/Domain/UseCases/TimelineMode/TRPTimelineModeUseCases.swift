//
//  TRPTimelineModeUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
final public class TRPTimelineModeUseCases: ObserveTripEventStatusUseCase {
    
    private(set) var timelineRepository: TimelineRepository
    private(set) var planRepository: TimelinePlanRepository
    private(set) var stepRepository: TimelineStepRepository
    private(set) var timelineModelRepository: TimelineModelRepository
    private(set) var poiRepository: PoiRepository
    private var generaterController: TimelinePlanGenerateController
    
    public var error: ValueObserver<ErrorResult> = .init(nil)
    public var showLoader: ValueObserver<LoaderResult> = .init(nil)
    public var successfullyUpdated: ValueObserver<EventType> = .init(nil)
    
    public init(timelineRepository: TimelineRepository = TRPTimelineRepository(),
                planRepository: TimelinePlanRepository = TRPTimelinePlanRepository(),
                stepRepository: TimelineStepRepository = TRPTimelineStepRepository(),
                timelineModelRepository: TimelineModelRepository = TRPTimelineModelRepository(),
                poiRepository: PoiRepository = TRPPoiRepository()
    ) {
        self.timelineRepository = timelineRepository
        self.planRepository = planRepository
        self.stepRepository = stepRepository
        self.timelineModelRepository = timelineModelRepository
        self.poiRepository = poiRepository
        
        generaterController = TimelinePlanGenerateController()
        generaterController.fetchPlanUseCase = self
    }
    
    private func updatePlanInTrip(plan:TRPTimelinePlan) {
        guard let trip = timelineModelRepository.timeline.value else {
            print("[Error] Trip is nil")
            return
        }
        guard trip.plans!.contains(plan) else {return }
        if let index = trip.plans?.firstIndex(of: plan) {
            var temp = timelineModelRepository.timeline.value
            temp!.plans?[index] = plan
            timelineModelRepository.timeline.value = temp
        }
    }
    
    private func deleteTripInPlan(stepId: Int) {
        guard let plan = currentPlan.value else {
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
        guard let planId = currentPlan.value?.id else {
            print("[Error] DailyPlan is nil")
            return
        }
        
        executeFetchPlan(id: planId) {[weak self] (result) in
            if case .success(let plan) = result {
                self?.updateDailyPlanInRepository(plan)
            }
        }
    }
    
    private func checkAndUpdateDailyPlan(_ newPlan: TRPTimelinePlan) {
        guard let dailyPlan = currentPlan.value else { return }
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
    private func addHomeBaseIfExist(_ dailyPlan: TRPTimelinePlan) -> TRPTimelinePlan {
        
        guard let trip = timeline.value, let accommodation = dailyPlan.accommodation else { return dailyPlan}
        
        var tempPlan = dailyPlan
        
        let stayAddress = getStepFromAccommodation(accommodation, cityId: trip.city.id)
        if let firstStep = tempPlan.steps.first, firstStep.poi?.id != accommodation.referanceId {
            tempPlan.steps.insert(stayAddress, at: 0)
        }
        
        guard let destinationAccommodation = dailyPlan.destinationAccommodation else { return tempPlan}
        
        let destinationAddress = getStepFromAccommodation(destinationAccommodation, cityId: trip.city.id)
        if let lastStep = tempPlan.steps.last, lastStep.poi?.id != destinationAccommodation.referanceId {
            tempPlan.steps.append(destinationAddress)
        }
        
        return tempPlan
    }
    
    private func getStepFromAccommodation(_ accommodation: TRPAccommodation, cityId: Int) -> TRPTimelineStep {
        
        let hotel = PoiMapper().accommodation(accommodation, cityId: cityId)
        let hotelStep = TRPTimelineStep(id: 1, poi: hotel, alternatives: [])
        return hotelStep
    }
    
    private func updateDailyPlanInRepository(_ dailyPlan: TRPTimelinePlan) {
        
        let planWithAccommondation = addHomeBaseIfExist(dailyPlan)
        
        timelineModelRepository.dailySegment.value = planWithAccommondation
    }
}

extension TRPTimelineModeUseCases: ObserveTimelineModeUseCase {
    
    public var timeline: ValueObserver<TRPTimeline> {
        return timelineModelRepository.timeline
    }
    
    public var currentPlan: ValueObserver<TRPTimelinePlan> {
        return timelineModelRepository.dailySegment
    }
    
}



extension TRPTimelineModeUseCases: FetchTimelineUseCases {
    
    public func executeFetchTimeline(tripHash: String, completion: ((Result<TRPTimeline, Error>) -> Void)?) {
        
        sendShowLoader(true, type: .fetchTrip)
        
        let onComplete = completion ?? { result in }
        
        
        if ReachabilityUseCases.shared.isOnline {
            timelineRepository.fetchTimeline(tripHash: tripHash) { [weak self] result in
                self?.sendShowLoader(false, type: .fetchTrip)
                switch result {
                case .success(let trip):
                    self?.timelineRepository.saveTimeline(tripHash: tripHash, data: trip)
                    self?.sendSuccellyUpdated(.fetchTrip)
                    self?.timelineModelRepository.timeline.value = trip
                    self?.addPoisIn(trip: trip)
                    onComplete(.success(trip))
                case .failure(let error):
                    self?.sendErrorLoader(error, type: .fetchTrip)
                    onComplete(.failure(error))
                }
            }
        }else {
            timelineRepository.fetchLocalTimeline(tripHash: tripHash) { [weak self] result in
                self?.sendShowLoader(false, type: .fetchTrip)
                switch result {
                case .success(let trip):
                    self?.sendSuccellyUpdated(.fetchTrip)
                    self?.timelineModelRepository.timeline.value = trip
                    self?.addPoisIn(trip: trip)
                    onComplete(.success(trip))
                case .failure(let error):
                    self?.sendErrorLoader(error, type: .fetchTrip)
                    onComplete(.failure(error))
                }
            }
        }
    }
    
    private func addPoisIn(trip: TRPTimeline){
        var pois = [TRPPoi]()
        trip.plans?.forEach { plan in
            pois.append(contentsOf: plan.steps.compactMap({$0.poi}))
        }
        poiRepository.addPois(contentsOf: pois)
    }
    
    private func addPoisIn(plan: TRPTimelinePlan){
        poiRepository.addPois(contentsOf: plan.steps.compactMap({$0.poi}))
    }
}


extension TRPTimelineModeUseCases: FetchTimelinePlanUseCase {
    
    public func executeFetchPlan(id: String,
                                 completion: ((Result<TRPTimelinePlan, Error>) -> Void)?) {
        
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

extension TRPTimelineModeUseCases: ChangeDailyTimelinePlanUseCase{
    
    public func executeChangeDailyPlan(id: String,
                                       completion: ((Result<TRPTimelinePlan, Error>) -> Void)?) {
        
        if let trip = timeline.value{
            if let plan = trip.plans?.first(where: { $0.id == id }) {
                if plan.generatedStatus == 0 {
                    generaterController.dailyPlanController(plan) { [weak self] generated, newPlan in
                        completion?(.success(newPlan))
                        self?.updateDailyPlanInRepository(newPlan)
                    }
                } else {
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

extension TRPTimelineModeUseCases: EditTimelinePlanUseCase {
    
    public func executeEditPlanHours(startTime: String, endTime: String, completion: ((Result<TRPTimelinePlan, Error>) -> Void)?) {
        
        guard let dailyPlanId = currentPlan.value?.id, let planId = getPlanIdForTargetDate(ids: dailyPlanId) else {
            print("[Error] Plan is nil")
            return
        }
        
        sendShowLoader(true, type: .changeTime)
        
        let onComplete = completion ?? { result in }
        planRepository.editPlanHours(planId: planId, start: startTime, end: endTime) { [weak self] result in
            
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
    
    public func executeEditPlanStepOrder(stepOrders: [Int], completion: ((Result<TRPTimelinePlan, Error>) -> Void)?) {
        
        guard let dailyPlanId = currentPlan.value?.id, let planId = getPlanIdForTargetDate(ids: dailyPlanId) else {
            print("[Error] Plan is nil")
            return
        }
        
        sendShowLoader(true, type: .changeTime)
        
        let onComplete = completion ?? { result in }
        planRepository.editPlanStepOrder(planId: planId, stepOrders: stepOrders) { [weak self] result in
            
            self?.sendShowLoader(false, type: .changeTime)
            
            switch result {
            case .success(let plan):
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

extension TRPTimelineModeUseCases: ExportItineraryUseCase {
    public func executeFetchExportItinerary(tripHash: String, completion: ((Result<TRPExportItinerary, any Error>) -> Void)?) {
        
//        guard let dailyPlan = currentPlan.value else {
//            print("[Error] Plan is nil")
//            return
//        }
//        
//        sendShowLoader(true, type: .changeTime)
//        
//        let onComplete = completion ?? { result in }
//        
//        planRepository.exportItinerary(planId: dailyPlan.id, tripHash: tripHash) { [weak self] result in
//            
//            self?.sendShowLoader(false, type: .changeTime)
//            
//            switch result {
//            case .success(let result):
//                self?.sendSuccellyUpdated(.changeTime)
//                onComplete(.success(result))
//            case .failure(let error):
//                self?.sendErrorLoader(error, type: .changeTime)
//                onComplete(.failure(error))
//            }
//        }
        
    }
    
    
}

extension TRPTimelineModeUseCases: AddTimelineStepUseCase {
    public func executeAddStep(poiId: String,
                               stepDate: String?,
                               startTime: String?,
                               endTime: String?,
                               completion: ((Result<TRPTimelineStep, any Error>) -> Void)?) {
        
        let onComplete = completion ?? { result in }
        
        guard let plan = currentPlan.value else {
            print("[Error] PlanId is nil")
            return
        }
        
        guard let planId = getPlanIdForTargetDate(start: plan.startDate, end: plan.endDate, target: stepDate, ids: plan.id) else {
            onComplete(.failure(GeneralError.customMessage("PlanId is nil")))
            return
        }
        
        
        
        sendShowLoader(true, type: .addStep)
        
        stepRepository.addStep(step: TRPTimelineStepCreate(planId: planId, poiId: poiId, startTime: startTime, endTime: endTime)) {[weak self] result in
            
            self?.sendShowLoader(false, type: .addStep)
            
            switch result {
            case .success(let step):
                self?.sendSuccellyUpdated(.addStep)
                self?.executeFetchPlan(id: plan.id, completion: nil)
                onComplete(.success(step))
            case .failure(let error):
                self?.sendErrorLoader(error, type: .addStep)
                onComplete(.failure(error))
            }
        }
    }
    
    public func executeAddCustomStep(planId: String,
                                     stepDate: String?,
                                     startTime: String?,
                                     endTime: String?,
                                     customStep: TRPTimelineStepCustomPoi?,
                                     completion: ((Result<TRPTimelineStep, any Error>) -> Void)?) {
        
        let onComplete = completion ?? { result in }
        
        guard let plan = timeline.value?.plans?.first(where: {$0.id == planId}) else {
            print("[Error] PlanId is nil")
            return
        }
        
        guard let planId = getPlanIdForTargetDate(start: plan.startDate, end: plan.endDate, target: stepDate, ids: plan.id) else {
            onComplete(.failure(GeneralError.customMessage("PlanId is nil")))
            return
        }
        
        sendShowLoader(true, type: .addStep)
        
        stepRepository.addStep(step: TRPTimelineStepCreate(planId: planId, customPoi: customStep, startTime: startTime, endTime: endTime)) {[weak self] result in
            
            self?.sendShowLoader(false, type: .addStep)
            
            switch result {
            case .success(let step):
                self?.sendSuccellyUpdated(.addStep)
                self?.executeFetchPlan(id: plan.id, completion: nil)
                onComplete(.success(step))
            case .failure(let error):
                self?.sendErrorLoader(error, type: .addStep)
                onComplete(.failure(error))
            }
        }
    }
    
    private func getPlanIdForTargetDate(
        start: String = "",
        end: String = "",
        target: String? = nil,
        ids: String,
        format: String = "yyyy-MM-dd HH:mm"
    ) -> Int? {
        
        // Split IDs into array of Ints
        let idList: [Int] = ids.split(separator: "-").compactMap { Int($0) }
        guard !idList.isEmpty else { return nil }
        
        // If only one ID, return it directly
        if idList.count == 1 {
            return idList.first
        }
        
        guard
            let startDate = Date.fromString(start, format: format),
            let endDate = Date.fromString(end, format: format)
        else { return idList.last }
        
        // If no target provided → return last id
        guard let target, let targetDate = Date.fromString(target, format: format) else {
            return idList.last
        }
        
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.day], from: startDate, to: targetDate)
        let dayIndex = comps.day ?? 0
        
        if targetDate >= startDate && targetDate <= endDate, dayIndex < idList.count {
            return idList[dayIndex]
        }
        
        return idList.last
    }
}

extension TRPTimelineModeUseCases: DeleteTimelineStepUseCase {
    
    public func executeDeletePoi(id: String, completion: ((Result<Bool, Error>) -> Void)?) {
        
        guard let plan = currentPlan.value else {
            print("[Error] Plan is nil")
            return
        }
        
        guard let step = plan.steps.first(where: {$0.poi?.id == id}) else {
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
                self?.deleteTripInPlan(stepId: id)
                self?.refetchDailyPlan()
                onComplete(.success(result))
            case .failure(let error):
                self?.sendErrorLoader(error, type: .deleteStep)
                onComplete(.failure(error))
            }
        }
    }
}

extension TRPTimelineModeUseCases: EditTimelineStepUseCase {    
    
    public func executeEditStep(id: Int,
                                poiId: String,
                                completion: ((Result<TRPTimelineStep, Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        sendShowLoader(true, type: .editStep)
        
        stepRepository.editStep(step: TRPTimelineStepEdit(stepId: id,
                                                          poiId: poiId)) { [weak self] result in
            
            self?.sendShowLoader(false, type: .editStep)
            
            switch result {
            case .success(let step):
                self?.sendSuccellyUpdated(.editStep)
                self?.refetchDailyPlan()
                onComplete(.success(step))
            case .failure(let error):
                self?.sendErrorLoader(error, type: .editStep)
                onComplete(.failure(error))
            }
        }
    }
    
    public func executeEditStepHour(id: Int,
                                    startTime: String,
                                    endTime: String,
                                    completion: ((Result<TRPTimelineStep, Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        sendShowLoader(true, type: .editStep)
        stepRepository.editStep(step: TRPTimelineStepEdit(stepId: id,
                                                          startTime: startTime,
                                                          endTime: endTime)) { [weak self] result in
            
            self?.sendShowLoader(false, type: .editStep)
            
            switch result {
            case .success(let step):
                self?.sendSuccellyUpdated(.editStep)
                self?.updateStepInPlan(step: step)
//                self?.refetchDailyPlan()
                onComplete(.success(step))
            case .failure(let error):
                self?.sendErrorLoader(error, type: .editStep)
                onComplete(.failure(error))
            }
        }
    }
    
    private func updateStepInPlan(step: TRPTimelineStep) {
        if var plan = currentPlan.value, let stepIdx = plan.steps.firstIndex(where: {$0.id == step.id}) {
            plan.steps[stepIdx] = step
            updatePlanInTrip(plan: plan)
            checkAndUpdateDailyPlan(plan)
            addPoisIn(plan: plan)
        }
    }
}

//extension TRPTimelineModeUseCases: ReOrderStepUseCase {
//    
//    public func execureReOrderStep(id: Int,
//                                   order: Int,
//                                   completion: ((Result<TRPTimelineStep, Error>) -> Void)?) {
//        
//        let onComplete = completion ?? { result in }
//        
//        sendShowLoader(true, type: .reorderStep)
//        
//        stepRepository.reOrderStep(id: id, order: order) { [weak self] result in
//            
//            self?.sendShowLoader(false, type: .reorderStep)
//            
//            switch result {
//            case .success(let step):
//                //TODO: dailyplandan yeniden çekilecek
//                self?.sendSuccellyUpdated(.reorderStep)
//                
//                self?.refetchDailyPlan()
//                onComplete(.success(step))
//            case .failure(let error):
//                self?.sendErrorLoader(error, type: .reorderStep)
//                onComplete(.failure(error))
//            }
//        }
//    }
//}


extension TRPTimelineModeUseCases: FetchAlternativeWithCategory {
    
    public func executeFetchAlternativeWithCategory(categories: [Int], completion: ((Result<[TRPPoi], Error>, TRPPagination?) -> Void)?) {
        guard let cityId = timeline.value?.city.id else {
            print("[Error] City is nil")
            return
        }
        
        guard let timeline = timeline.value else {
            print("[Error] Plan is nil")
            return
        }
        
        let onComplete = completion ?? { result, pagination in }
        
        var poiIds = [String]()
        
        timeline.plans?.forEach { plan in
    
            categories.forEach { (categoryId) in
                
                let categorySteps = plan.steps.filter({$0.poi?.categories.contains(where: {$0.id == categoryId}) == true})
                categorySteps.forEach { step in
                    poiIds.append(contentsOf: step.alternatives ?? [])
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


extension TRPTimelineModeUseCases: FetchPlanAlternative {
    
    
    public func executeFetchPlanAlternative(completion: ((Result<[TRPPoi], Error>, TRPPagination?) -> Void)?) {
        guard let cityId = timeline.value?.city.id else {
            print("[Error] City is nil")
            return
        }
        
        guard let plan = currentPlan.value else {
            print("[Error] Plan is nil")
            return
        }
        
        let onComplete = completion ?? { result, pagination in }
        
        var poiIds = [String]()
        
        plan.steps.forEach { step in
            poiIds.append(contentsOf: step.alternatives ?? [])
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


extension TRPTimelineModeUseCases: FetchStepAlternative {
    public func executeFetchStepAlternative(stepId: Int, completion: ((Result<[TRPPoi], Error>) -> Void)?) {
        
        guard let cityId = timeline.value?.city.id else {
            print("[Error] City is nil")
            return
        }
        
        guard let plan = currentPlan.value else {
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




