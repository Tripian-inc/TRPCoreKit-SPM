//
//  ReservationUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 2.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public protocol FetchReservationUseCase {
    
    func executefetchReservation(cityId: Int, from: String?, to: String?, completion: ((Result<[TRPReservation], Error>) -> Void)?)
    
}

public protocol AddReservationUseCase {
    
    func executeAddReservation(key: String, provider: String, tripHash: String?, poiId: String?, values: [String: Any]?, completion: ((Result<TRPReservation, Error>) -> Void)?)
    
}

public protocol DeleteReservationUseCase {
    
    func executeDeleteReservation(id: Int, completion: ((Result<Bool, Error>) -> Void)?)
    
}

public protocol UpdateReservationUseCase {
    
    func executeUpdateReservation(id: Int, key: String, provider: String, tripHash: String?, poiId: String?, values: [String: Any]?, completion: ((Result<TRPReservation, Error>) -> Void)?)
}

public protocol ObserveReservationUseCase {
    
    

    var reservations: ValueObserver<[TRPReservation]> { get }

}
