//
//  YelpApi.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 2.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public class YelpApi {
    var network: Networking?
    internal let sandboxToken = "sandbox"
    
    internal let productToken = "product"
    private var networkController: NetworkController?
    
    internal var token = ""
    
    public init(network: Networking = Networking(), isProduct: Bool = true) {
        self.network = network
        token = isProduct ? productToken : sandboxToken
        networkController = createNetworkController(network: network)
    }
    
    private func createNetworkController(network: Networking) -> NetworkController {
        var urlComponent = URLComponents()
        urlComponent.scheme = "https"
        urlComponent.host = "api.yelp.com"
        return NetworkController(network: network)
            .urlComponent(urlComponent)
            .setBodyDataType(.dictionary)
            .addValue("Authorization", value: "Bearer \(token)")
            
    }
    
}

//MARK: - Business
extension YelpApi {
    // businesses/${businessId}
    //TODO: - TİME VE DATE EKLENECEK
    public func business(id: String, completion: @escaping (Result<YelpBusiness, Error>) -> Void) {
        let path = "/v3/businesses/\(id)"
        networkController?
            .urlComponentPath(path)
            .responseDecodable(type: YelpBusiness.self) { (result) in
            switch result {
            case .success(let model):
                completion(.success(model))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

//MARK: - Openings
extension YelpApi {
    // /bookings/${businessId}/openings
    // https://api.yelp.com/v3/bookings/rC5mIHMNF5C1Jtpb2obSkA/openings?covers=1&date=2020-09-09&time=06:30
    
    public func openings(businessId id: String, covers: Int = 1, date:String, time: String, completion: @escaping (Result<YelpOpenings, Error>)-> Void ) {
        let path = "/v3/bookings/\(id)/openings"
        let params = ["covers": "\(covers)", "date":date, "time": time]
        
        networkController?
            .urlComponentPath(path)
            .parameters(params)
            .responseDecodable(type: YelpOpenings.self) { (result) in
                switch result {
                case .success(let model):
                    completion(.success(model))
                case .failure(let error):
                    completion(.failure(error))
                }
        }
    }
    
}


//MARK: - Hold
extension YelpApi {
    // /bookings/${businessId}/holds
    
    public func hold(reservation: Reservation,
                     completion: @escaping (Result<YelpHolds, Error>)-> Void) {
        
        
        hold(businessId: reservation.businessId,
             covers: reservation.covers,
             date: reservation.date,
             time: reservation.time,
             uniqueId: reservation.uniqueId, completion: completion)
    }
    
    public func hold(businessId id: String,
                     covers: Int = 1,
                     date:String,
                     time: String,
                     uniqueId: String,
                     completion: @escaping (Result<YelpHolds, Error>)-> Void ) {
        let path = "/v3/bookings/\(id)/holds"
        let bodyParams = ["covers": "\(covers)", "date":date, "time": time, "unique_id" : uniqueId]
        networkController?
            .urlComponentPath(path)
            .httpMethod(.post)
            .addValue("Content-Type", value: "application/x-www-form-urlencoded")
            .bodyParameters(bodyParams)
            .responseDecodable(type: YelpHolds.self) { (result) in
                switch result {
                case .success(let model):
                    completion(.success(model))
                case .failure(let error):
                    completion(.failure(error))
                }
        }
    }
}

//MARK: - Reservation
extension YelpApi {
    
    public func reservations(reservation: Reservation,
                             completion: @escaping (Result<YelpReservation, Error>)-> Void) {
        
        if !reservation.isValidReservation {
            print("Reservation values are not valid")
            return
        }
        
        reservations(businessId: reservation.businessId,
                     covers: reservation.covers,
                     date: reservation.date,
                     time: reservation.time,
                     uniqueId: reservation.uniqueId,
                     holdId: reservation.holdId! ,
                     firstName: reservation.firstName!,
                     lastName: reservation.lastName!,
                     email: reservation.email!,
                     phone: reservation.phone ?? "0", completion: completion)
    }
    
    public func reservations(businessId id: String,
                             covers: Int,
                             date: String,
                             time: String,
                             uniqueId: String,
                             holdId: String,
                             firstName: String,
                             lastName: String,
                             email: String,
                             phone: String,
                             completion: @escaping (Result<YelpReservation, Error>)-> Void ) {
        
        let path = "/v3/bookings/\(id)/reservations"
        let bodyParams = ["covers": "\(covers)",
            "date":date,
            "time": time,
            "unique_id" : uniqueId,
            "hold_id": holdId,
            "first_name":firstName,
            "last_name":lastName,
            "email":email,
            "phone":phone]
        print("")
        print("-----")
        print("RESERVATİON \(bodyParams)")
        networkController?
            .urlComponentPath(path)
            .httpMethod(.post)
            .addValue("Content-Type", value: "application/x-www-form-urlencoded")
            .bodyParameters(bodyParams)
            .responseDecodable(type: YelpReservation.self) { (result) in
                switch result {
                case .success(let model):
                    completion(.success(model))
                case .failure(let error):
                    completion(.failure(error))
                }
        }
        
    }
    
    
}


//MARK: - ReservationStatus
extension YelpApi {
    
    public func reservationStatus(reservationId id: String, completion: @escaping (Result<YelpStatus, Error>) -> Void) {
        let path = "/v3/bookings/reservation/\(id)/status"
        networkController?.urlComponentPath(path).responseDecodable(type: YelpStatus.self) { (result) in
            switch result {
            case .success(let model):
                completion(.success(model))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
}

//MARK: - ReservationCancel
extension YelpApi {
    
    public func reservationCancel(reservationId id: String, completion: @escaping (Result<YelpBusiness, Error>) -> Void) {
        let path = "/v3/bookings/reservation/\(id)/cancel"
        networkController?.urlComponentPath(path).responseDecodable(type: YelpBusiness.self) { (result) in
            switch result {
            case .success(let model):
                completion(.success(model))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
}

//MARK: - HELPER
extension YelpApi {
    
}
