//
//  TRPCreateTripUseCase.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 6.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
final public class TRPCreateTimelineUseCase {
    
    private(set) var repository: TimelineRepository
    
    public init(repository: TimelineRepository = TRPTimelineRepository()) {
        self.repository = repository
    }
    
}

extension TRPCreateTimelineUseCase: CreateTimelineUseCases {
    
    public func executeCreateTimeline(profile: TRPTimelineProfile, completion: ((Result<TRPTimeline,  Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        guard checkTripParameters(profile: profile) else {
            onComplete(.failure(GeneralError.customMessage("Timeline parameters not valid")))
//            print("[Error] Trip parameters not valid")
            return
        }
        
        repository.createTimeline(profile: profile, completion: onComplete)
    }
    
    private func checkTripParameters(profile: TRPTimelineProfile) -> Bool {
        
        if profile.segments.isEmpty {return false}
        
        
        return true
    }
    
    
}
