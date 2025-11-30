//
//  TRPEditTripUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 6.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

//NOTE: FetchTrip usecase i burayada eklenebilir. ????????
final public class TRPEditTimelineUseCases {
    
    private(set) var repository: TimelineRepository
    
    
    public init(repository: TimelineRepository = TRPTimelineRepository()) {
        self.repository = repository
    }
    
}

extension TRPEditTimelineUseCases: EditTimelineUseCases {
    public func executeEditTimeline(profile: TRPCreateEditTimelineProfile, completion: ((Result<TRPTimeline, any Error>) -> Void)?) {
        
//        let onComplete = completion ?? { result in }
//        TODO: - ERROR DONDURULECEK
//        guard checkTripParameters(profile: profile) else {
//            print("[Error] Trip parameters not valid")
//            return
//        }
//        profile.doNotGenerate = doNotGenerate(newProfile: profile)
//        repository.editTrip(profile: profile, completion: onComplete)
    }
    
    public func executeEditTimelineSegment(profile: TRPCreateEditTimelineSegmentProfile, completion: ((Result<Bool, any Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        repository.createEditTimelineSegment(profile: profile, completion: onComplete)
    }
    
//    private func checkTripParameters(profile: TRPCreateEditTimelineProfile) -> Bool {
//        
//        if profile.arrivalDate == nil {return false}
//        
//        if profile.departureDate == nil {return false}
//        
//        return true
//    }
    
    
}
