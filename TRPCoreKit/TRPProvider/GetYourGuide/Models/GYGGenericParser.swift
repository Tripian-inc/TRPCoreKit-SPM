//
//  GYGGenericParser.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 11.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
internal class GYGGenericDataParser<T: Decodable>: Decodable {
    
    public var data: T?

    private enum CodingKeys: String, CodingKey {
        case data
        
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.data = try values.decodeIfPresent(T.self, forKey: .data)
    }
    
}



