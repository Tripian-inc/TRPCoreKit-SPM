//
//  YelpHolds.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 7.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public struct YelpHolds: Codable {
    public let cancellationPolicy: String
    public let creditCardHold: Bool
    public let expiresAt: Double
    public let holdID: String
    public let isEditable: Bool
    public let lastCancellationDate: Int
    public let notes: String
    public let reserveURL: String

    enum CodingKeys: String, CodingKey {
        case cancellationPolicy = "cancellation_policy"
        case creditCardHold = "credit_card_hold"
        case expiresAt = "expires_at"
        case holdID = "hold_id"
        case isEditable = "is_editable"
        case lastCancellationDate = "last_cancellation_date"
        case notes
        case reserveURL = "reserve_url"
    }
}


/***
{
    "cancellation_policy": "Cancel before it's too late!",
    "credit_card_hold": false,
    "expires_at": 1594111911.716037,
    "hold_id": "b0NTynUky1aWxETedjGpYw",
    "is_editable": true,
    "last_cancellation_date": 1599616800.0,
    "notes": "If you end up finding this restaurant on yelp or otherwise, please note that this is not a real restaurant and won't be able to honor any reservations.",
    "reserve_url": "https://www.yelp.com/reservations/victors-french-bistro-test-listing-san-francisco/checkout/2020-09-09/1900/1?hold_id=61773311"
}
*/
