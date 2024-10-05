//
//  GYGTours.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 14.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
internal class GYGTours: Decodable {
    
    public var tours: [GYGTour]?
    
    private enum CodingKeys: String, CodingKey {
        case tours
    }
    
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.tours = try values.decodeIfPresent([GYGTour].self, forKey: .tours)
    }
    
}
