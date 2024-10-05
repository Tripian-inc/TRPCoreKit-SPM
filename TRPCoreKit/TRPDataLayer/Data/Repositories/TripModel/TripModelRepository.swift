//
//  TripModelRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol TripModelRepository {
    
    
    /// Tüm Trip(1.2.3. gün)
    var trip: ValueObserver<TRPTrip> {get set}
    
    
    /// Secilen gün
    var dailyPlan: ValueObserver<TRPPlan> {get set}
    
}

