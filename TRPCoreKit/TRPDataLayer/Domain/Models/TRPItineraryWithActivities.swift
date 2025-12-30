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
    public var favouriteItems: [TRPSegmentFavoriteItem]?
    public var tripItems: [TRPSegmentActivityItem]?

    public init(tripName: String?, startDatetime: String, endDatetime: String, uniqueId: String, tripianHash: String?, destinationItems: [TRPSegmentDestinationItem], favouriteItems: [TRPSegmentFavoriteItem]?, tripItems: [TRPSegmentActivityItem]?) {
        self.tripName = tripName
        self.startDatetime = startDatetime
        self.endDatetime = endDatetime
        self.uniqueId = uniqueId
        self.tripianHash = tripianHash
        self.destinationItems = destinationItems
        self.favouriteItems = favouriteItems
        self.tripItems = tripItems
    }

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
    public var cityId: Int?

    public init(title: String, coordinate: String, cityId: Int? = nil) {
        self.title = title
        self.coordinate = coordinate
        self.cityId = cityId
    }

}

public struct TRPSegmentFavoriteItem: Codable {

    public var activityId: String?
    public var title: String
    public var cityName: String
    public var photoUrl: String?
    public var description: String?
    public var activityUrl: String?
    public var coordinate: TRPLocation
    public var rating: Float?
    public var ratingCount: Int?
    public var cancellation: String?
    public var duration: Double?
    public var price: TRPSegmentActivityPrice?
    public var locations: [String]?

    public init(activityId: String?,
                title: String,
                cityName: String,
                photoUrl: String?,
                description: String?,
                activityUrl: String?,
                coordinate: TRPLocation,
                rating: Float?,
                ratingCount: Int?,
                cancellation: String?,
                duration: Double?,
                price: TRPSegmentActivityPrice?,
                locations: [String]?) {
        self.activityId = activityId
        self.title = title
        self.cityName = cityName
        self.photoUrl = photoUrl
        self.description = description
        self.activityUrl = activityUrl
        self.coordinate = coordinate
        self.rating = rating
        self.ratingCount = ratingCount
        self.cancellation = cancellation
        self.price = price
        self.locations = locations
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey {
        case activityId
        case title
        case cityName
        case photoUrl
        case description
        case activityUrl
        case coordinate
        case rating
        case ratingCount
        case cancellation
        case price
        case locations
        case duration
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
    public var adultCount: Int = 1
    public var childCount: Int = 0
    public var bookingUrl: String?

    public init(activityId: String?, bookingId: String?, title: String?, imageUrl: String?, description: String?, startDatetime: String?, endDatetime: String?, coordinate: TRPLocation, cancellation: String?, adultCount: Int, childCount: Int, bookingUrl: String? = nil) {
        self.activityId = activityId
        self.bookingId = bookingId
        self.title = title
        self.imageUrl = imageUrl
        self.description = description
        self.startDatetime = startDatetime
        self.endDatetime = endDatetime
        self.coordinate = coordinate
        self.cancellation = cancellation
        self.adultCount = adultCount
        self.childCount = childCount
        self.bookingUrl = bookingUrl
    }

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
        case adultCount
        case childCount
        case bookingUrl
    }

}

public struct TRPSegmentActivityPrice: Codable {

    public var currency: String
    public var value: Float

    public init(currency: String, value: Float) {
        self.currency = currency
        self.value = value
    }

}

// MARK: - Timeline Profile Conversion
extension TRPItineraryWithActivities {
    
    /// Creates a TRPTimelineProfile from booking products (tripItems) in the itinerary export
    /// This method creates timeline segments ONLY from booking products - no gaps or available segments are generated
    /// - Returns: TRPTimelineProfile ready to be used with Timeline API's createTimeline method
    public func createTimelineProfileFromBookings() -> TRPTimelineProfile {
        let timelineProfile = TRPTimelineProfile()

        // Set traveler counts from first trip item (or default to 1 adult)
        if let firstItem = tripItems?.first {
            timelineProfile.adults = firstItem.adultCount
            timelineProfile.children = firstItem.childCount
            timelineProfile.pets = 0
        } else {
            timelineProfile.adults = 1
            timelineProfile.children = 0
            timelineProfile.pets = 0
        }

        // Create segments only from tripItems (booking products)
        // Note: City information will come from timeline API response (plans), not from destinationItems
        let segments = tripItems?.map { tripItem in
            createTimelineSegment(from: tripItem)
        }

        timelineProfile.segments = segments ?? []

        return timelineProfile
    }

    /// Creates a TRPTimelineSegment from a TRPSegmentActivityItem
    private func createTimelineSegment(from tripItem: TRPSegmentActivityItem) -> TRPTimelineSegment {
        let segment = TRPTimelineSegment()

        // Set segment type
        segment.segmentType = .bookedActivity

        // Set basic properties
        segment.title = tripItem.title
        segment.description = tripItem.description
        segment.available = false // Booking products are fixed activities
        segment.distinctPlan = true

        // Use item-specific dates if available, otherwise use base parameters
        segment.startDate = tripItem.startDatetime ?? startDatetime
        segment.endDate = tripItem.endDatetime ?? endDatetime

        segment.coordinate = tripItem.coordinate

        // Set traveler counts
        segment.adults = tripItem.adultCount
        segment.children = tripItem.childCount
        segment.pets = 0

        // Set additional data (this is CRITICAL for booked activities)
        segment.additionalData = tripItem

        // City will be populated from timeline.plans using index-based mapping
        // tripProfile.segments[i] corresponds to plans[i]
        segment.city = nil

        return segment
    }
}


