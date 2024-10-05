//
//  BusinessModel.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 2.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public struct YelpBusiness: Decodable {
    public let id: String
    public let alias: String?
    public let name: String
    public let imageURL: String
    public let isClaimed, isClosed: Bool
    public let url: String?
    public let phone, displayPhone: String?
    public let reviewCount: Int?
    public let categories: [YelpCategory?]
    public let rating: Int?
    public let location: YelpLocation?
    public let coordinates: YelpCoordinates?
    public let photos: [String?]
    public let price: String?
    public let hours: [YelpHour?]
    public let transactions: [String?]
    let messaging: YelpMessaging?
    
    enum CodingKeys: String, CodingKey {
        case id, alias, name
        case imageURL = "image_url"
        case isClaimed = "is_claimed"
        case isClosed = "is_closed"
        case url, phone
        case displayPhone = "display_phone"
        case reviewCount = "review_count"
        case categories, rating, location, coordinates, photos, price, hours, transactions, messaging
    }
}

// MARK: - Category
public struct YelpCategory: Codable {
    let alias, title: String
}

// MARK: - Coordinates
public struct YelpCoordinates: Codable {
    let latitude, longitude: Double?
}

// MARK: - Hour
public struct YelpHour: Codable {
    let hourOpen: [YelpOpen]
    let hoursType: String
    let isOpenNow: Bool

    enum CodingKeys: String, CodingKey {
        case hourOpen = "open"
        case hoursType = "hours_type"
        case isOpenNow = "is_open_now"
    }
}

// MARK: - Open
public struct YelpOpen: Codable {
    public let isOvernight: Bool?
    public let start, end: String?
    public let day: Int?

    enum CodingKeys: String, CodingKey {
        case isOvernight = "is_overnight"
        case start, end, day
    }
}

// MARK: - Location
public struct YelpLocation: Codable {
    let address1, address2, address3, city: String?
    let zipCode, country, state: String?
    let displayAddress: [String?]
    let crossStreets: String?

    enum CodingKeys: String, CodingKey {
        case address1, address2, address3, city
        case zipCode = "zip_code"
        case country, state
        case displayAddress = "display_address"
        case crossStreets = "cross_streets"
    }
}


public struct YelpMessaging: Codable {
    public let url: String?
    public let useCaseText: String?

    enum CodingKeys: String, CodingKey {
        case url
        case useCaseText = "use_case_text"
    }
}

/**
{
    "id": "gR9DTbKCvezQlqvD7_FzPw",
    "alias": "north-india-restaurant-san-francisco",
    "name": "North India Restaurant",
    "image_url": "https://s3-media1.fl.yelpcdn.com/bphoto/howYvOKNPXU9A5KUahEXLA/o.jpg",
    "is_claimed": true,
    "is_closed": false,
    "url": "https://www.yelp.com/biz/north-india-restaurant-san-francisco?adjust_creative=liqimTxDxUYNXavoxs15Pg&utm_campaign=yelp_api_v3&utm_medium=api_v3_business_lookup&utm_source=liqimTxDxUYNXavoxs15Pg",
    "phone": "+14153481234",
    "display_phone": "(415) 348-1234",
    "review_count": 1740,
    "categories": [
        {
            "alias": "indpak",
            "title": "Indian"
        }
    ],
    "rating": 4.0,
    "location": {
        "address1": "123 Second St",
        "address2": "",
        "address3": "",
        "city": "San Francisco",
        "zip_code": "94105",
        "country": "US",
        "state": "CA",
        "display_address": [
            "123 Second St",
            "San Francisco, CA 94105"
        ],
        "cross_streets": ""
    },
    "coordinates": {
        "latitude": 37.787789124691,
        "longitude": -122.399305736113
    },
    "photos": [
        "https://s3-media1.fl.yelpcdn.com/bphoto/howYvOKNPXU9A5KUahEXLA/o.jpg",
        "https://s3-media2.fl.yelpcdn.com/bphoto/I-CX8nioj3_ybAAYmhZcYg/o.jpg",
        "https://s3-media3.fl.yelpcdn.com/bphoto/uaSNfzJUiFDzMeSCwTcs-A/o.jpg"
    ],
    "price": "$$",
    "hours": [
        {
            "open": [
                {
                    "is_overnight": false,
                    "start": "1000",
                    "end": "2300",
                    "day": 0
                },
                {
                    "is_overnight": false,
                    "start": "1000",
                    "end": "2300",
                    "day": 1
                },
                {
                    "is_overnight": false,
                    "start": "1000",
                    "end": "2300",
                    "day": 2
                },
                {
                    "is_overnight": false,
                    "start": "1000",
                    "end": "2300",
                    "day": 3
                },
                {
                    "is_overnight": false,
                    "start": "1000",
                    "end": "2330",
                    "day": 4
                },
                {
                    "is_overnight": false,
                    "start": "1000",
                    "end": "2330",
                    "day": 5
                },
                {
                    "is_overnight": false,
                    "start": "1000",
                    "end": "2300",
                    "day": 6
                }
            ],
            "hours_type": "REGULAR",
            "is_open_now": false
        }
    ],
    "transactions": [
        "delivery",
        "restaurant_reservation",
        "pickup"
    ]
}
*/
