//
//  TRPPoi.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 5.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit
import TRPRestKit

public struct TRPPoi: Codable {
    
    public static var ACCOMMODATION_ID = "9987109"
    
    public enum PlaceType: Codable {
        case poi, hotel
    }
    
    public let id: String
    public let cityId: Int
    public let name: String
    public let image: TRPImage?
    public var gallery: [TRPImage?]? = []
    public var duration: Int?
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
    public var bookings: [TRPBooking]?
    public var categories = [TRPPoiCategory]()
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
    public var additionalData: TRPAdditionalData?
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

extension TRPPoi {
    public func isBookingAvailable(providerId: Int) -> Bool {
        guard let bookings = bookings else {return false}
        let data = bookings.filter{$0.providerId == providerId}
        return data.first?.products?.isEmpty == false
    }
}

extension TRPPoi {
    public func isRatingAvailable() -> Bool {
        return rating != nil && ratingCount ?? -1 > 0
    }
    
    public func isCustomPoi() -> Bool {
        return id.starts(with: "c_")
    }
    
    public func getCustomPoiUrl(planDate: String) -> URL? {
        var poiUrl = ""
        if let bookingUrl = additionalData?.bookingUrl {
            poiUrl = bookingUrl
        }
        if poiUrl.isEmpty, let web = webUrl, web.starts(with: "http") {
            poiUrl = web
        }
        if poiUrl.isEmpty, let description = description, description.starts(with: "http") {
            poiUrl = description
        }

        return NexusHelper.getCustomPoiUrl(url: poiUrl.replacingOccurrences(of: "/en/", with: "/\(TRPClient.getLanguage())/"), startDate: planDate)
    }
    
    public func getCategoryName() -> String {
        guard let category = categories.first else { return "" }
        if category.id == 40 {
            return "NexusTours"
        }
        
        return category.name ?? ""
    }
}

extension [TRPPoi] {
    public func getPoisWith(types: [Int]) -> [TRPPoi] {
        var pois = [TRPPoi]()
        self.forEach { poi in
            let isExist = poi.categories.contains { poiType -> Bool in
                return types.contains { id -> Bool in
                    return id == poiType.id
                }
            }
            
            if isExist {
                pois.append(poi)
            }
        }
        return pois.unique()
    }
}

public struct TRPAdditionalData: Codable {
    var bookingUrl: String?
}
