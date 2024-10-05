//
//  GYGReview.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 23.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public struct GYGReview: Codable {
    public let reviewID, tourID, supplierID: Int
    public let reviewDate: String
    public let subject, comment: String?
    public let reviewerName: String?
    public let reviewRating: Int

    enum CodingKeys: String, CodingKey {
        case reviewID = "review_id"
        case tourID = "tour_id"
        case supplierID = "supplier_id"
        case reviewDate = "review_date"
        case subject, comment
        case reviewerName = "reviewer_name"
        case reviewRating = "review_rating"
    }
}
