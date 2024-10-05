//
//  TRPRouteCalculator.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 21.12.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation
import MapboxDirections

import CoreLocation

public class TRPRouteCalculator {
    
    private enum DirectionErrorStatus {
        case none, walking, automobile
    }
    
    public enum DirectionProfile {
        case walking, automobile
    }
    
    public enum RouteServicesProvider {
        case MapBox
    }
    
    public typealias CompletationHandler = (_ route: Route? ,_ error:Error? ,_ wayPoints: [TRPLocation],_ dailyPlanId: Int?) -> Void
    
    public var routeServiceProvider: RouteServicesProvider = .MapBox
    public var directionProfile: DirectionProfile = .automobile
    public let providerApiKey: String
    private var routeErrorStatus: DirectionErrorStatus = .none
    private var handler: CompletationHandler?
    private let wayPoints: [TRPLocation]
    private var dailyPlanId:Int?
    public var legCount: Int?
    
    public init(providerApiKey: String, wayPoints: [TRPLocation], dailyPlanId:Int? = nil) {
        self.providerApiKey = providerApiKey
        self.wayPoints = wayPoints
        self.dailyPlanId = dailyPlanId
    }
    
    public func calculateRoute(_ handler: @escaping CompletationHandler) {
        self.handler = handler
        calculate(directionProfile, wayPoints)
    }
    
    private func calculate(_ directionProfile: DirectionProfile,_ mWayPoints:[TRPLocation]) {
        
        var mapBoxProfileIdentify: ProfileIdentifier = .walking
        
        //Yeni bir tip eklenirse burası değiştirilecek
        switch directionProfile {
        case .automobile:
            mapBoxProfileIdentify = .automobile
            break;
        case .walking:
            mapBoxProfileIdentify = .walking
            break;
        }
        
        let mapBoxWayPoints = trpLocationsToWayPoints(mWayPoints)
        let options = RouteOptions(waypoints: mapBoxWayPoints,
                                   profileIdentifier: mapBoxProfileIdentify)
        options.includesSteps = false
        options.includesAlternativeRoutes = true
        options.roadClassesToAvoid = [.ferry]
        options.routeShapeResolution = .full
        //todo: - mapbox framework ü değiştikten sonra düzenlenecek
        
        let directions = Directions(credentials: Credentials(accessToken: providerApiKey))
        
        _ = directions.calculate(options) { (session, result) in
            
            switch result {
            case .success(let routeResponse):
                
                guard let route = routeResponse.routes?.first else {return}
                self.legCount = route.legs.count
                if self.routeErrorStatus == .walking {
                    self.routeErrorStatus = .automobile
                    let newCalculatedWayPoints = self.legToWayPoint(route)
                    self.calculate(DirectionProfile.automobile, newCalculatedWayPoints)
                    return
                }
                self.sendCompletionHandler(route, nil)
                
            case .failure(let error):
                //Eski error yapısı yeni Mapbox api' ından dolayı değiştirildi.
                if self.isErrorAboutNoRoute(error.localizedDescription) && self.routeErrorStatus == .none {
                    self.routeErrorStatus = .walking
                    self.calculate(DirectionProfile.automobile, mWayPoints)
                    return
                }
                self.sendCompletionHandler(nil, error)
            }
        }
       
    }
    
    
    private func legToWayPoint(_ route: Route) -> [TRPLocation] {
        
        var mWayPoints = [TRPLocation]()
        
        for leg in route.legs{
            if let source = leg.source  {
                mWayPoints.append(TRPLocation(lat: source.coordinate.latitude, lon: source.coordinate.longitude))
            }

        }
        if let last = route.legs.last,  let destination = last.destination {
            mWayPoints.append(TRPLocation(lat: destination.coordinate.latitude, lon: destination.coordinate.longitude))
        }
        return mWayPoints
    }
    
    private func sendCompletionHandler(_ route: Route? ,_ error:Error?) {
        handler?(route,error,wayPoints,dailyPlanId)
    }
    
    internal func trpLocationsToWayPoints(_ trpLocations: [TRPLocation]) -> [Waypoint] {
        var mapBoxWayPoints = [Waypoint]()
        for point in trpLocations {
            let coordinate = CLLocationCoordinate2D(latitude: point.lat, longitude: point.lon)
            let newPoint = Waypoint(coordinate: coordinate)
            mapBoxWayPoints.append(newPoint)
        }
        return mapBoxWayPoints
    }
    
    internal func isErrorAboutNoRoute(_ localizedDes: String)  -> Bool {
        let noRoute = "no route"
        let errorDescription = localizedDes.lowercased()
        if errorDescription.contains(noRoute) {
            return true
        }
        return false
    }
    
    internal func isErrorAboutNoRoute(_ error: NSError)  -> Bool {
        let noRoute = "no route"
        let errorDescription = error.localizedDescription.lowercased()
        if errorDescription.contains(noRoute) {
            return true
        }
        for errorUser in error.userInfo {
            if let msg = errorUser.value as? String {
                let lowerMessage = msg.lowercased()
                if lowerMessage.contains(noRoute) {
                    return true
                }
            }
        }
        return false
    }
    
}
