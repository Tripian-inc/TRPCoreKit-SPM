//
//  TRPExportPlanJsonModel.swift
//  TRPRestKit
//
//  Created by Cem Çaygöz on 4.04.2023.
//  Copyright © 2023 Evren Yaşar. All rights reserved.
//

import Foundation

public struct TRPExportPlanJsonModel: Decodable {
    
    public var url: String
    
    private enum CodingKeys: String, CodingKey {
        case url
    }
    
    /// Initializes a new object with decoder
    ///
    /// - Parameter decoder: Json decoder
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.url = try values.decode(String.self, forKey: .url)
    }
    
}
