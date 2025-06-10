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
    var rating: Float = 0.0
    var category: String = ""
    var isHotel = false
    var canReplace = true
    var startTime: String = ""
    var endTime: String = ""
    var isProduct: Bool = false
    var bookingUrl: String? = nil
    var bookingProduct: TRPBookingProduct? = nil
    
    init(step: TRPStep, order: Int) {
        self.order = order
        self.poiId = step.poi.id
        self.poiName = step.poi.name
        self.price = step.poi.price ?? 0
        self.reviewCount = step.poi.ratingCount ?? 0
        self.rating = step.poi.rating ?? 0.0
        self.star = Int((step.poi.rating ?? 0.0).rounded())
        self.category = step.poi.getCategoryName()
        self.isHotel = step.isHotelPoi()
        self.startTime = step.times?.from ?? ""
        self.endTime = step.times?.to ?? ""
        self.isProduct = step.poi.isCustomPoi()
        self.bookingProduct = getBooking(poi: step.poi, providerId: 7) // JUNIPER
        self.bookingUrl = step.poi.additionalData?.bookingUrl
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
