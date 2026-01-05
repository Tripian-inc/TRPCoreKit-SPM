//
//  TRPTrip.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 5.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

public struct TRPTrip: Codable {
    
    public var id: Int
    
    public var tripHash: String
    
    public var tripProfile: TRPTripProfile
    
    public var city: TRPCity

    public var plans: [TRPPlan]
    
    /// Tripdeki tüm poileri döndürür.
    /// - Returns: All pois of trip that are unique
    public func getPois() -> [TRPPoi] {
        var pois = [TRPPoi]()
        plans.forEach { plan in
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
        var inDay = [Int]()
        for (order,plan) in plans.enumerated() {
            var exist = false
            for pois in plan.steps {
                if pois.poi.id == placeId {
                    exist = true
                }
            }
            if exist {
                inDay.append(order + 1)
            }
        }
        return inDay.isEmpty ? nil : inDay
    }
    
    public func getPoiScore(poiId: String) -> Float? {
        var score: Float? = nil
        plans.forEach { plan in
            if let step = plan.steps.first(where: {$0.poi.id == poiId}) {
                score = step.score
            }
        }
        return score
    }
    
    public func getStepScore(stepId: Int) -> Float? {
        var score: Float? = nil
        plans.forEach { plan in
            if let step = plan.steps.first(where: {$0.id == stepId}) {
                score = step.score
            }
        }
        return score
    }
    
    public func isPartOfDay(placeId: String) -> Bool {
        var inDay = [Int]()
        for (order,plan) in plans.enumerated() {
            for pois in plan.steps {
                if pois.poi.id == placeId {
                    return true
                }
            }
        }
        return false
    }
    
    public func isFirstPlan(planId: Int) -> Bool  {
        if let first = plans.first {
            return first.id == planId
        }
        return false
    }
    
    public func isLastPlan(planId: Int) -> Bool  {
        if let last = plans.last {
            return last.id == planId
        }
        return false
    }
    
    public func getArrivalDate() -> TRPTime? {
        return tripProfile.arrivalDate
    }
    
    public func getDepartureDate() -> TRPTime? {
        return tripProfile.departureDate
    }
}

