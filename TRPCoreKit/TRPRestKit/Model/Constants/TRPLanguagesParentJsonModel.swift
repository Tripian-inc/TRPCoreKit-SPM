//
//  TRPLanguagesParentJsonModel.swift
//  TRPRestKit
//
//  Created by Cem Çaygöz on 8.09.2024.
//  Copyright © 2024 Evren Yaşar. All rights reserved.
//

import Foundation

public struct TRPLanguagesInfoModel: Decodable {
    public let translations: [String: Any]
    
    private enum CodingKeys: String, CodingKey {
        case translations
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.translations = try container.decode([String: Any].self, forKey: .translations)
    }
}
