//
//  TrippianCommonApi.swift
//  TRPProvider
//
//  Created by Cem Çaygöz on 25.08.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation

public class TripianCommonApi {
    
    static let DEVELOPER_MODE = false
    
    var network: Networking?
    
    var apiUrl = "commonapi.tripian.com"
    
    private var networkController: NetworkController?
    
    public init(network: Networking = Networking()) {
        self.network = network
        networkController = createNetworkController(network: network)
    }
    
    private func createNetworkController(network: Networking) -> NetworkController {
        
        var urlComponent = URLComponents()
        urlComponent.scheme = "https"
        if GetYourGuideApi.DEVELOPER_MODE {
            urlComponent.host = apiUrl
        }else {
            urlComponent.host = apiUrl
        }
        let network =  NetworkController(network: network).urlComponent(urlComponent)
//            .addValue("X-ACCESS-TOKEN", value: apiKey)
        network.provider = .commonApi
        return network
    }
}

extension TripianCommonApi {
    public func getDestinationIdFromCity(_ cityId: Int,
                                         completion: @escaping (Result<JuniperCityInfo?, Error>) -> Void) {
        
        let path = "/juniper_zones/\(cityId)"
        
        networkController?
            .urlComponentPath(path)
            .responseDecodable(type: TripianCommonGenericDataParser<JuniperCityInfo>.self) { (result) in
                switch result {
                case .success(let model):
                    completion(.success(model.data))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        
    }
    
    public func getCityIdFromDestination(_ destinationId: String,
                                         completion: @escaping (Result<Int, Error>) -> Void) {
        
        let path = "/juniper_cities/\(destinationId)"
        
        networkController?
            .urlComponentPath(path)
            .responseDecodable(type: TripianCommonGenericDataParser<Int>.self) { (result) in
                switch result {
                case .success(let model):
                    completion(.success(model.data ?? 0))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        
    }
    
    public func getProducts(_ destinationId: Int,
                            startDate: String,
                            endDate: String,
                            completion: @escaping (Result<[JuniperProduct], Error>) -> Void) {
        
        let path = "/juniper_products"
        
        var params = [URLQueryItem]()
        params.append(URLQueryItem(name: "start_date", value: "\(startDate)"))
        params.append(URLQueryItem(name: "end_date", value: "\(endDate)"))
        params.append(URLQueryItem(name: "zone_id", value: "\(destinationId)"))
        
        networkController?
            .urlComponentPath(path)
            .parameters(params)
            .responseDecodable(type: TripianCommonGenericDataParser<[JuniperProduct]>.self) { (result) in
                switch result {
                case .success(let model):
                    completion(.success(model.data ?? []))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        
    }
}
