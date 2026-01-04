//
//  TRPTimelineSegmentProfile.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 08.08.2025.
//  Copyright © 2025 Cem Çaygöz. All rights reserved.
//

import Foundation
import TRPFoundationKit

public class TRPTimelineProfile: Codable {

    public var cityId: Int?
    public var hash: String?
    
    public var adults: Int = 1
    public var children: Int = 0
    public var pets: Int = 0
    public var answerIds: [Int]?
    public var doNotRecommend: [String]?
    public var excludePoiIds: [String]?
    public var excludeHashPois: [String]?
    public var considerWeather: Bool = false
    public var segments: [TRPTimelineSegment] = []

    public var userAnswerIds: [Int]?

    public var accommodation: TRPAccommodation?
    public var destinationAccommodation: TRPAccommodation?

    /// Favourite items - used only in CoreKit for itinerary planning, not sent to server
    public var favouriteItems: [TRPSegmentFavoriteItem]?
    
    private(set) var oldestStartDate: Date?
    private(set) var maxEndDate: Date?
    
    /// Create a Trip
    /// - Parameter cityId: CityId
    public init(cityId: Int?) {
        self.cityId = cityId
    }
    
    public init() {
        
    }
    
    public func getTotalPeopleCount() -> Int {
        let count = adults + children
        return count
    }
    
    public func getOldestStartDate() -> Date {
        if oldestStartDate != nil {
            return oldestStartDate!
        }
        let dates = segments.compactMap({ Date.fromString($0.startDate, format: "yyyy-MM-dd HH:mm")})
        oldestStartDate = dates.min()
        return oldestStartDate ?? Date()
    }
    
    public func getMaxEndDate() -> Date {
        if maxEndDate != nil {
            return maxEndDate!
        }
        let dates = segments.compactMap({ Date.fromString($0.endDate, format: "yyyy-MM-dd HH:mm") })
        maxEndDate = dates.max()
        return maxEndDate ?? Date()
    }
    
    public func getDateRangeText() -> String? {
        return "\(getOldestStartDate().toString(format: "MMMM dd")) - \(getMaxEndDate().toString(format: "MMMM dd, yyyy"))"
    }
    
    public func getFirstSegmentTitle() -> String? {
        guard !segments.isEmpty else {
            return nil
        }
        return segments.first?.title
    }
}


public class TRPCreateEditTimelineProfile: TRPTimelineProfile {
    
    public var tripHash: String = ""
    public var segmentIndex: Int?
//    public var doNotGenerate: Int?
    
    public init(cityId: Int, tripHash: String) {
        self.tripHash = tripHash
        super.init(cityId: cityId)
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
