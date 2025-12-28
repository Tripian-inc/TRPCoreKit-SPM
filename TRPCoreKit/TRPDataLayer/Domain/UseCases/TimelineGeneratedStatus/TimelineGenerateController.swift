//
//  TripGenerateController.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 19.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
class TimelineGenerateController {
    
    private var dailyPlanGeneraterInterval: DispatchTimeInterval = .seconds(2)
    private var dailyPlanGeneraterLimit = 30
    private var dailyPlanGeneraterCount = 0
    public var repository: TimelineRepository?
    
    
    init() {}
    
    
    public func fetchTimeline(hash: String, completion: ((Result<TRPTimeline, Error>) -> Void)?) {
        
        repository?.fetchTimeline(tripHash: hash, completion: { [weak self] result in
            guard let self else {
                completion?(.failure(GeneralError.customMessageKey("trips.myTrips.itinerary.offers.payment.error.somethingWentWrong")))
                return
            }
            self.dailyPlanGeneraterCount += 1
            if self.dailyPlanGeneraterCount > self.dailyPlanGeneraterLimit {
                completion?(.failure(GeneralError.customMessageKey("trips.myTrips.itinerary.offers.payment.error.somethingWentWrong")))
                self.dailyPlanGeneraterCount = 0
                return
            }
            switch result {
            case .success(let trip):
                // If there are no plans (only booked/reserved activities), consider it as successfully generated
                guard let plans = trip.plans, !plans.isEmpty else {
                    completion?(.success(trip))
                    return
                }

                let generated = plans.map({$0.generatedStatus})

                if generated.contains(0) {
                    DispatchQueue.global().asyncAfter(deadline: .now() + self.dailyPlanGeneraterInterval) { [weak self] in
                        self?.fetchTimeline(hash: hash, completion: completion)
                    }
                }

                guard let firstStatus = generated.first else { return }
                if firstStatus > 0 {
                    completion?(.success(trip))
                } else if firstStatus < 0 {
                    completion?(.failure(GeneralError.customMessageKey("trips.myTrips.itinerary.error.generatedStatusNegative1")))
                }
            case .failure(let error):
                completion?(.failure(error))
            }
        })
        
    }
    
    
}
