//
//  ItineraryUIModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2021-06-07.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import Foundation



class ItineraryUIModel {
    var poiId: String
    var poiName: String
    var order: Int
    var readableDistance: String? = nil
    var readableTime: String? = nil
    var userCar: Bool = false
    var price: Int = 0
    var reviewCount: Int = 0
    var showReaction: Bool = false
    var reaction: TRPUserReactionType? = nil
    var image: URL? = nil
    var star: Int = 0
    var category: String = ""
    var isHotel = false
    var canReplace = true
    var bookingProduct: TRPBookingProduct? = nil
    
    init(poi: TRPPoi, order: Int) {
        self.order = order
        self.poiId = poi.id
        self.poiName = poi.name
        self.price = poi.price ?? 0
        self.reviewCount = poi.ratingCount ?? 0
        self.star = Int((poi.rating ?? 0.0).rounded())
        self.category = poi.categories.first?.name ?? ""
        self.isHotel = poi.placeType == .hotel ? true : false
        self.bookingProduct = getBooking(poi: poi, providerId: 7) // JUNIPER
    }
    
    init(poiId: String, poiName: String, order: Int) {
        self.poiId = poiId
        self.poiName = poiName
        self.order = order
    }
    
    private func getBooking(poi: TRPPoi, providerId id: Int) -> TRPBookingProduct? {
        guard let bookings = poi.bookings else {return nil}
        let data = bookings.filter{$0.providerId == id}
        return data.first?.products?.first
    }
    
}
