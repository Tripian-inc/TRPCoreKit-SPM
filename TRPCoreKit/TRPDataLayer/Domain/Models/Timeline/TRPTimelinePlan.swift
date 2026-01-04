//
//  TRPTimelinePlan.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 14.08.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import Foundation
public struct TRPTimelinePlan: Codable {
    
    /// An Int value. Id of plan
    public var id: String
    
    /// A String value. Start time of plan
    public var startDate: String
    /// A String value. End time of plan
    public var endDate: String
    /// A TRPPlanPoi array. Indicates a pois to go within a day.
    public var steps: [TRPTimelineStep]
    
    public var available: Bool?
    public var tripType: Int?
    public var name: String?
    public var description: String?
    public var generatedStatus: Int
    public var children: Int?
    public var pets: Int?
    public var adults: Int?
    public var city: TRPCity?
    
    public var accommodation: TRPAccommodation?
    public var destinationAccommodation: TRPAccommodation?
    
    func getPoi() -> [TRPPoi] {
        return steps.compactMap({$0.poi})
    }
    
    public func getStartDate() -> Date? {
        return Date.fromString(startDate, format: "yyyy-MM-dd HH:mm")
    }
    
    public func getEndDate() -> Date? {
        return Date.fromString(endDate, format: "yyyy-MM-dd HH:mm")
    }
}

extension TRPTimelinePlan: Equatable {

    public static func == (lhs: TRPTimelinePlan, rhs: TRPTimelinePlan) -> Bool {
        lhs.id == rhs.id
    }

}
