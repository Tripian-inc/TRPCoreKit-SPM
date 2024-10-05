//
//  TravelTimeGenericDataParser.swift
//  TRPProvider
//
//  Created by Cem Çaygöz on 17.06.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation

internal class TravelTimeGenericDataParser<T: Decodable>: Decodable {
    
    public var results: T?

    private enum CodingKeys: String, CodingKey {
        case results
        
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.results = try values.decodeIfPresent(T.self, forKey: .results)
    }
    
}
