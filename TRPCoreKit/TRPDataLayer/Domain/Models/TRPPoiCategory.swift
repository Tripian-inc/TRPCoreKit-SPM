//
//  TRPPoiCategoy.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 26.02.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import Foundation

public struct TRPPoiCategory: Codable {
    public let id: Int
    public let name: String?
    public let isCustom: Bool?
}

public struct TRPPoiCategoyGroup {
    public let name: String?
    public let categories: [TRPPoiCategory]?
}

extension [TRPPoiCategory] {
    public func getIds() -> [Int] {
        return self.map(\.id)
    }
}
