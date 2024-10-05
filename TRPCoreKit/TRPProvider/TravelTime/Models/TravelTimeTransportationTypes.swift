//
//  TravelTimeTransportationType.swift
//  TRPProvider
//
//  Created by Cem Çaygöz on 17.06.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation


public enum TravelTimeTransportationTypes: String, CaseIterable {
    case walking = "Walking"
    case cycling = "Cycling"
    case driving = "Driving"
    case publicTransport = "Public Transport"
    case coach = "Coach"
    case bus = "Bus"
    case train = "Train"
    case ferry = "Ferry"
    
    
    public func value() -> RouteRequestSearchTransportation {
        switch self {
        case .walking:
            return RouteRequestSearchTransportation(type: "walking")
        case .cycling:
            return RouteRequestSearchTransportation(type: "cycling")
        case .driving:
            return RouteRequestSearchTransportation(type: "driving")
        case .publicTransport:
            return RouteRequestSearchTransportation(type: "public_transport")
        case .coach:
            return RouteRequestSearchTransportation(type: "coach")
        case .bus:
            return RouteRequestSearchTransportation(type: "bus")
        case .train:
            return RouteRequestSearchTransportation(type: "train")
        case .ferry:
            return RouteRequestSearchTransportation(type: "ferry")
        }
    }
}
