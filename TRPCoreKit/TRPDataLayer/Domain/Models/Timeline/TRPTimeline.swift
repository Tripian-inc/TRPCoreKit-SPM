//
//  TRPTimeline.swift
//  TRPDataLayer
//
//  Created by Cem Çaygöz on 08.08.2025.
//  Copyright © 2025 Cem Çaygöz. All rights reserved.
//

import Foundation
import TRPFoundationKit

public struct TRPTimeline: Codable {

    public var id: Int

    public var tripHash: String

    public var tripProfile: TRPTimelineProfile?

    public var city: TRPCity

    public var plans: [TRPTimelinePlan]?

    public var segments: [TRPTimelineSegment]?

    /// Favourite items - used only in CoreKit for itinerary planning, not sent to/from server
    /// This field is populated from TRPItineraryWithActivities when available
    public var favouriteItems: [TRPSegmentFavoriteItem]?
    
    /// Tripdeki tüm poileri döndürür.
    /// - Returns: All pois of trip that are unique
    public func getPois() -> [TRPPoi] {
        var pois = [TRPPoi]()
        plans?.forEach { plan in
            pois.append(contentsOf: plan.getPoi())
        }
        return pois.unique()
    }
    
    
    /// Categorylere göre Poi döndürür.
    /// - Parameter types: category ids
    /// - Returns: All pois of trip that are unique
    public func getPoisWith(types: [Int]) -> [TRPPoi] {
        var pois = [TRPPoi]()
        getPois().forEach { poi in
            let isExist = poi.categories.contains { poiType -> Bool in
                return types.contains { id -> Bool in
                    return id == poiType.id
                }
            }
            
            if isExist {
                pois.append(poi)
            }
        }
        return pois.unique()
    }
    
    /// Poinin hangi günlerde olduğunu döndürür.
    /// - Parameter placeId: Poi id
    /// - Returns: Hangi günlerde var ise onları döndürür. 1,2,3. gün şekilndedir.
    public func getPartOfDay(placeId: String) -> [Int]? {
        guard let plans else { return nil}
        var inDay = [Int]()
        for (order,plan) in plans.enumerated() {
            var exist = false
            for pois in plan.steps {
                if pois.poi?.id == placeId {
                    exist = true
                }
            }
            if exist {
                inDay.append(order + 1)
            }
        }
        return inDay.isEmpty ? nil : inDay
    }
    
    public func getPoiScore(poiId: String) -> Double? {
        guard let plans else { return nil}
        var score: Double? = nil
        plans.forEach { plan in
            if let step = plan.steps.first(where: {$0.poi?.id == poiId}) {
                score = step.score
            }
        }
        return score
    }
    
    public func getStepScore(stepId: Int) -> Double? {
        guard let plans else { return nil}
        var score: Double? = nil
        plans.forEach { plan in
            if let step = plan.steps.first(where: {$0.id == stepId}) {
                score = step.score
            }
        }
        return score
    }
    
    public func isFirstPlan(planId: String) -> Bool  {
        guard let plans else { return false}
        if let first = plans.first {
            return first.id == planId
        }
        return false
    }
    
    public func isLastPlan(planId: String) -> Bool  {
        guard let plans else { return false}
        if let last = plans.last {
            return last.id == planId
        }
        return false
    }
}
