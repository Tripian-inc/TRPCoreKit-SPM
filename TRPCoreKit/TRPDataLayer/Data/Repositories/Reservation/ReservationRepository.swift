//
//  ReservationRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 25.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public typealias ReservationResultsValue = (Result<[TRPReservation], Error>)

public typealias ReservationResultValue = (Result<TRPReservation, Error>)

public typealias ReservationResultStatus = (Result<Bool, Error>)

public protocol ReservationRepository {
    
    var results: ValueObserver<[TRPReservation]> {get set}
    
    var error: ValueObserver<Error> {get set}
    
    
    func fetchReservation(cityId: Int, from: String?, to: String?, provider: String?, completion: @escaping (ReservationResultsValue) -> Void)
    
    func addReservation(key: String, provider: String, tripHash: String?, poiId: String?, value: [String : Any]?, completion: @escaping (ReservationResultValue) -> Void)
    
    func updateReservation(id: Int, key: String, provider: String, tripHash: String?, poiId: String?, value: [String : Any]?, completion: @escaping (ReservationResultValue) -> Void)
    
    func deleteReservation(id: Int, completion: @escaping (ReservationResultStatus) -> Void)
    
}


