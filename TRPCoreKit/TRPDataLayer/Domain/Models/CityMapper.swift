//
//  CityMapper.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 28.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation



/// City için model dönüşümü yapar
public class CityMapper {
    
    public func map(_ restModel: TRPCityInfoModel) -> TRPCity {
        
        let coordinate = TRPLocation(lat: restModel.coordinate.lat,
                                     lon: restModel.coordinate.lon)
        
        var newModel = TRPCity(id: restModel.id,
                               name: restModel.name,
                               coordinate: coordinate)
        
        newModel.image = restModel.image?.url
        newModel.displayName = restModel.displayName
        newModel.isPopular = restModel.isPopular
        newModel.countryName = restModel.country.name
        newModel.countryCode = restModel.country.code
        
        if let continents = restModel.country.continent {
            newModel.countryContinents = [continents]
        }
        
        newModel.continent = restModel.country.continentModel.map({
            TRPContinent(name: $0.name, slug: $0.slug)
        })
        
        if let tastes = restModel.tastes {
            newModel.tastes = TasteMapper().map(tastes)
        }
        
        if let weathers = restModel.weathers {
            newModel.weathers = weathers.map({ w in
                TRPCityWeather(date: w.date,
                               maxTempC: w.maxTempC,
                               minTempC: w.minTempC,
                               maxTempF: w.maxTempF,
                               minTempF: w.minTempF,
                               weatherIcon: w.weatherIcon,
                               weatherText: w.weatherText)
            })
        }
        
        if restModel.boundary.count == 4 {
            newModel.boundarySouthWest = TRPLocation(lat: restModel.boundary[1],
                                                     lon: restModel.boundary[3])
            newModel.boundaryNorthEast = TRPLocation(lat: restModel.boundary[0],
                                                     lon: restModel.boundary[2])
        }
        
        if let locationType = restModel.locationType {
            newModel.locationType = locationType
        }
        
        if let parentLocationId = restModel.parentLocationId {
            newModel.parentLocationId = parentLocationId
        }
        
        if let parentLocations = restModel.parentLocations {
            newModel.parentLocations = map(parentLocations)
        }
        
        if let maxTripDays = restModel.maxTripDays {
            newModel.maxTripDays = maxTripDays
        }
        
        if let timezone = restModel.timezone {
            newModel.timezone = timezone
        }
        return newModel
    }
    
    func map(_ restModels: [TRPCityInfoModel]) -> [TRPCity] {
        return restModels.map { map($0) }
    }
 
}
