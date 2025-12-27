//
//  TRPTourProduct.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 26.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit
import TRPRestKit

public struct TRPTourProduct: Codable {

    public let id: String
    public let cityId: Int
    public let name: String
    public let image: TRPImage?
    public var gallery: [TRPImage?]? = []
    public var duration: Int?
    public var price: Int?
    public var rating: Float?
    public var ratingCount: Int?
    public var description: String?

    public var webUrl: String?
    public var phone: String?
    public var hours: String?
    public var address: String?
    public let icon: String

    public let coordinate: TRPLocation
    public var categories = [TRPPoiCategory]()
    public var tags = [String]()
    public var distance: Float?

    public let status: Bool

    public var offers: [TRPOffer] = []
    public var additionalData: TRPAdditionalData?
}

extension TRPTourProduct: Equatable {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }

}

extension TRPTourProduct: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

}

extension TRPTourProduct {
    public func isRatingAvailable() -> Bool {
        return rating != nil && ratingCount ?? -1 > 0
    }

    public func getCategoryName() -> String {
        guard let category = categories.first else { return "" }
        return category.name ?? ""
    }
}

extension [TRPTourProduct] {
    public func getToursWithCategories(_ categoryIds: [String]) -> [TRPTourProduct] {
        guard !categoryIds.isEmpty else { return self }

        var tours = [TRPTourProduct]()
        self.forEach { tour in
            let isExist = tour.categories.contains { tourCategory -> Bool in
                return categoryIds.contains { categoryId -> Bool in
                    return String(tourCategory.id) == categoryId
                }
            }

            if isExist {
                tours.append(tour)
            }
        }
        return tours.unique()
    }
}
