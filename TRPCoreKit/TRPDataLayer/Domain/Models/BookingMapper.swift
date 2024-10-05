//
//  BookingMapper.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 13.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

final class BookingMapper {
    
    func map(_ restModel: TRPBookingInfoModel) -> TRPBooking {
        
        let products = restModel.products != nil ? BookingProductMapper().map(restModel.products!) : nil
        
        return TRPBooking(providerId: restModel.providerId, providerName: restModel.providerName, products: products)
    }
   
    
    func map(_ restModels: [TRPBookingInfoModel]) -> [TRPBooking] {
        restModels.map { map($0) }
    }
}

final class BookingProductMapper {
    
    func map(_ restModel: TRPBookingProductInfoModel) -> TRPBookingProduct? {
        guard let id = restModel.id, let title = restModel.title else {return nil}
        return TRPBookingProduct(id: id,
                          title: title,
                          currency: restModel.currency,
                          price: restModel.price,
                          priceDescription: restModel.priceDescription,
                          image: restModel.image,
                          rating: restModel.rating,
                          ratingCount: restModel.ratingCount,
                          duration: restModel.duration,
                          info: restModel.info ?? [],
                          url: restModel.url)
    }
    
    func map(_ restModel: [TRPBookingProductInfoModel]) -> [TRPBookingProduct]? {
        var mappedList = [TRPBookingProduct]()
        restModel.forEach { model in
            guard let mappedModel = map(model) else {return}
            mappedList.append(mappedModel)
        }
        return mappedList
    }
    
}
