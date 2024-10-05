//
//  TRPGenericParser.swift
//  TRPRestKit
//
//  Created by Evren Yaşar on 28.02.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation
public class TRPGenericParser<T: Decodable>: TRPParentJsonModel {
    
    public var data: T?
    
    private enum CodingKeys: String, CodingKey {
        case data
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        self.data = try values.decodeIfPresent(T.self, forKey: .data)
        try super.init(from: decoder)
    }
    
}
