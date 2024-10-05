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
    func callCreateTripWithDestination(startDate: String, endDate: String, city: TRPCity, destinationId: Int)
}

public class MyTripViewModel {
    
    public init(){}
    
    public var fetchCityUseCase: FetchCityUseCase?
    public weak var delegate: MyTripViewModelDelegate?
    
    private var startDate: String? = nil
    private var endDate: String? = nil
    private var destinationId: String? = nil
    
    let paging = [TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.upComingTrips.title"),
                  TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.pastTrips.title")]
    
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
        destinationId = url.valueOfURL("destinationID")
        guard let destinationID = destinationId else {return}
        fetchDestinationWithTripianCity(destinationId: destinationID)
    }
    
    private func fetchDestinationWithTripianCity(destinationId: String) {
    
        delegate?.viewModel(showPreloader: true)
        TripianCommonApi().getCityIdFromDestination(destinationId) { [weak self] result in
            switch(result) {
            case .success(let city):
                if city > 0 {
                    self?.getTripianCity(cityId: city)
                } else {
                    self?.delegate?.viewModel(showPreloader: false)
                }
            case .failure(let error):
                self?.delegate?.viewModel(showPreloader: false)
//                self?.delegate?.viewModel(error: error)
                print(error.localizedDescription)
            }
        }
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
        guard let destinationId = destinationId, let destId = Int(destinationId) else {return}
        delegate?.callCreateTripWithDestination(startDate: startDate!, endDate: endDate!, city: city, destinationId: destId)
    }
   
    deinit {
       Log.deInitialize()
    }
}

struct JuniperCityResponse: Decodable {
    let data: Int
    let status: Int
}
