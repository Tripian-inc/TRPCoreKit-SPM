//
//  BookingCellModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 15.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public struct BookingCellModel {
    
    var id: Int
    var title: String
    var date: String?
    var time: String?
    var image: URL?
    var confirmUrl: URL?
    var provider: String
    var cityName: String?
    var ticketUrl: String?
    var cancelInfo: String?
    var bookingHash: String?
    
    public init(reservation: TRPReservation, yelp: TRPYelp) {
        id = reservation.id
        title = yelp.restaurantName ?? ""
        image = URL(string: yelp.restaurantImage ?? "")
        confirmUrl = URL(string: yelp.confirmURL)
        provider = reservation.provider
        
        if let yelpDate = yelp.reservationDetail?.date {
            self.date = yelpDate
        }
        
        if let time = yelp.reservationDetail?.time {
            self.time = time
        }
        
        if self.date != nil && self.time != nil {
            let totalTime = date! + " " + time!
            if let date = totalTime.toDate(format: "yyyy-MM-dd HH:mm:ss") {
                self.date = date.toString(format: nil, dateStyle: .medium, timeStyle: .short)
                self.time = nil
            }
        }
        
    }
    
    public init(reservation: TRPReservation, gyg: TRPGyg) {
        id = reservation.id
        title = gyg.tourName
        cityName = gyg.cityName
        provider = "GYG"
        ticketUrl = gyg.ticketUrl
        cancelInfo = gyg.cancellation_policy_text
        bookingHash = gyg.bookingHash
        let image = (gyg.image ).replacingOccurrences(of: "[format_id]", with: "21")
        if let url = URL(string: image ) {
            self.image = url
        }
        if let url = URL(string: gyg.ticketUrl) {
            self.confirmUrl = url
        }
    }
    
    
}
