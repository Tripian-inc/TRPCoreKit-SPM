//
//  TripianCommonGenericDataParser.swift
//  TRPProvider
//
//  Created by Cem Çaygöz on 25.08.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
internal class TripianCommonGenericDataParser<T: Decodable>: Decodable {
    
    public var data: T?
    public var status: Int?
    public var message: String?

    private enum CodingKeys: String, CodingKey {
        case data
        case message
        case status
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.data = try values.decodeIfPresent(T.self, forKey: .data)
        self.message = try values.decodeIfPresent(String.self, forKey: .message)
        self.status = try values.decodeIfPresent(Int.self, forKey: .status)
    }
    
}
