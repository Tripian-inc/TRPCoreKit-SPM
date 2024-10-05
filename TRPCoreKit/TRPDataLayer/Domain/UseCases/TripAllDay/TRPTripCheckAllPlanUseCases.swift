//
//  TRPTripCheckAllPlanUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 19.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public final class TRPTripCheckAllPlanUseCases {
    
    private(set) var tripRepository: TripRepository
    private(set) var tripModelRepository: TripModelRepository
    private(set) var generateController: TripGenerateController?
    
    //ObserveTripCheckAllPlanUseCase
    public var firstTripGenerated: ValueObserver<Bool> = .init(false)
    
    public var generatedStatus: Int = 0
    
    public init(tripRepository: TripRepository = TRPTripRepository(),
                tripModelRepository: TripModelRepository = TRPTripModelRepository()) {
        self.tripRepository = tripRepository
        self.tripModelRepository = tripModelRepository
        
        generateController = TripGenerateController()
        generateController?.repository = self.tripRepository
    }
    
    private func checkFirstTripStatus(trip: TRPTrip) {
    
        if firstTripGenerated.value == true {return}
        
        for plan in trip.plans {
            if plan.generatedStatus != 0 {
                self.generatedStatus = plan.generatedStatus
                firstTripGenerated.value = true
                break
            }
        }
    }
    
}


extension TRPTripCheckAllPlanUseCases: ObserveTripCheckAllPlanUseCase{
    
    public var trip: ValueObserver<TRPTrip> {
        return tripModelRepository.trip
    }
    
}


extension TRPTripCheckAllPlanUseCases: FetchTripCheckAllPlanUseCase {
    
    public func executeFetchTripCheckAllPlanGenerate(tripHash: String,
                                                     completion: ((Result<TRPTrip, Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        
        generateController?.fetchTrip(hash: tripHash, completion: { [weak self] result in
            switch result {
            case .success(let trip):
                self?.tripModelRepository.trip.value = trip
                self?.checkFirstTripStatus(trip: trip)
                onComplete(.success(trip))
            case .failure(let error):
                onComplete(.failure(error))
            }
        })
    }

}
