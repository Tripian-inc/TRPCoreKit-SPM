//
//  TripAllDayUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 19.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol FetchTripCheckAllPlanUseCase{
    
    func executeFetchTripCheckAllPlanGenerate(tripHash: String, completion: ((Result<TRPTrip, Error>) -> Void)?)
}


public protocol ObserveTripCheckAllPlanUseCase {

    var trip: ValueObserver<TRPTrip> { get }
    
    var firstTripGenerated: ValueObserver<Bool> { get set}
}
