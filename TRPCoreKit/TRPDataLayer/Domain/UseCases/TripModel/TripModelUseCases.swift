//
//  TripModelUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol ObserveTripModeUseCase {
    

    var trip: ValueObserver<TRPTrip> { get }
    
    var dailyPlan: ValueObserver<TRPPlan> { get }
}



