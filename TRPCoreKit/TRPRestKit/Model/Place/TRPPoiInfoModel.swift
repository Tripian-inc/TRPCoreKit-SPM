//
//  TRPPlaceInfoJsonModel.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 21.05.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation

/// This model provide you to use full information of Poi.
public struct TRPPoiInfoModel: Decodable {
    
    /// An Int value. Unique id of Poi
    public var id: String
    /// An Int value. City Id of Poi
    public var cityId: Int
    /// A String value. Name of poi
    public var name: String
    /// A String value. Featured image of poi
    public var image: TRPImageModel
    
    public var gallery: [TRPImageModel]
    /// An Int value. Indicates level of price between 0 and 4.
    public var price: Int?
    /// A Float value. Indicates how many stars poi has.
    public var rating: Float?
    /// An Int value. Indicates how many review poi has.
    public var ratingCount: Int?
    /// A String value. Description of poi.
    public var description: String?
    /// A String value. Url of web site.
    public var web: String?
    /// A String value. Phone number of  poi.
    public var phone: String?
    /// A String value. Indicates the hours of operation.
    public var hours: String?
    /// A String value. Address of poi.
    public var address: String?
    /// A String value. Icon name of poi.
    public var icon: String
    /// A TRPCoordinateModel objects. Center coordinate of poi.
    public var coordinate: TRPCoordinateModel
    
    public var bookings: [TRPBookingInfoModel]?
    
    /// A TRPCategoryInfoModel array. A poi can have multiple categories.
    public var category = [TRPCategoryInfoModel]()
    public var tags: [String]? = []
    public var mustTries: [TRPTastesInfoModel] = []
    public var cuisines: String?
    public var attention: String?
    public var safety: [String] = []
    public var closed: [Int]
    public var distance: Float?
    public var status: Bool = true
    public var offers: [TRPOfferInfoModel] = []
    
    private enum CodingKeys: String, CodingKey {
        case id
        case cityId
        case rating
        case ratingCount
        case name
        case address
        case price
        case web
        case hours
        case phone
        case image
        case icon
        case category
        case coordinate
        case description
        case cuisines
        case features
        case imageOwner
        case gallery
        case bookings
        case tags
        case attention
        case closed
        case distance
        case status
        case mustTries
        case safety
        case offers
    }
    
    /// Json to Object converter
    ///
    /// - Parameter decoder: Json Decoder Object
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try values.decode(String.self, forKey: .id)
        self.cityId = try values.decode(Int.self, forKey: .cityId)
        self.name = try values.decode(String.self, forKey: .name)
        
        self.image = try values.decode(TRPImageModel.self, forKey: .image)
        self.gallery = try values.decodeIfPresent([TRPImageModel].self, forKey: .gallery) ?? []
        self.price = try values.decodeIfPresent(Int.self, forKey: .price)
        self.rating = try values.decodeIfPresent(Float.self, forKey: .rating)
        self.ratingCount = try values.decodeIfPresent(Int.self, forKey: .ratingCount)
        
        self.address = try values.decodeIfPresent(String.self, forKey: .address)
        
        self.web = try values.decodeIfPresent(String.self, forKey: .web)
        self.hours = try values.decodeIfPresent(String.self, forKey: .hours)
        self.phone = try values.decodeIfPresent(String.self, forKey: .phone)
        
        self.icon = try values.decode(String.self, forKey: .icon)
        self.coordinate = try values.decode(TRPCoordinateModel.self, forKey: .coordinate)
        
        if let categorys = try values.decodeIfPresent([TRPCategoryInfoModel].self, forKey: .category) {
            category = categorys
        }
        if let desk = try values.decodeIfPresent(String.self, forKey: .description) {
            description = desk
        }

        self.cuisines = try values.decodeIfPresent(String.self, forKey: .cuisines)
        
        do {
             self.bookings = try values.decodeIfPresent([TRPBookingInfoModel].self, forKey: .bookings)
        }catch let error {
            print("Booking Error \(error)")
        }
        
       // self.booking = try values.decodeIfPresent([TRPBookingInfoModel].self, forKey:.booking)
        
        self.tags = try values.decodeIfPresent([String].self, forKey: .tags)
        
        self.attention = try values.decodeIfPresent(String.self, forKey: .attention)
        self.closed = try values.decodeIfPresent([Int].self, forKey: .closed) ?? []
        self.distance = try values.decodeIfPresent(Float.self, forKey: .distance)
        self.status = try values.decodeIfPresent(Bool.self, forKey: .status) ?? true
        self.safety = try values.decodeIfPresent([String].self, forKey: .safety) ?? []
    
        if let mustTries = try? values.decodeIfPresent([TRPTastesInfoModel].self, forKey: .mustTries){
            self.mustTries = mustTries ?? []
        }
        if let offers = try? values.decodeIfPresent([TRPOfferInfoModel].self, forKey: .offers) {
            self.offers = offers ?? []
        }
    }
    
}
