//
//  StayAddressViewModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 30.01.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit
import TRPFoundationKit
import CoreLocation
import TRPDataLayer
protocol StayAddressVMDelegate: ViewModelDelegate {
    func stayAddressVMSelectedPlace(id: String, location: TRPLocation, hotelAddress: String, name: String?)
}

class StayAddressViewModel {
    
    var googleApiKey: String?
    weak var delegate: StayAddressVMDelegate? = nil
    
    var data:[TRPGooglePlace] = [] {
        didSet {delegate?.viewModel(dataLoaded: true) }
    }
    private let boundaryNW: TRPLocation?
    private let boundaryES: TRPLocation?
    private var cityCenter: TRPLocation?
    private var radius: Double?
    private var accommondation: TRPAccommodation?
    
    private var meetingPoint: String?
    
    public var accommondationId: String? {
        return accommondation?.referanceId
    }
    
    public var acommondationTitle: String? {
        if let name = accommondation?.name {
            return name
        }else if let address = accommondation?.address {
            return address
        }
        return nil
    }
    
    
    init(boundaryNW: TRPLocation?, boundaryES: TRPLocation?, accommondation: TRPAccommodation? = nil, meetingPoint: String?) {
        self.boundaryNW = boundaryNW
        self.boundaryES = boundaryES
        self.accommondation = accommondation
        self.cityCenter = calculateCenter()
        if let key = TRPApiKeyController.getKey(TRPApiKeys.trpGooglePlace) {
            googleApiKey = key
        }else {
            Log.e("TRPGooglePlaceApi key not found")
        }
        self.meetingPoint = meetingPoint
    }
    
    public func getMainTitle() -> String {
        return TRPLanguagesController.shared.getLanguageValue(for: "trips.createNewTrip.form.travelerInfo.accommodation.label")
    }
    
    public func getGooglePlaceCount() -> Int {
        return data.count
    }
    
    public func getGooglePlace(indexPath: IndexPath) -> TRPGooglePlace {
        return data[indexPath.row]
    }
    
    func getCellModel(at indexPath: IndexPath) -> StayAddressCellModel {
        return StayAddressCellModel(place: getGooglePlace(indexPath: indexPath))
    }
    
    func getDefaultSearchText() -> String {
        searchMeetingPoint()
        return meetingPoint ?? ""
    }
    
    func clearData() {
        data = []
    }
    
    func searchMeetingPoint() {
        if let meetingPoint = self.meetingPoint {
            searchAddress(text: meetingPoint)
        }
    }
    
    private func calculateCenter() -> TRPLocation? {
        guard let boundaryNW = boundaryNW, let boundaryES = boundaryES else {return nil}
        let centerLat = ( boundaryNW.lat + boundaryES.lat ) / 2
        let centerLon = ( boundaryNW.lon + boundaryES.lon ) / 2
        let distance = CLLocation(latitude: centerLat, longitude: centerLon).distance(from: CLLocation(latitude: boundaryNW.lat, longitude: boundaryNW.lon))
        radius = Double(distance)
        return TRPLocation(lat: centerLat, lon: centerLon)
    }
    
    public func searchAddress(text: String)  {
        guard let apiKey = googleApiKey else {
            Log.e("TRPGooglePlaceApi can not found")
            return
        }
        self.delegate?.viewModel(showPreloader: true)
        TRPRestKit().googleAutoComplete(key: apiKey,
                                        text: text,
                                        centerForBoundary: cityCenter,
                                        radiusForBoundary: radius) {[weak self] (data, error) in
            guard let strongSelf = self else {return}
            strongSelf.delegate?.viewModel(showPreloader: false)
            if let error = error {
                strongSelf.delegate?.viewModel(error: error)
                return
            }
            if let data = data as? [TRPGooglePlace] {
                strongSelf.data = data
                
            }
        }
    }
    
    public func searchPlace(withId id: String)  {
        guard let apiKey = googleApiKey else {
            Log.e("TRPGooglePlaceApi can not found")
            return
        }
        TRPRestKit().googlePlace(key: apiKey, id: id) {[weak self] (data, error) in
            guard let strongSelf = self else {return}
            if let error = error {
                
                strongSelf.delegate?.viewModel(error: error)
                
                return
            }
            
            if let data = data as? TRPGooglePlaceLocation {
                strongSelf.delegate?.stayAddressVMSelectedPlace(id: id,
                                                                location: data.location,
                                                                hotelAddress: data.hotelAddress,
                                                                name: data.name)
            }
            
        }
    }
    
}
