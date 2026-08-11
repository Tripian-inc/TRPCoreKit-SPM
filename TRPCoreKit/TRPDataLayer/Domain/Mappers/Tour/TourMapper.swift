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

        // Prefer currentPrice over price; preserve decimal precision so the
        // UI can show the exact fractional value the API returned.
        let price: Double?
        if let currentPrice = restModel.currentPrice {
            price = Double(currentPrice)
        } else if let regularPrice = restModel.price {
            price = Double(regularPrice)
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

        // Map per-product slots from search response. `date` is required; `time` may be
        // nil to indicate a flexible (any-time) slot for that day — we keep those so
        // the time-selection screen can render a flexible-time card instead of a grid.
        let slots: [TRPTourSlot]? = restModel.slots?.compactMap { slotModel in
            guard let date = slotModel.date else { return nil }
            return TRPTourSlot(date: date, time: slotModel.time, price: slotModel.price)
        }

        let tour = TRPTourProduct(id: restModel.id,
                                  productId: restModel.productId,
                                  cityId: restModel.cityId,
                                  name: restModel.title,
                                  image: mainImage,
                                  gallery: gallery,
                                  duration: duration,
                                  price: price,
                                  currency: restModel.currency,
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
                                  additionalData: nil,
                                  slots: slots)
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

    // Map TRPTourSearchDataModel to a domain outcome (products + facets + pagination)
    func mapDataModel(_ dataModel: TRPTourSearchDataModel) -> TRPTourSearchOutcome {
        let products = map(dataModel.products ?? [])
        let facets = mapFacets(dataModel.facets)

        var pagination: TRPTourPagination?
        if let total = dataModel.total, let limit = dataModel.limit, let offset = dataModel.offset {
            pagination = TRPTourPagination(total: total, limit: limit, offset: offset)
        }

        return TRPTourSearchOutcome(products: products, facets: facets, pagination: pagination)
    }

    // Map first facet entry (single provider; providerId = 15) to domain TRPTourFacets
    func mapFacets(_ facetModels: [TRPTourFacetModel]?) -> TRPTourFacets? {
        guard let facet = facetModels?.first else { return nil }

        let categories: [TRPTourCategoryFacet] = (facet.categories ?? []).compactMap { model in
            guard let id = model.id, let label = model.label else { return nil }
            return TRPTourCategoryFacet(
                id: id,
                key: model.key,
                label: label,
                count: model.count ?? 0
            )
        }

        var priceRange: TRPTourPriceRangeFacet?
        if let minMoney = facet.priceRange?.minimum,
           let maxMoney = facet.priceRange?.maximum,
           let minAmount = minMoney.amount,
           let maxAmount = maxMoney.amount {
            priceRange = TRPTourPriceRangeFacet(
                minAmount: Double(minAmount) / 100.0,
                maxAmount: Double(maxAmount) / 100.0,
                currency: minMoney.currency ?? maxMoney.currency ?? ""
            )
        }

        var durationRange: TRPTourDurationRangeFacet?
        if let minMinutes = facet.durationRange?.minimumMinutes,
           let maxMinutes = facet.durationRange?.maximumMinutes {
            durationRange = TRPTourDurationRangeFacet(
                minMinutes: minMinutes,
                maxMinutes: maxMinutes
            )
        }

        return TRPTourFacets(
            categories: categories,
            priceRange: priceRange,
            durationRange: durationRange
        )
    }

    // Map TRPTourScheduleModel to TRPTourSchedule. `time` on individual slots may be
    // nil to indicate a flexible (any-time) slot — preserved so the booking flow can
    // render a flexible-time card instead of a time grid.
    //
    // The domain `TRPTourSchedule.dates` always carries per-day buckets — range
    // queries (`to` set) populate the SDK's `dates[]` directly; single-day responses
    // are synthesized into a 1-entry list from the top-level `date` + flat `slots`
    // so callers iterate the same shape regardless.
    func mapSchedule(_ scheduleModel: TRPTourScheduleModel) -> TRPTourSchedule {
        let title = scheduleModel.title

        // Range path: server populated `dates[]`.
        if let dateModels = scheduleModel.dates, !dateModels.isEmpty {
            let mappedDays: [TRPTourScheduleDay] = dateModels.compactMap { dayModel in
                guard let date = dayModel.date else { return nil }
                let slots = (dayModel.slots ?? []).map { slot in
                    TRPTourScheduleSlot(time: slot.time, price: slot.price)
                }
                return TRPTourScheduleDay(date: date, slots: slots)
            }
            return TRPTourSchedule(title: title, dates: mappedDays)
        }

        // Single-day fallback: synthesize one TRPTourScheduleDay from the response's
        // top-level `date` + flat `slots`.
        let slots = (scheduleModel.slots ?? []).map { slot in
            TRPTourScheduleSlot(time: slot.time, price: slot.price)
        }
        let day = TRPTourScheduleDay(date: scheduleModel.date, slots: slots)
        return TRPTourSchedule(title: title, dates: [day])
    }

    /// Map the batch `tour-api/schedule-availability` response. Missing or empty
    /// schedules are preserved as `TRPTourScheduleAvailability(schedule: nil)` so
    /// callers can distinguish "sold out / unavailable" from "not requested".
    func mapAvailability(_ dataModel: TRPTourScheduleAvailabilityDataModel) -> [TRPTourScheduleAvailability] {
        return (dataModel.schedules ?? []).map { itemModel in
            let schedule: TRPTourSchedule? = itemModel.schedule.map { mapSchedule($0) }
            return TRPTourScheduleAvailability(activityId: itemModel.id, schedule: schedule)
        }
    }
}
