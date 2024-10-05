//
//  TravelTimeApi.swift
//  TRPProvider
//
//  Created by Cem Çaygöz on 17.06.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation

public class TravelTimeApi {
    
    var network: Networking?
    
    internal let appId = "97f0e481"
    
    private var networkController: NetworkController?
    
    
    public init(network: Networking = Networking()) {
        self.network = network
        networkController = createNetworkController(network: network)
    }
    
    private func createNetworkController(network: Networking) -> NetworkController {
        
        var urlComponent = URLComponents()
        urlComponent.scheme = "https"
        urlComponent.host = "api.traveltimeapp.com"
        let network = NetworkController(network: network)
            .urlComponent(urlComponent)
            .addValue("X-Api-Key", value: TRPProvider.shared.getTravelTimeApiKey())
            .addValue("X-Application-Id", value: appId)
        network.provider = .travelTime
        return network
    }
}

extension TravelTimeApi {
    public func routes(departure: RouteRequestLocation,
                       arrival: RouteRequestLocation,
                       transportationType: TravelTimeTransportationTypes,
                       departureTime: Date = Date(),
                       properties: [String] = ["travel_time", "distance", "route"],
                       completion: @escaping (Result<TravelTimeRouteResult?, Error>) -> Void) {
        let path = "/v4/routes"
        let departureSearcData = RouteRequestDepartureSearch(id: "departure_search", departureLocationId: departure.id, arrivalLocationIds: [arrival.id], transportation: transportationType.value(), departureTime: departureTime.toString(), properties: properties, range: nil)
        let requestData = TravelTimeRouteRequest(locations: [departure, arrival], departureSearches: [departureSearcData], arrivalSearches: nil)
        
        _ = networkController?.encodeData(requestData)
        networkController?
            .urlComponentPath(path)
            .bodyData(requestData)
            .httpMethod(.post)
            .addValue("Content-Type", value: "application/json")
            .addValue("accept", value: "application/json")
            .responseDecodable(type: TravelTimeRouteResult.self) { (result) in
            switch result {
            case .success(let model):
                print("MODEL \(model)")
                completion(.success(model))
            case .failure(let error):
                print("Mazinga \(error)")
                completion(.failure(error))
            }
        }
    }
}
