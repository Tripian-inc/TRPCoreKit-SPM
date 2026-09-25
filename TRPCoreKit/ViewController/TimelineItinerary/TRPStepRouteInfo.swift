//
//  TRPStepRouteInfo.swift
//  TRPCoreKit
//

import Foundation
import CoreLocation
import MapboxDirections

/// Distance, duration and shape of the route between two consecutive timeline steps,
/// plus the profile they were routed with.
struct TRPStepRouteInfo {

    /// Walking legs at or beyond this distance are re-routed by car.
    static let walkingThresholdMeters: Double = 1500

    private static let drivingMinutesPerKm: Double = 1.5

    /// Kilometers, rounded to one decimal.
    let distance: Float
    /// Minutes.
    let time: Int
    let isWalking: Bool
    /// Leg shape for drawing on the map; the straight line between the endpoints when the leg has no steps.
    let shape: [CLLocationCoordinate2D]

    init(leg: RouteLeg, isWalking: Bool) {
        let readable = ReadableDistance.calculate(distance: Float(leg.distance), time: leg.expectedTravelTime)
        self.distance = readable.distance
        self.time = readable.time
        self.isWalking = isWalking
        self.shape = TRPStepRouteInfo.shape(of: leg)
    }

    /// Driving estimate for a leg the directions service could not route by car; keeps the walking shape.
    static func estimatedDriving(from walkingLeg: RouteLeg) -> TRPStepRouteInfo {
        let seconds = walkingLeg.distance / 1000 * drivingMinutesPerKm * 60
        let readable = ReadableDistance.calculate(distance: Float(walkingLeg.distance), time: seconds)
        return TRPStepRouteInfo(distance: readable.distance, time: readable.time, isWalking: false, shape: shape(of: walkingLeg))
    }

    private init(distance: Float, time: Int, isWalking: Bool, shape: [CLLocationCoordinate2D]) {
        self.distance = distance
        self.time = time
        self.isWalking = isWalking
        self.shape = shape
    }

    private static func shape(of leg: RouteLeg) -> [CLLocationCoordinate2D] {
        let coordinates = leg.steps.flatMap { $0.shape?.coordinates ?? [] }
        if coordinates.count > 1 { return coordinates }
        return [leg.source?.coordinate, leg.destination?.coordinate].compactMap { $0 }
    }
}
