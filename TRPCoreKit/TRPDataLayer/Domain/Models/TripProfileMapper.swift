//
//  TripProfileMapper.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation



/// Favorite için model dönüşümü yapar
final class TripProfileMapper {
    
    func map(_ restModel: TRPTripProfileModel, _ tripModel: TRPTripModel? = nil) -> TRPTripProfile? {
        
        guard let arrival = restModel.arrivalDateTime,
            let departure = restModel.departureDateTime else {return nil}
        let newModel = TRPTripProfile(cityId: restModel.cityId)
        
        newModel.arrivalDate = arrival
        newModel.departureDate = departure
        newModel.allAnswers = restModel.answers
        
        newModel.companionIds = restModel.companionIds
        newModel.numberOfAdults = restModel.numberOfAdults
        newModel.numberOfChildren = restModel.numberOfChildren ?? 0
        
        if let pace = restModel.pace {
            newModel.pace = TRPPace(rawValue: pace) ?? TRPPace.normal
        }
        
        if let accommondation = restModel.accommodation {
            newModel.accommodation = AccommondationMapper().map(accommondation)
        }
        
        if let theme = restModel.theme {
            newModel.theme = TRPPreGeneratedTheme(rawValue: theme)
        }
        if let excludeHash = restModel.excludeHash {
            newModel.excludeHash = excludeHash
        }
        
        newModel.additionalData = restModel.additionalData
        return newModel
    }
    
    func map(_ restModels: [TRPTripProfileModel]) -> [TRPTripProfile] {
        return restModels.compactMap{ map($0) }
    }
 
    public func makeTripSettings(editTripProfile: TRPEditTripProfile, tripHash: String) ->  TRPTripSettings?{
        let tripSetting = makeTripSettings(profile: editTripProfile, tripHash: tripHash)
        tripSetting?.doNotGenerate = editTripProfile.doNotGenerate
        return tripSetting
    }
    
    
    public func makeTripSettings(profile: TRPTripProfile, tripHash: String? = nil) ->  TRPTripSettings?{
        
        guard let departure = profile.departureDate, let arrival = profile.arrivalDate else {
            print("[Error] Departure or arrival date can't empty.")
            return nil
        }
        
        var settings: TRPTripSettings?
        
        if let tripHash = tripHash {
            settings = TRPTripSettings(hash: tripHash, arrivalTime: arrival, departureTime: departure)
        }else {
            settings = TRPTripSettings(cityId: profile.cityId, arrivalTime: arrival, departureTime: departure)
        }
        
        guard let setting = settings else {return nil}
        setting.cityId = profile.cityId
        setting.tripAnswer = profile.tripAnswers ?? []
        setting.profileAnswer = profile.profileAnswers ?? []
        setting.adultsCount = profile.numberOfAdults
        setting.childrenCount = profile.numberOfChildren
        setting.pace = profile.pace.rawValue
        setting.selectedCompanionIds = profile.companionIds
        setting.additionalData = profile.additionalData
        if let theme = profile.theme {
            setting.theme = theme.rawValue
        }
        if let excludeHash = profile.excludeHash {
            setting.excludeHash = excludeHash
        }
        
        if let accommondation = profile.accommodation {
            let restKitAccommondation = Accommondation(refId: accommondation.referanceId,
                                                       name: accommondation.name,
                                                       address: accommondation.address,
                                                       coordinate: accommondation.coordinate)
            setting.setAccommondation(restKitAccommondation)
        }
        setting.withOffers = profile.withOffers
        print(setting)
        return setting
    }
}
