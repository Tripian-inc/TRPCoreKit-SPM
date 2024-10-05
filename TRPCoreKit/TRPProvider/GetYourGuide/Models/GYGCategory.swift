//
//  GYGCategory.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 14.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public struct GYGCategory: Codable {
    public let name: String
    public let categoryID: Int
    public let numberOfTours: Int?
    public let parentID: Int?
    public let numberOfParticipants: Int?
    
    enum CodingKeys: String, CodingKey {
        case name
        case categoryID = "category_id"
        case numberOfTours = "number_of_tours"
        case parentID = "parent_id"
        case numberOfParticipants = "number_of_participants"
        
    }
}
