//
//  TRPCreateTripUseCase.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 6.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
final public class TRPCreateTripUseCase {
    
    private(set) var repository: TripRepository
    
    public init(repository: TripRepository = TRPTripRepository()) {
        self.repository = repository
    }
    
}

extension TRPCreateTripUseCase: CreateTripUseCase {
    
    public func executeCreateTrip(profile: TRPTripProfile, completion: ((Result<TRPTrip,  Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        //TODO: - ERROR DONDURULECEK
        guard checkTripParameters(profile: profile) else {
            print("[Error] Trip parameters not valid")
            return
        }
        
        repository.createTrip(profile: profile, completion: onComplete)
    }
    
    private func checkTripParameters(profile: TRPTripProfile) -> Bool {
        
        if profile.arrivalDate == nil {return false}
        
        if profile.departureDate == nil {return false}
        
        
        return true
    }
    
    
}
