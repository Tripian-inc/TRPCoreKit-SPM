//
//  TRPTimelineSegmentAdditionalData.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 30.11.2025.
//

import TRPFoundationKit

public struct TRPTimelineSegmentAdditionalData: Codable {
    
    public var activityId: String?
    public var bookingId: String?
    public var title: String?
    public var imageUrl: String?
    public var description: String?
    public var startDatetime: String?
    public var endDatetime: String?
    public var coordinate: TRPLocation?
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
    
    public init(activityId: String? = nil,
                bookingId: String? = nil,
                title: String? = nil,
                imageUrl: String? = nil,
                description: String? = nil,
                startDatetime: String? = nil,
                endDatetime: String? = nil,
                coordinate: TRPLocation? = nil,
                cancellation: String? = nil) {
        self.activityId = activityId
        self.bookingId = bookingId
        self.title = title
        self.imageUrl = imageUrl
        self.description = description
        self.startDatetime = startDatetime
        self.endDatetime = endDatetime
        self.coordinate = coordinate
        self.cancellation = cancellation
    }
    
}
