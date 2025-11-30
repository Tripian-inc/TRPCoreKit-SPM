//
//  TRPUserTripUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public final class TRPUserTimelineUseCases: ObserverController {
   
    private(set) var repository: UserTimelineRepository
    
    public init(repository: UserTimelineRepository = TRPUserTimelineRepository()) {
        self.repository = repository
    }
    
    private var currentDate: String {
        return Date().toString(format: "YYYY-MM-dd")
    }
    
    private func removeTimelineInPastTimelines(tripHash: String) {
        guard var trips = repository.pastTimelines.value else {return}
        if let index = trips.firstIndex(where: {$0.tripHash == tripHash}) {
            trips.remove(at: index)
        }
        repository.pastTimelines.value = trips
    }
    
    private func removeTimelineInUpcommingTimelines(tripHash: String) {
        guard var trips = repository.upcomingTimelines.value else {return}
        if let index = trips.firstIndex(where: {$0.tripHash == tripHash}) {
            trips.remove(at: index)
        }
        repository.upcomingTimelines.value = trips
    }
    
    public func remove() {
        repository.upcomingTimelines.removeObservers()
        repository.pastTimelines.removeObservers()
    }
}

extension TRPUserTimelineUseCases: ObserveUserUpcomingTimelinesUseCase,
                                ObserveUserPastTimelinesUseCase {
    
    public var upcomingTimelines: ValueObserver<[TRPTimeline]> {
        return repository.upcomingTimelines
    }
    
    public var pastTimelines: ValueObserver<[TRPTimeline]> {
        return repository.pastTimelines
    }
}



extension TRPUserTimelineUseCases: FetchUserPastTimelineUseCase {
    
    public func executePastTimeline(completion: ((Result<[TRPTimeline], Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        
        repository.fetchTimeline(to: currentDate) { [weak self] (result) in
            switch(result) {
            case .success(let trips):
                self?.repository.pastTimelines.value = trips
                onComplete(.success(trips))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
    
}

extension TRPUserTimelineUseCases: FetchUserUpcomingTimelineUseCase {
    
    public func executeUpcomingTimeline(completion: ((Result<[TRPTimeline], Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        if ReachabilityUseCases.shared.isOnline {
            repository.fetchTimeline(from: currentDate) { [weak self] (result) in
                switch(result) {
                case .success(let trips):
                    self?.repository.upcomingTimelines.value = trips.sorted(by: {
                        $0.tripProfile?.getOldestStartDate() ?? Date() < $1.tripProfile?.getOldestStartDate() ?? Date()
                    })
                    onComplete(.success(trips))
                case .failure(let error):
                    onComplete(.failure(error))
                }
            }
        }else {
            repository.fetchLocalTimeline { [weak self] (result) in
                switch(result) {
                case .success(let trips):
                    self?.repository.upcomingTimelines.value = trips
                    onComplete(.success(trips))
                case .failure(let error):
                    onComplete(.failure(error))
                }
            }
        }
    }
    
}

extension TRPUserTimelineUseCases: DeleteUserTimelineUseCase {
    
    public func executeDeleteTimeline(tripHash: String, completion: ((Result<Bool, Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        repository.deleteTimeline(tripHash: tripHash) { [weak self] result in
            switch(result) {
            case .success(let status):
                print("Delete status \(status)")
                if status {
                    self?.removeTimelineInPastTimelines(tripHash: tripHash)
                    self?.removeTimelineInUpcommingTimelines(tripHash: tripHash)
                }
                onComplete(.success(status))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
    
}
