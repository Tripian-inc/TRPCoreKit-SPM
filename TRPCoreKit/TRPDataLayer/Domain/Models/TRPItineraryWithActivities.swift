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
    public var cityId: Int?
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
                cityId: Int? = nil,
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
        self.cityId = cityId
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
        case cityId
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
    public var duration: Double?
    public var price: TRPSegmentActivityPrice?
    public var cityId: Int?

    public init(activityId: String?, bookingId: String?, title: String?, imageUrl: String?, description: String?, startDatetime: String?, endDatetime: String?, coordinate: TRPLocation, cancellation: String?, adultCount: Int, childCount: Int, bookingUrl: String? = nil, duration: Double? = nil, price: TRPSegmentActivityPrice? = nil, cityId: Int? = nil) {
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
        self.duration = duration
        self.price = price
        self.cityId = cityId
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
        case duration
        case price
        case cityId
    }

}

public struct TRPSegmentActivityPrice: Codable {

    public var currency: String
    public var value: Double

    public init(currency: String, value: Double) {
        self.currency = currency
        self.value = value
    }

}

// MARK: - Timeline Profile Conversion
extension TRPItineraryWithActivities {

    /// Creates a TRPTimelineProfile from booking products (tripItems) in the itinerary export
    /// This method creates timeline segments from booking products and adds empty segments for start/end dates if needed
    /// - Returns: TRPTimelineProfile ready to be used with Timeline API's createTimeline method
    public func createTimelineProfileFromBookings() -> TRPTimelineProfile {
        let timelineProfile = TRPTimelineProfile()

        // Set traveler counts from first trip item (or default to 1 adult)
        let adults: Int
        let children: Int
        if let firstItem = tripItems?.first {
            adults = firstItem.adultCount
            children = firstItem.childCount
        } else {
            adults = 1
            children = 0
        }

        timelineProfile.adults = adults
        timelineProfile.children = children
        timelineProfile.pets = 0

        // Set cityId from first destinationItem (for timeline creation)
        if let firstCityId = destinationItems.first?.cityId {
            timelineProfile.cityId = firstCityId
        }

        // Create segments from tripItems (booking products)
        // Note: City information will come from timeline API response (plans), not from destinationItems
        var segments = tripItems?.map { tripItem in
            createTimelineSegment(from: tripItem)
        } ?? []

        // Extract start and end dates from itinerary
        guard let startDateStr = extractDateString(from: startDatetime),
              let endDateStr = extractDateString(from: endDatetime) else {
            timelineProfile.segments = segments
            return timelineProfile
        }

        // Get city from first destinationItem (if no tripItems, use this for empty segments)
        let city = createCityFromDestination()

        // Check if there's a tripItem on the start date
        let hasItemOnStartDate = tripItems?.contains { item in
            guard let itemDate = item.startDatetime else { return false }
            return extractDateString(from: itemDate) == startDateStr
        } ?? false

        // Check if there's a tripItem on the end date
        let hasItemOnEndDate = tripItems?.contains { item in
            guard let itemDate = item.startDatetime else { return false }
            return extractDateString(from: itemDate) == endDateStr
        } ?? false

        // Add empty segment for start date if needed
        if !hasItemOnStartDate {
            let emptyStartSegment = createEmptySegment(
                date: startDateStr,
                title: "Empty",
                adults: adults,
                children: children,
                city: city
            )
            segments.insert(emptyStartSegment, at: 0)
        }

        // Add empty segment for end date if needed (and different from start)
        if !hasItemOnEndDate && startDateStr != endDateStr {
            let emptyEndSegment = createEmptySegment(
                date: endDateStr,
                title: "Empty",
                adults: adults,
                children: children,
                city: city
            )
            segments.append(emptyEndSegment)
        }

        timelineProfile.segments = segments

        return timelineProfile
    }

    // MARK: - Private Helpers

    /// Extracts the date portion from a datetime string
    /// - Parameter datetime: String in format "yyyy-MM-dd HH:mm" or "yyyy-MM-dd"
    /// - Returns: Date string in format "yyyy-MM-dd" or nil if extraction fails
    private func extractDateString(from datetime: String) -> String? {
        let components = datetime.components(separatedBy: " ")
        return components.first
    }

    /// Creates an empty segment for a given date
    /// Used to ensure timeline covers the full trip date range even when there are no tripItems on certain days
    private func createEmptySegment(date: String, title: String, adults: Int, children: Int, city: TRPCity?) -> TRPTimelineSegment {
        let segment = TRPTimelineSegment()
        segment.segmentType = .itinerary
        segment.title = title
        segment.available = false
        segment.distinctPlan = true
        segment.startDate = "\(date) 00:00"
        segment.endDate = "\(date) 23:59"
        segment.adults = adults
        segment.children = children
        segment.pets = 0
        segment.city = city
        segment.doNotGenerate = 1
        return segment
    }

    /// Creates a TRPCity from the first destinationItem if cityId is available
    /// Used to populate city info in empty segments when no tripItems exist
    private func createCityFromDestination() -> TRPCity? {
        guard let destination = destinationItems.first,
              let cityId = destination.cityId else {
            return nil
        }

        // Parse coordinate from string (format: "lat,lon")
        let coordinate = parseCoordinate(from: destination.coordinate)

        return TRPCity(
            id: cityId,
            name: destination.title,
            coordinate: coordinate
        )
    }

    /// Parses a coordinate string into TRPLocation
    /// - Parameter coordinateString: String in format "lat,lon" (e.g., "41.3851,2.1734")
    /// - Returns: TRPLocation with parsed coordinates, or default (0,0) if parsing fails
    private func parseCoordinate(from coordinateString: String) -> TRPLocation {
        let parts = coordinateString.components(separatedBy: ",")
        guard parts.count >= 2,
              let lat = Double(parts[0].trimmingCharacters(in: .whitespaces)),
              let lon = Double(parts[1].trimmingCharacters(in: .whitespaces)) else {
            return TRPLocation(lat: 0, lon: 0)
        }
        return TRPLocation(lat: lat, lon: lon)
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
        segment.doNotGenerate = 1

        // Set additional data (this is CRITICAL for booked activities)
        segment.additionalData = tripItem

        // City will be populated from timeline.plans using index-based mapping
        // tripProfile.segments[i] corresponds to plans[i]
        segment.city = nil

        return segment
    }
}


