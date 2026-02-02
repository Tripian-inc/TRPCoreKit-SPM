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

    // Data needed for time selection flow
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

    /// Get total number of sections (cities)
    public func numberOfSections() -> Int {
        return sections.count
    }

    /// Get number of items in a section
    public func numberOfItems(in section: Int) -> Int {
        guard section < sections.count else { return 0 }
        return sections[section].items.count
    }

    /// Get section data for header
    public func getSection(at index: Int) -> SavedPlansSection? {
        guard index < sections.count else { return nil }
        return sections[index]
    }

    /// Get favourite item at index path
    public func getItem(at indexPath: IndexPath) -> TRPSegmentFavoriteItem? {
        guard indexPath.section < sections.count,
              indexPath.row < sections[indexPath.section].items.count else { return nil }
        return sections[indexPath.section].items[indexPath.row]
    }

    /// Get total count of all items
    public func getTotalItemCount() -> Int {
        return favouriteItems.count
    }

    /// Convert TRPSegmentFavoriteItem to TRPTourProduct for time selection flow
    public func convertToTourProduct(from item: TRPSegmentFavoriteItem) -> TRPTourProduct? {
        guard let activityId = item.activityId else { return nil }

        // Format activity ID as C_{id}_15, unless it already starts with C_
        let formattedActivityId = activityId.hasPrefix("C_") ? activityId : "C_\(activityId)_15"

        let location: TRPLocation? = item.coordinate

        // Get city ID from item's own cityId, fallback to first available city or 0
        let cityId = item.cityId ?? availableCities.first?.id ?? 0

        // Create image if photoUrl available
        var image: TRPImage?
        if let photoUrl = item.photoUrl {
            image = TRPImage(url: photoUrl, imageOwner: nil, width: nil, height: nil)
        }

        // Convert price to Int
        var priceInt: Int?
        if let priceValue = item.price?.value {
            priceInt = Int(priceValue)
        }

        return TRPTourProduct(
            id: formattedActivityId,
            productId: formattedActivityId,
            cityId: cityId,
            name: item.title,
            image: image,
            gallery: nil,
            duration: nil, // Not available in TRPSegmentFavoriteItem
            price: priceInt,
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

    /// Create AddPlanData for time selection flow with specific city ID
    public func createAddPlanData(cityId: Int) -> AddPlanData {
        var planData = AddPlanData()
        planData.tripHash = tripHash
        planData.availableDays = availableDays
        // Find the city matching the given cityId, fallback to first available city
        planData.selectedCity = availableCities.first(where: { $0.id == cityId }) ?? availableCities.first
        planData.selectedDay = availableDays.first
        planData.travelers = 1 // Default
        return planData
    }

    /// Create AddPlanData for time selection flow (uses first available city)
    public func createAddPlanData() -> AddPlanData {
        return createAddPlanData(cityId: availableCities.first?.id ?? 0)
    }

    // MARK: - Private Methods

    /// Group favourite items by their city name
    private func groupItemsByCity() {
        // Create a dictionary to group items by city name
        var cityGroups: [String: [TRPSegmentFavoriteItem]] = [:]
        var cityOrder: [String] = [] // Maintain insertion order

        for item in favouriteItems {
            // Use cityName field for grouping
            let cityName = item.cityName

            if cityGroups[cityName] == nil {
                cityGroups[cityName] = []
                cityOrder.append(cityName)
            }
            cityGroups[cityName]?.append(item)
        }

        // Convert to sections maintaining order
        sections = cityOrder.compactMap { cityName in
            guard let items = cityGroups[cityName] else { return nil }
            return SavedPlansSection(cityName: cityName, items: items)
        }
    }
}
