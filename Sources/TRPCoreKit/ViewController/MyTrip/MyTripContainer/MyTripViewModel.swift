//
//  MyTripViewModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 16.10.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit
import Alamofire
import TRPDataLayer
import TRPProvider

public protocol MyTripViewModelDelegate: ViewModelDelegate{
    func callCreateTripWithDestination(startDate: String, endDate: String, city: TRPCity, destinationId: String)
}

public class MyTripViewModel {
    
    public init(){}
    
    public var fetchCityUseCase: FetchCityUseCase?
    public weak var delegate: MyTripViewModelDelegate?
    
    private var startDate: String? = nil
    private var endDate: String? = nil
    
    private var destinationId: String? = nil
    
    let paging = [TRPAppearanceSettings.MyTrip.upcomingString.toLocalized(),
                  TRPAppearanceSettings.MyTrip.pastTripString]
    
    public func getTitle() -> String {
        return "MyTrips"
    }
    
    public func getPagingTitle(index: Int) -> String {
        return paging[index]
    }
    
    public func getPagingNumber() -> Int {
        return paging.count
    }
    
    public func setupDetailUrl(_ url: String) {
        startDate = url.valueOfURL("startDate")
        endDate = url.valueOfURL("endDate")
        let destinationID = url.valueOfURL("destinationID")
        guard let destinationID = destinationID else {return}
        fetchDestinationWithTripianCity(destinationId: destinationID)
    }
    
    private func fetchDestinationWithTripianCity(destinationId: String) {
//        let url = "https://commonapi.tripian.com/juniper_cities/109303"
    
        self.destinationId = destinationId
        delegate?.viewModel(showPreloader: true)
        TripianCommonApi().getCityIdFromDestination(destinationId) { [weak self] result in
            switch(result) {
            case .success(let city):
                self?.getTripianCity(cityId: city)
            case .failure(let error):
                self?.delegate?.viewModel(error: error)
            }
        }
//        AF.request(url).responseDecodable(of: JuniperCityResponse.self) { response in
//            switch response.result {
//            case .success(let cityResponse):
//                print("City Data received: \(cityResponse.data), Status: \(cityResponse.status)")
//                // Handle the received city data and status here
//                self.getTripianCity(cityId: cityResponse.data)
//                
//            case .failure(let error):
//                self.delegate?.viewModel(showPreloader: false)
//                print("Error: \(error)")
//            }
//        }
    }
    
    private func getTripianCity(cityId: Int) {
        fetchCityUseCase?.executeFetchCity(id: cityId, completion: { [weak self] result in
            self?.delegate?.viewModel(showPreloader: false)
            switch(result) {
            case .success(let city):
                self?.callCreateTripWithDestination(city: city)
            case .failure(let error):
                self?.delegate?.viewModel(error: error)
            }
        })
    }
    
    func callCreateTripWithDestination(city: TRPCity) {
        delegate?.callCreateTripWithDestination(startDate: startDate!, endDate: endDate!, city: city, destinationId: destinationId!)
    }
   
    deinit {
       Log.deInitialize()
    }
}

struct JuniperCityResponse: Decodable {
    let data: Int
    let status: Int
}
