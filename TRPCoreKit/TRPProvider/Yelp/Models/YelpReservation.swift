//
//  YelpReservation.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 14.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public struct YelpReservation: Codable {
    public let confirmationUrl: String
    public let reservationId: String
    public let notes: String
  

    enum CodingKeys: String, CodingKey {
        case confirmationUrl = "confirmation_url"
        case notes
        case reservationId = "reservation_id"
    }
}

/**
 {
     "confirmation_url": "https://www.yelp.com/reservations/rC5mIHMNF5C1Jtpb2obSkA/confirmed/6cdbc26b-1ec6-4249-9578-c1cae5f3618a?adjust_creative=68dQB46B8HiE-cyWE0sarw&checkout_success=1&utm_campaign=yelp_api_v3&utm_medium=api_v3_reservations&utm_source=68dQB46B8HiE-cyWE0sarw",
     "notes": "",
     "reservation_id": "6cdbc26b-1ec6-4249-9578-c1cae5f3618a"
 }
 */
