//
//  TRPPoi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 5.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation


public struct TRPPoi: Codable {
    
    public static var ACCOMMODATION_ID = "9987109"
    
    public enum PlaceType: Codable {
        case poi, hotel
    }
    
    public let id: String
    public let cityId: Int
    public let name: String
    public let image: TRPImage
    public var gallery: [TRPImage] = []
    public var price: Int?
    public var rating: Float?
    public var ratingCount: Int?
    public var description: String?
    
    public var webUrl: String?
    public var phone: String?
    public var hours: String?
    public var address: String?
    public let icon: String
    
    public let coordinate: TRPLocation
//    public let markerCoordinate: TRPLocation?
    public var bookings: [TRPBooking]?
    public var categories = [TRPCategory]()
    public var tags = [String]()
    public var mustTries = [TRPTaste]()
    public var cuisines: String?
    public var attention: String?
    public var closed = [Int]()
    public var distance: Float?
    public var safety = [String]()
    
    public let status: Bool
    
    public var placeType = PlaceType.poi
    
    public var offers: [TRPOffer] = []
}

extension TRPPoi: Equatable {
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
}


extension TRPPoi: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}
