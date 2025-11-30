//
//  TRPUserLocationController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 20.02.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation
import CoreLocation
import TRPFoundationKit



public class TRPUserLocationController: NSObject, CLLocationManagerDelegate {
    
    public typealias Completion = (_ city: Int, _ status: UserStatus,_ userLocation: TRPLocation?) -> Void
    public typealias CompletionUserLocation = (_ userLocation: TRPLocation?) -> Void
    public static var shared = TRPUserLocationController()
    
    public enum UserStatus {
        case inCity, outCity, locationProblem
    }
    
    private let manager = CLLocationManager()
    public var userLatestLocation: TRPLocation? {
        didSet {
            checkUserLocation()
            userLocationHandler?(userLatestLocation)
        }
    }
    private var city: TRPCity?
    private var completionHandler: Completion?
    private var userLocationHandler: CompletionUserLocation?
    
    
    public override init(){
        super.init()
        manager.delegate = self
        manager.requestLocation()
        manager.requestWhenInUseAuthorization()
        if let userLocation = manager.location {
            userLatestLocation = TRPLocation(lat: userLocation.coordinate.latitude, lon: userLocation.coordinate.longitude)
        }
    }
    
    public func start(city: TRPCity) {
        self.city = city
        if let userLocation = manager.location {
            userLatestLocation = TRPLocation(lat: userLocation.coordinate.latitude, lon: userLocation.coordinate.longitude)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            userLatestLocation = TRPLocation(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user location \(error.localizedDescription)")
    }
    
    public func isUserInCity(_ completionHandler: @escaping Completion) {
        self.completionHandler = completionHandler
        checkUserLocation()
    }
    
    public func userLocaion(_ completionHandler: @escaping CompletionUserLocation){
        self.userLocationHandler = completionHandler
        completionHandler(userLatestLocation)
    }
    
    private func checkUserLocation() {
        guard let city = city else {return}
        
        if let userLoc = userLatestLocation {
            if let nw = city.boundaryNorthEast, let es = city.boundarySouthWest {
                var inLat = false
                var inLon = false
                if nw.lat > es.lat {
                    if nw.lat > userLoc.lat && userLoc.lat > es.lat {
                        inLat = true
                    }
                }else {
                    if nw.lat < userLoc.lat && userLoc.lat < es.lat {
                        inLat = true
                    }
                }
                if nw.lon > es.lon {
                    if nw.lon > userLoc.lon && userLoc.lon > es.lon {
                        inLon = true
                    }
                }else {
                    if nw.lon < userLoc.lon && userLoc.lon < es.lon {
                        inLon = true
                    }
                }
                
                if inLat && inLon {
                    
                    completionHandler?(city.id, UserStatus.inCity, userLoc)
                }else {
                    completionHandler?(city.id, UserStatus.outCity, userLoc)
                }
            }else {
                let distance = CLLocation(latitude: city.coordinate.lat, longitude: city.coordinate.lon).distance(from: CLLocation(latitude: userLoc.lat, longitude: userLoc.lon))
                if distance < 50000 {
                    completionHandler?(city.id, UserStatus.inCity, userLoc)
                }else {
                    completionHandler?(city.id, UserStatus.outCity, userLoc)
                }
            }
        }else {
            completionHandler?(city.id, UserStatus.locationProblem,nil)
        }
    }
    
}
