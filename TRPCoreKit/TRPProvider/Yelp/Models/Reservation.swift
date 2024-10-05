//
//  Reservation.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 10.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
public class Reservation {
    
    public var businessId: String
    public var covers: Int = 1
    public var date: String
    public var time: String
    //Burada generateedilebilir.
    public var uniqueId: String
    public var holdId: String?
    public var firstName: String?
    public var lastName: String?
    public var email: String?
    public var phone: String?
    public var poiId: String?
    public var poiName: String?
    public var poiImage: String?
    public var tripHash: String?
    
    public var isValidReservation: Bool {
        if holdId == nil { print("HoldId is nil"); return false}
        
        if firstName == nil { print("Firstname is nil"); return false}
        
        if lastName == nil { print("LastName is nil"); return false }
        
        if email == nil { print("Email is nil"); return false }
        
        if phone == nil { print("phone is nil"); return false}
        
        if firstName == nil { print("Firstname is nil"); return false}

        return true
    }
    
    
    public init(businessId id: String, covers: Int = 1, date: String, time: String, uniqueId: String) {
        self.businessId = id
        self.covers = covers
        self.date = date
        self.time = time
        self.uniqueId = uniqueId
    }
    
    public convenience init(businessId id: String, covers: Int = 1, date: String, time: String) {
        let uniqueId = UIDevice.current.identifierForVendor?.uuidString ?? "tripian_unique_unknown"
        self.init(businessId: id,
                  covers: covers,
                  date: date,
                  time: time, uniqueId: uniqueId)
    }
    
    
    public func addUserInfo(firstName: String, lastName: String, email: String, phone: String) {
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
    }
    
}
