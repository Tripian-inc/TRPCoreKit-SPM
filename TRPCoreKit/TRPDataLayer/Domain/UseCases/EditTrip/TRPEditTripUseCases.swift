//
//  TRPEditTripUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 6.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

//NOTE: FetchTrip usecase i burayada eklenebilir. ????????
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
        //TODO: - ERROR DONDURULECEK
        guard checkTripParameters(profile: profile) else {
            print("[Error] Trip parameters not valid")
            return
        }
//        profile.doNotGenerate = doNotGenerate(newProfile: profile)
        repository.editTrip(profile: profile, completion: onComplete)
    }
    
    private func checkTripParameters(profile: TRPEditTripProfile) -> Bool {
        
        if profile.arrivalDate == nil {return false}
        
        if profile.departureDate == nil {return false}
        
        return true
    }
    
    /// Eski trip ile yeni trip verileri karşılaştırır.
    /// Eğer aşağıdaki veriler hiç değişme yok TRIP YENİDEN OLUŞTURULMAYACAKTIR. DO NOT GENERATE trip i eskisi gibi tutar.
    /// - Parameters:
    /// - Returns: False ise trip yeniden oluşturulur, true ise trip olduğu gibi kalır.
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
        
        //Cevaplar aynı olmadığı için trip yeniden yaratılacak
        if tripAnswerSet != currentAnswer || tripAnswerSet.count == 0 {
            return false
        }
        
        let currentCompSet: Set<Int> = Set(newProfile.companionIds)
        let oldCompSet: Set<Int> = Set(oldTrip.companionIds)
        //Companion sayısı aynı olmadığı için yeniden yaratılacak
        if currentCompSet != oldCompSet {
            return false
        }
    
        if oldTrip.pace != newProfile.pace {
            return false
        }
        
        if oldTrip.theme != newProfile.theme {
            return false
        }
        
        //Trip kesinlikle değiştirilmeyecek
        return true
    }
    
    
}
