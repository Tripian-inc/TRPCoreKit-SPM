//
//  TRPTimelineStep.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 14.08.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import Foundation

public struct TRPTimelineStep: Codable, Hashable {
    public var id: Int
    public var poi: TRPPoi?
    public var score: Double?
    public var planId: String?
    public var scoreDetails: [Double]?
    public var order: Int = 0
    public var startDateTimes: String?
    public var endDateTimes: String?
    public var stepType: String?
    public var attention: String?
    public var alternatives: [String]?
    public var warningMessage: [String]?
}

extension TRPTimelineStep: Equatable {
    
    public static func == (lhs: TRPTimelineStep, rhs: TRPTimelineStep) -> Bool {
        return lhs.id == rhs.id
    }
    
}

extension TRPTimelineStep {
    public func getStartTime() -> String? {
        guard let startDateTimes = Date.fromString(startDateTimes, format: "yyyy-MM-dd HH:mm:ss") else {
            return nil
        }
        return startDateTimes.toString(format: "HH:mm")
    }
    
    public func getEndTime() -> String? {
        guard let endDateTimes = Date.fromString(endDateTimes, format: "yyyy-MM-dd HH:mm:ss") else {
            return nil
        }
        return endDateTimes.toString(format: "HH:mm")
    }
}
