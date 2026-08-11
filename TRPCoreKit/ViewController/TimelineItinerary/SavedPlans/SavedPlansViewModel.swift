//
//  SavedPlansViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 29.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

public protocol SavedPlansViewModelDelegate: ViewModelDelegate {
    func savedPlansDidLoad()
}

/// Represents a section in the saved plans table view (grouped by city/location)
public struct SavedPlansSection {
    public let cityName: String
    public var items: [TRPSegmentFavoriteItem]
}

public class SavedPlansViewModel {

    // MARK: - Properties
    public weak var delegate: SavedPlansViewModelDelegate?

    private let favouriteItems: [TRPSegmentFavoriteItem]
    private var sections: [SavedPlansSection] = []

    public let tripHash: String?
    public let availableDays: [Date]
    public let availableCities: [TRPCity]

    // MARK: - Initialization
    public init(favouriteItems: [TRPSegmentFavoriteItem],
                tripHash: String?,
                availableDays: [Date],
                availableCities: [TRPCity]) {
        self.favouriteItems = favouriteItems
        self.tripHash = tripHash
        self.availableDays = availableDays
        self.availableCities = availableCities

        groupItemsByCity()
    }

    // MARK: - Public Methods

    public func numberOfSections() -> Int {
        return sections.count
    }

    public func numberOfItems(in section: Int) -> Int {
        guard section < sections.count else { return 0 }
        return sections[section].items.count
    }

    public func getSection(at index: Int) -> SavedPlansSection? {
        guard index < sections.count else { return nil }
        return sections[index]
    }

    public func getItem(at indexPath: IndexPath) -> TRPSegmentFavoriteItem? {
        guard indexPath.section < sections.count,
              indexPath.row < sections[indexPath.section].items.count else { return nil }
        return sections[indexPath.section].items[indexPath.row]
    }

    public func getTotalItemCount() -> Int {
        return sections.reduce(0) { $0 + $1.items.count }
    }

    /// `productId` may be raw, provider-prefixed or city-suffixed form; all reduce to the same core id for matching.
    @discardableResult
    public func removeItem(matchingProductId productId: String) -> Bool {
        let target = productId.cleanedAsActivityId()
        var didRemove = false

        for sectionIndex in sections.indices {
            sections[sectionIndex].items.removeAll { item in
                guard let activityId = item.activityId else { return false }
                if activityId.cleanedAsActivityId() == target {
                    didRemove = true
                    return true
                }
                return false
            }
        }
        // Drop sections that just emptied out so the list collapses naturally.
        sections.removeAll { $0.items.isEmpty }

        if didRemove {
            delegate?.savedPlansDidLoad()
        }
        return didRemove
    }

    public func convertToTourProduct(from item: TRPSegmentFavoriteItem) -> TRPTourProduct? {
        guard let activityId = item.activityId else { return nil }

        let formattedActivityId = TRPActivityIdFormat.normalized(activityId)

        let location: TRPLocation? = item.coordinate

        let cityId = item.cityId ?? availableCities.first?.id ?? 0

        var image: TRPImage?
        if let photoUrl = item.photoUrl {
            image = TRPImage(url: photoUrl, imageOwner: nil, width: nil, height: nil)
        }

        // Favourite prices are minor units (cents); TRPTourProduct.price is major units, so divide.
        let majorUnitPrice = item.price.map { $0.value / 100.0 }

        return TRPTourProduct(
            id: formattedActivityId,
            productId: formattedActivityId,
            cityId: cityId,
            name: item.title,
            image: image,
            gallery: nil,
            duration: nil,
            price: majorUnitPrice,
            currency: item.price?.currency,
            rating: item.rating,
            ratingCount: item.ratingCount,
            description: item.description,
            webUrl: item.activityUrl,
            phone: nil,
            hours: nil,
            address: nil,
            icon: "ic_activity",
            coordinate: location,
            categories: [],
            tags: [],
            distance: nil,
            status: true,
            offers: [],
            additionalData: nil
        )
    }

    public func createAddPlanData(cityId: Int) -> AddPlanData {
        var planData = AddPlanData()
        planData.tripHash = tripHash
        planData.availableDays = availableDays
        planData.selectedCity = availableCities.first(where: { $0.id == cityId }) ?? availableCities.first
        planData.selectedDay = availableDays.first
        planData.travelers = 1
        return planData
    }

    public func createAddPlanData() -> AddPlanData {
        return createAddPlanData(cityId: availableCities.first?.id ?? 0)
    }

    // MARK: - Private Methods

    /// Group by cached `TRPCity` name (via `cityId`) so varying backend `cityName` spellings still merge; falls back to `item.cityName`.
    private func groupItemsByCity() {
        var cityGroups: [String: [TRPSegmentFavoriteItem]] = [:]
        var cityOrder: [String] = []

        for item in favouriteItems {
            let resolvedCityName: String
            if let cityId = item.cityId,
               let cachedCity = availableCities.first(where: { $0.id == cityId }) {
                resolvedCityName = cachedCity.name
            } else {
                resolvedCityName = item.cityName
            }

            if cityGroups[resolvedCityName] == nil {
                cityGroups[resolvedCityName] = []
                cityOrder.append(resolvedCityName)
            }
            cityGroups[resolvedCityName]?.append(item)
        }

        sections = cityOrder.compactMap { cityName in
            guard let items = cityGroups[cityName] else { return nil }
            return SavedPlansSection(cityName: cityName, items: items)
        }
    }
}
