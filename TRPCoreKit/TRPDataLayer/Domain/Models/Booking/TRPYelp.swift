//
//  TRPYelp.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 25.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public struct TRPYelp: Codable {
    
    public var confirmURL: String
    public var reservationID: String
    public var restaurantImage: String?
    public var restaurantName: String?
    public var reservationDetail: TRPYelpReservationDetail?
    
    public init(confirmURL: String,
                reservationID: String,
                restaurantImage: String?,
                restaurantName: String?,
                reservationDetail: TRPYelpReservationDetail?) {
        self.confirmURL = confirmURL
        self.reservationID = reservationID
        self.restaurantImage = restaurantImage
        self.restaurantName = restaurantName
        self.reservationDetail = reservationDetail
    }
    
    enum CodingKeys: String, CodingKey {
        case confirmURL = "confirmUrl"
        case reservationID = "reservationId"
        case restaurantImage = "restaurantImage"
        case restaurantName = "restaurantName"
        case reservationDetail = "reservationDetails"
    }
    
    public func getParams() -> [String: Any] {
        var params = [String: Any]()
        params[CodingKeys.confirmURL.rawValue] = confirmURL
        params[CodingKeys.reservationID.rawValue] = reservationID
        params[CodingKeys.restaurantImage.rawValue] = restaurantImage
        params[CodingKeys.restaurantName.rawValue] = restaurantName
        params[CodingKeys.reservationDetail.rawValue] = reservationDetail?.getParams()
        return params
    }
    
}


public struct TRPYelpReservationDetail: Codable {
    
    public var businessID: String
    public var covers: Int
    public var time, date: String
    public var uniqueID: String
    public var phone: String?
    public var holdID: String?
    public var firstName: String?
    public var lastName: String?
    public var email: String?
    
    
    public init(businessID: String, covers: Int, time: String, date: String, uniqueID: String, phone: String?, holdID: String?, firstName: String?, lastName: String?, email: String?) {
        self.businessID = businessID
        self.covers = covers
        self.time = time
        self.date = date
        self.uniqueID = uniqueID
        self.phone = phone
        self.holdID = holdID
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
    }
    
    enum CodingKeys: String, CodingKey {
        case businessID = "businessId"
        case covers, time
        case holdID = "holdId"
        case firstName, phone, date, email
        case uniqueID = "uniqueId"
        case lastName
    }
    
    public func getParams() -> [String: Any] {
        var params = [String: Any]()
        params[CodingKeys.businessID.rawValue] = businessID
        params[CodingKeys.covers.rawValue] = covers
        params[CodingKeys.time.rawValue] = time
        params[CodingKeys.holdID.rawValue] = holdID
        params[CodingKeys.firstName.rawValue] = firstName
        params[CodingKeys.lastName.rawValue] = lastName
        params[CodingKeys.phone.rawValue] = phone
        params[CodingKeys.date.rawValue] = date
        params[CodingKeys.email.rawValue] = email
        params[CodingKeys.uniqueID.rawValue] = uniqueID
        return params
    }
}



