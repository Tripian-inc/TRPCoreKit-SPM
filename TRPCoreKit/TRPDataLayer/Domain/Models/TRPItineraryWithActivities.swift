//
//  TRPItineraryExport.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on [Date].
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

public struct TRPItineraryWithActivities: Codable {
    
    public var tripName: String?
    public var startDatetime: String
    public var endDatetime: String
    public var uniqueId: String
    public var tripianHash: String?
    public var destinationItems: [TRPSegmentDestinationItem]
    public var favouriteItems: [TRPSegmentFavoriteItem]
    public var tripItems: [TRPSegmentActivityItem]
    
    enum CodingKeys: String, CodingKey {
        case tripName
        case startDatetime
        case endDatetime
        case uniqueId
        case tripianHash
        case destinationItems
        case favouriteItems
        case tripItems
    }
    
}

public struct TRPSegmentDestinationItem: Codable {
    
    public var title: String
    public var coordinate: String
    
}

public struct TRPSegmentFavoriteItem: Codable {
    
    public var activityId: String?
    public var title: String
    public var photoUrl: String?
    public var description: String?
    public var activityUrl: String?
    public var coordinate: String
    public var rating: Float?
    public var ratingCount: Int?
    public var cancellation: String?
    public var price: TRPSegmentActivityPrice?
    public var locations: [String]?
    
    enum CodingKeys: String, CodingKey {
        case activityId
        case title
        case photoUrl
        case description
        case activityUrl
        case coordinate
        case rating
        case ratingCount
        case cancellation
        case price
        case locations
    }
    
}

public struct TRPSegmentActivityItem: Codable {
    
    public var activityId: String?
    public var bookingId: String?
    public var title: String?
    public var imageUrl: String?
    public var description: String?
    public var startDatetime: String?
    public var endDatetime: String?
    public var coordinate: TRPLocation
    public var cancellation: String?
    
    enum CodingKeys: String, CodingKey {
        case activityId
        case bookingId
        case title
        case imageUrl
        case description
        case startDatetime
        case endDatetime
        case coordinate
        case cancellation
    }
    
}

public struct TRPSegmentActivityPrice: Codable {
    
    public var currency: String
    public var value: Float
    
}

// MARK: - Timeline Profile Conversion
extension TRPItineraryWithActivities {
    
    /// Creates a TRPTimelineProfile from booking products (tripItems) in the itinerary export
    /// This method creates timeline segments ONLY from booking products - no gaps or available segments are generated
    /// - Parameters:
    ///   - cityId: Optional city ID (can be nil if using destinationItems)
    ///   - adults: Number of adults (default: 1)
    ///   - children: Number of children (default: 0)
    ///   - pets: Number of pets (default: 0)
    ///   - destinationCityIds: Optional dictionary mapping destination titles to city IDs
    /// - Returns: TRPTimelineProfile ready to be used with Timeline API's createTimeline method
    public func createTimelineProfileFromBookings(
        cityId: Int? = nil,
        adults: Int = 1,
        children: Int = 0,
        pets: Int = 0,
        destinationCityIds: [String: Int]? = nil
    ) -> TRPTimelineProfile {
        let timelineProfile = TRPTimelineProfile(cityId: cityId)
        timelineProfile.adults = adults
        timelineProfile.children = children
        timelineProfile.pets = pets
        
        // Create segments only from tripItems (booking products)
        let segments = tripItems.map { tripItem in
            createTimelineSegment(from: tripItem, cityId: getCityIdForItem(tripItem: tripItem, destinationCityIds: destinationCityIds, defaultCityId: cityId), adults: adults, children: children, pets: pets)
        }
        
        timelineProfile.segments = segments
        
        return timelineProfile
    }
    
    /// Creates a TRPTimelineSegment from a TRPSegmentActivityItem
    private func createTimelineSegment(from tripItem: TRPSegmentActivityItem, cityId: Int?, adults: Int, children: Int, pets: Int) -> TRPTimelineSegment {
        let segment = TRPTimelineSegment()
        
        segment.title = tripItem.title
        segment.description = tripItem.description
        segment.available = false // Booking products are fixed activities
        segment.distinctPlan = true
        
        // Use item-specific dates if available, otherwise use base parameters
        segment.startDate = tripItem.startDatetime ?? startDatetime
        segment.endDate = tripItem.endDatetime ?? endDatetime
        
        segment.coordinate = tripItem.coordinate
        
        segment.adults = adults
        segment.children = children
        segment.pets = pets
        
        // Set city if cityId is provided
        if let cityId = cityId {
            // Note: You may need to set the city object if you have it available
            // segment.city = TRPCity(id: cityId, ...)
        }
        
        return segment
    }
    
    // MARK: - Private Helpers
    
    /// Gets city ID for a trip item based on destination mapping or default
    private func getCityIdForItem(
        tripItem: TRPSegmentActivityItem,
        destinationCityIds: [String: Int]?,
        defaultCityId: Int?
    ) -> Int? {
        // If destination mapping is provided, try to match by title
        if let destinationCityIds = destinationCityIds,
           let title = tripItem.title {
            // Try to find matching destination
            for (destinationTitle, cityId) in destinationCityIds {
                if title.localizedCaseInsensitiveContains(destinationTitle) {
                    return cityId
                }
            }
        }
        
        // Try to match with destinationItems
        if let destinationCityIds = destinationCityIds {
            for destinationItem in destinationItems {
                if let cityId = destinationCityIds[destinationItem.title] {
                    return cityId
                }
            }
        }
        
        return defaultCityId
    }
    
}


