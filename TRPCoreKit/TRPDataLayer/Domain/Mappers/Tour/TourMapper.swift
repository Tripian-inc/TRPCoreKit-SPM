//
//  TourMapper.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 26.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit
import TRPFoundationKit

final class TourMapper {

    func map(_ restModel: TRPTourProductInfoModel) -> TRPTourProduct? {

        // Map images: separate cover image from gallery
        var mainImage: TRPImage?
        var gallery: [TRPImage?] = []

        if let images = restModel.images {
            // Find cover image
            if let coverImageModel = images.first(where: { $0.isCover == true }) {
                mainImage = mapTourImage(coverImageModel)
            } else if let firstImage = images.first {
                // If no cover is specified, use first image
                mainImage = mapTourImage(firstImage)
            }

            // Map remaining images to gallery
            gallery = images.filter { $0.isCover != true || images.count == 1 }
                .map { mapTourImage($0) }
        }
        
        var coordinate: TRPLocation?

        // Get coordinate from first location
        if let firstLocation = restModel.locations?.first {
            // If no location, we can't create a tour product
            coordinate = TRPLocation(lat: firstLocation.lat ?? 0, lon: firstLocation.lon ?? 0)
        }

        // Convert duration from Double (minutes) to Int
        let duration = restModel.duration != nil ? Int(restModel.duration!) : nil

        // Convert price: prefer currentPrice over price, convert to Int
        let price: Int?
        if let currentPrice = restModel.currentPrice {
            price = Int(currentPrice)
        } else if let regularPrice = restModel.price {
            price = Int(regularPrice)
        } else {
            price = nil
        }

        // Convert rating from Double to Float
        let rating = restModel.rating != nil ? Float(restModel.rating!) : nil

        // Convert status from Int to Bool (1 = active/true)
        let status = restModel.status == 1

        // Map tags (use tag names)
        let tags = restModel.tags ?? []

        // Use default icon for tours
        let icon = "tour"

        let tour = TRPTourProduct(id: restModel.id,
                                  productId: restModel.productId,
                                  cityId: restModel.cityId,
                                  name: restModel.title,
                                  image: mainImage,
                                  gallery: gallery,
                                  duration: duration,
                                  price: price,
                                  rating: rating,
                                  ratingCount: restModel.ratingCount,
                                  description: restModel.description,
                                  webUrl: restModel.url,
                                  phone: nil,
                                  hours: nil,
                                  address: restModel.locationNames?.first,
                                  icon: icon,
                                  coordinate: coordinate,
                                  categories: [],
                                  tags: tags,
                                  distance: nil,
                                  status: status,
                                  offers: [],
                                  additionalData: nil)
        return tour
    }

    // Helper to map TRPTourImageModel to TRPImage
    private func mapTourImage(_ imageModel: TRPTourImageModel) -> TRPImage? {
        guard let url = imageModel.url else { return nil }
        return TRPImage(url: url, imageOwner: nil, width: nil, height: nil)
    }

    func map(_ restModels: [TRPTourProductInfoModel]) -> [TRPTourProduct] {
        restModels.compactMap{ map($0) }
    }

    // Map TRPTourSearchDataModel to extract products
    func mapDataModel(_ dataModel: TRPTourSearchDataModel) -> [TRPTourProduct] {
        guard let products = dataModel.products else { return [] }
        return map(products)
    }

    // Extract pagination from TRPTourSearchDataModel
    func mapPagination(_ dataModel: TRPTourSearchDataModel) -> TRPTourPagination? {
        guard let total = dataModel.total,
              let limit = dataModel.limit,
              let offset = dataModel.offset else {
            return nil
        }
        return TRPTourPagination(total: total, limit: limit, offset: offset)
    }
}
