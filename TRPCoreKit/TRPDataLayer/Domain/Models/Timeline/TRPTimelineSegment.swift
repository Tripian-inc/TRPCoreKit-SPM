//
//  TRPTimelineSegmentProfile.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 14.08.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import TRPFoundationKit

public enum TRPTimelineSegmentType: String, Codable {
    case bookedActivity = "booked_activity"
    case reservedActivity = "reserved_activity"
    case itinerary = "itinerary"
    case manualPoi = "manual_poi"
}

public class TRPTimelineSegment: Codable {
    public var available: Bool = true
    public var title: String?
    public var description: String?
    public var startDate: String?
    public var endDate: String?
    public var coordinate: TRPLocation?
    public var destinationCoordinate: TRPLocation?
    public var adults: Int = 1
    public var children: Int = 0
    public var pets: Int = 0
    public var generatedStatus: Int?
    public var answerIds: [Int]?
    public var doNotRecommend: [String]?
    public var excludePoiIds: [String]?
    public var includePoiIds: [String]?
    public var dayIds: [Int]?
    public var considerWeather: Bool?
    public var distinctPlan: Bool = true
    public var segmentType: TRPTimelineSegmentType = .itinerary
    
    public var city: TRPCity?
    public var differentEndLocation: Bool = false
    public var differentMealSuggestions: Bool = false
    public var customSettings: Bool = false
    public var accommodation: TRPAccommodation?
    public var destinationAccommodation: TRPAccommodation?

    // Smart Recommendations properties
    public var activityFreeText: String?
    public var activityIds: [String]?
    public var smartRecommendation: Bool?
    public var excludedActivityIds: [String]?
    public var doNotGenerate: Int = 0

    // Manual POI properties
    public var poiId: String?

    public var additionalData: TRPSegmentActivityItem?
    
    public init() {
        
    }
    
    public convenience init(from base: TRPTimelinePlan) {
        self.init()
        
        self.available       = base.available ?? false
        self.title           = base.name
        self.description     = base.description
        self.startDate       = base.startDate
        self.endDate         = base.endDate
        self.adults          = base.adults ?? 1
        self.children        = base.children ?? 0
        self.pets            = base.pets ?? 0
        self.city            = base.city
        self.generatedStatus = base.generatedStatus
    }
    
}


public class TRPCreateEditTimelineSegmentProfile: TRPTimelineSegment {
    
    public var tripHash: String = ""
    public var segmentIndex: Int?
    
    public init(tripHash: String) {
        super.init()
        self.tripHash = tripHash
    }
    
    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

extension TRPCreateEditTimelineSegmentProfile {
    public convenience init(from base: TRPTimelineSegment, tripHash: String, segmentIndex: Int? = nil) {
        self.init(tripHash: tripHash)
        
        self.segmentIndex          = segmentIndex
        self.available             = base.available
        self.title                 = base.title
        self.description           = base.description
        self.startDate             = base.startDate
        self.endDate               = base.endDate
        self.coordinate            = base.coordinate
        self.destinationCoordinate = base.destinationCoordinate
        self.adults                = base.adults
        self.children              = base.children
        self.pets                  = base.pets
        self.city                  = base.city
        self.generatedStatus       = base.generatedStatus
        self.answerIds             = base.answerIds
        self.doNotRecommend        = base.doNotRecommend
        self.excludePoiIds         = base.excludePoiIds
        self.includePoiIds         = base.includePoiIds
        self.dayIds                = base.dayIds
        self.considerWeather       = base.considerWeather
        self.distinctPlan          = base.distinctPlan
        
        self.differentEndLocation  = base.differentEndLocation
        self.differentMealSuggestions = base.differentMealSuggestions
        self.customSettings        = base.customSettings
        self.accommodation        = base.accommodation
        self.destinationAccommodation        = base.destinationAccommodation

        // Smart Recommendations properties
        self.activityFreeText      = base.activityFreeText
        self.activityIds           = base.activityIds
        self.smartRecommendation   = base.smartRecommendation
        self.excludedActivityIds   = base.excludedActivityIds
        self.doNotGenerate         = base.doNotGenerate

        // Manual POI properties
        self.poiId                 = base.poiId
    }
}
