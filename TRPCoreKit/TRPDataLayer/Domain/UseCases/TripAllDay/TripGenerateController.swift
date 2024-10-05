//
//  TripGenerateController.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 19.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
class TripGenerateController {
    
    private var dailyPlanGeneraterInterval: Float = 2
    private var dailyPlanGeneraterLimit = 30
    public var repository: TripRepository?
    
    
    init() {}
    
    
    public func fetchTrip(hash: String, completion: ((Result<TRPTrip, Error>) -> Void)?) {
        
        repository?.fetchTrip(tripHash: hash, completion: { result in
            switch result {
            case .success(let trip):
                let generated = trip.plans.map({$0.generatedStatus})
                
                if generated.contains(0) {
                    //TODO: LİMİT KOYULACAK
                    DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [weak self] in
                        self?.fetchTrip(hash: hash, completion: completion)
                    }
                }
                completion?(.success(trip))
            case .failure(let error):
                completion?(.failure(error))
            }
        })
        
    }
    
    
}
