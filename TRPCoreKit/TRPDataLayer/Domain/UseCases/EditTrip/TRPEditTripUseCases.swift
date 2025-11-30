//
//  TRPEditTripUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 6.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

//NOTE: The FetchTrip use case can also be added here. ????????
final public class TRPEditTripUseCases {
    
    private(set) var repository: TripRepository
    private var oldTrip: TRPTripProfile
    
    
    public init(repository: TripRepository = TRPTripRepository(),
                oldTripProfile: TRPTripProfile) {
        self.repository = repository
        self.oldTrip = oldTripProfile
    }
    
}

extension TRPEditTripUseCases: EditTripUseCase {
    
    public func executeEditTrip(profile: TRPEditTripProfile, completion: ((Result<TRPTrip, Error>) -> Void)?) {
        
        let onComplete = completion ?? { result in }
        guard checkTripParameters(profile: profile) else {
            onComplete(.failure(GeneralError.customMessage("Trip Parameters are not valid.")))
            return
        }
        repository.editTrip(profile: profile, completion: onComplete)
    }
    
    private func checkTripParameters(profile: TRPEditTripProfile) -> Bool {
        
        if profile.arrivalDate == nil {return false}
        
        if profile.departureDate == nil {return false}
        
        return true
    }
    
    /// Compares the old trip with the new trip data.
    /// If none of the following data changes, THE TRIP WILL NOT BE REGENERATED. DO NOT GENERATE keeps the trip as it is.
    /// - Parameters:
    /// - Returns: Returns false if the trip should be regenerated, true if the trip should remain unchanged.
    public func doNotGenerate(newProfile: TRPTripProfile) -> Bool{
        
        guard let oldArrival = oldTrip.arrivalDate, let oldDeparture = oldTrip.departureDate else {return false}
        let newArrival = newProfile.arrivalDate
        let newDeparture = newProfile.departureDate
        
        if oldArrival != newArrival || oldDeparture != newDeparture {
            return false
        }
        
        let tripAnswerSet: Set<Int> = Set(oldTrip.allAnswers ?? [])
        var currentTotalAnswer: [Int] = newProfile.tripAnswers ?? []
        if let profileAnswers = newProfile.profileAnswers {
            currentTotalAnswer.append(contentsOf: profileAnswers)
        }
        let currentAnswer: Set<Int> = Set(currentTotalAnswer)
        
        //The trip will be recreated because the answers are not the same
        if tripAnswerSet != currentAnswer || tripAnswerSet.count == 0 {
            return false
        }
        
        let currentCompSet: Set<Int> = Set(newProfile.companionIds)
        let oldCompSet: Set<Int> = Set(oldTrip.companionIds)
        //Will be recreated because the number of companions is not the same
        if currentCompSet != oldCompSet {
            return false
        }
    
        if oldTrip.pace != newProfile.pace {
            return false
        }
        
        if oldTrip.theme != newProfile.theme {
            return false
        }
        
        //The trip will definitely not be changed
        return true
    }
    
    
}

