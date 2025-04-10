//
//  PoiMapper.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 5.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation




final class PoiMapper {
    
    func map(_ restModel: TRPPoiInfoModel) -> TRPPoi? {
        
        let mainImage = ImageMapper().map(restModel.image)
        
        let gallery = ImageMapper().map(restModel.gallery)
        
        let coordinate: TRPLocation = TRPLocation(lat: restModel.coordinate.lat, lon: restModel.coordinate.lon)
        
//        let markerCoordinate: TRPLocation? = restModel.markerCoordinate != nil ? TRPLocation(lat: restModel.markerCoordinate!.lat, lon: restModel.markerCoordinate!.lon) : nil
        
        let bookings: [TRPBooking]? = restModel.bookings != nil ? BookingMapper().map(restModel.bookings ?? []) : nil
        
        let categoreies = PoiCategoryMapper().map(restModel.category)
        
        let mustTaste = TasteMapper().map(restModel.mustTries)
        let offers = OfferMapper().map(restModel.offers)
        let additionalData = AdditionalDataMapper().map(restModel.additionalData)
        
        return TRPPoi(id: restModel.id,
                      cityId: restModel.cityId,
                      name: restModel.name,
                      image: mainImage,
                      gallery: gallery,
                      duration: restModel.duration,
                      price: restModel.price,
                      rating: restModel.rating,
                      ratingCount: restModel.ratingCount,
                      description: restModel.description,
                      webUrl: restModel.web,
                      phone: restModel.phone,
                      hours: restModel.hours,
                      address: restModel.address,
                      icon: restModel.icon,
                      coordinate: coordinate,
//                      markerCoordinate: markerCoordinate,
                      bookings: bookings,
                      categories: categoreies,
                      tags: restModel.tags ?? [],
                      mustTries: mustTaste,
                      cuisines: restModel.cuisines,
                      attention: restModel.attention,
                      closed: restModel.closed,
                      distance: restModel.distance,
                      safety: restModel.safety,
                      status: restModel.status,
                      placeType: .poi,
                      offers: offers,
                      additionalData: additionalData)
    }
    
    
    func map(_ restModels: [TRPPoiInfoModel]) -> [TRPPoi] {
        restModels.compactMap{ map($0) }
    }

    
    
    func accommodation(_ referance: TRPAccommodation, cityId: Int) -> TRPPoi {
        
        let image = TRPImage(url: "", imageOwner: nil, width: nil, height: nil)
        
        return TRPPoi(id: TRPPoi.ACCOMMODATION_ID,
                      cityId: cityId,
                      name: referance.name ?? "Home",
                      image: image,
                      gallery: [],
                      price: nil,
                      rating: nil,
                      ratingCount: nil,
                      description: nil,
                      webUrl: nil,
                      phone: nil,
                      hours: nil,
                      address: referance.address,
                      icon: "Homebase",
                      coordinate: referance.coordinate,
//                      markerCoordinate: nil,
                      bookings: nil,
                      categories: [],
                      tags: [],
                      mustTries: [],
                      cuisines: nil,
                      attention: nil,
                      closed: [],
                      distance: nil,
                      status: true,
                      placeType: .hotel,
                      offers: [])
    }
}
