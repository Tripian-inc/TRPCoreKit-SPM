//
//  TRPUserTripUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public final class TRPUserTripUseCases: ObserverController {
   
    private(set) var repository: UserTripRepository
    
    public init(repository: UserTripRepository = TRPUserTripRepository()) {
        self.repository = repository
    }
    
    private var currentDate: String {
        return Date().toString(format: "YYYY-MM-dd")
    }
    
    private func removeTripInPastTrip(tripHash: String) {
        guard var trips = repository.pastTrips.value else {return}
        if let index = trips.firstIndex(where: {$0.tripHash == tripHash}) {
            trips.remove(at: index)
        }
        repository.pastTrips.value = trips
    }
    
    private func removeTripInUpcommingTrip(tripHash: String) {
        guard var trips = repository.upcomingTrips.value else {return}
        if let index = trips.firstIndex(where: {$0.tripHash == tripHash}) {
            trips.remove(at: index)
        }
        repository.upcomingTrips.value = trips
    }
    
    public func remove() {
        repository.upcomingTrips.removeObservers()
        repository.pastTrips.removeObservers()
    }
}

extension TRPUserTripUseCases: ObserveUserUpcomingTripsUseCase,
                                ObserveUserPastTripsUseCase {
    
    public var upcomingTrips: ValueObserver<[TRPUserTrip]> {
        return repository.upcomingTrips
    }
    
    public var pastTrips: ValueObserver<[TRPUserTrip]> {
        return repository.pastTrips
    }
}



extension TRPUserTripUseCases: FetchUserPastTripUseCase {
    
    public func executePastTrip(completion: ((Result<[TRPUserTrip], Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        
        repository.fetchTrip(to: currentDate) { [weak self] (result) in
            switch(result) {
            case .success(let trips):
                self?.repository.pastTrips.value = trips
                onComplete(.success(trips))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
    
}

extension TRPUserTripUseCases: FetchUserUpcomingTripUseCase {
    
    public func executeUpcomingTrip(completion: ((Result<[TRPUserTrip], Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        if ReachabilityUseCases.shared.isOnline {
            repository.fetchTrip(from: currentDate) { [weak self] (result) in
                switch(result) {
                case .success(let trips):
                    self?.repository.upcomingTrips.value = trips
                    onComplete(.success(trips))
                case .failure(let error):
                    onComplete(.failure(error))
                }
            }
        }else {
            repository.fetchLocalTrip { [weak self] (result) in
                switch(result) {
                case .success(let trips):
                    self?.repository.upcomingTrips.value = trips
                    onComplete(.success(trips))
                case .failure(let error):
                    onComplete(.failure(error))
                }
            }
        }
    }
    
}

extension TRPUserTripUseCases: DeleteUserTripUseCase {
    
    public func executeDeleteTrip(tripHash: String, completion: ((Result<Bool, Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        repository.deleteTrip(tripHash: tripHash) { [weak self] result in
            switch(result) {
            case .success(let status):
                print("Delete status \(status)")
                if status {
                    self?.removeTripInPastTrip(tripHash: tripHash)
                    self?.removeTripInUpcommingTrip(tripHash: tripHash)
                }
                onComplete(.success(status))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
    
}

/*extension TRPUserTripUseCases: FetchUserTripToUseCase {
 
 public func executeFetchUserTripTo(_ to: String, completion: ((Result<[TRPUserTrip], Error>) -> Void)?) {
 
 let onComplete = completion ?? { result in }
 
 repository.fetchTrip(to: to) { [weak self] (result) in
 switch(result) {
 case .success(let favorites):
 self?.repository.toTrips = favorites
 onComplete(.success(favorites))
 case .failure(let error):
 onComplete(.failure(error))
 }
 }
 
 }
 
 }
 
 extension TRPUserTripUseCases: FetchUserTripFromUseCase {
 
 public func executeFetchUserTripFrom(_ from: String, completion: ((Result<[TRPUserTrip], Error>) -> Void)?) {
 
 let onComplete = completion ?? { result in }
 
 repository.fetchTrip(from: from) { [weak self] (result) in
 switch(result) {
 case .success(let favorites):
 self?.repository.fromTrips = favorites
 onComplete(.success(favorites))
 case .failure(let error):
 onComplete(.failure(error))
 }
 }
 
 }
 
 
 }
 */
