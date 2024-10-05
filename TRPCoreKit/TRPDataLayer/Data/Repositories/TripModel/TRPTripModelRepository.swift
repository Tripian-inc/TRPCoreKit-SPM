//
//  TRPTripModelRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 12.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
final public class TRPTripModelRepository: TripModelRepository {
    
    public var trip: ValueObserver<TRPTrip> = .init(nil)
    
    public var dailyPlan: ValueObserver<TRPPlan> = .init(nil)
    
    public init() {}
}
