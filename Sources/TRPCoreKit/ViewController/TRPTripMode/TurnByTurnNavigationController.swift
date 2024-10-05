//
//  TurnByTurnNavigationController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2021-01-19.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import UIKit
//import MapboxDirections
//import MapboxCoreNavigation
//import MapboxNavigation
//import TRPDataLayer

// NOTE ROTA BAŞKA YERDEN BAŞLADIĞINDA İNDEX KARIŞIYOR OLABİLİR. BU KONUDA ÇÖZÜM OLARAK WAYPOINT NAME İ BULUP ORADAN DEVAM ETTİRİLEBİLİR?
/*
class TurnByTurnNavigationController<T: TRPBaseUIViewController> {
    
    private var mapNavigation: NavigationViewController?
    private var parentVC: T
    
    public var wayPoints = [Waypoint]()
    public var startLocatinon: CLLocationCoordinate2D?
    public var steps = [TRPStep]() {
        didSet {
            wayPoints = steps.map { step -> Waypoint in
                let poi = step.poi
                print("Evren \(poi.name) \(poi.coordinate.lat),\(poi.coordinate.lon)")
                let coordinate = CLLocationCoordinate2D(latitude: poi.coordinate.lat, longitude: poi.coordinate.lon)
                return Waypoint(coordinate: coordinate, name: poi.name)
            }
        }
    }
    public var planId: Int = 0
    public var profileIdentifier: MapboxDirections.DirectionsProfileIdentifier = .cycling
    //Rotanın ilk başlayacağı index
    public var routeIndex = 0
    
    init(parentVC: T) {
        self.parentVC = parentVC
    }
    
    public func openNavigation() {
        
        guard wayPoints.count > 1 else {
            print("[Error] Waypoints count must be more than 2")
            return
        }
        
        let routeOptions = NavigationRouteOptions(waypoints: wayPoints)
        
        routeOptions.profileIdentifier = profileIdentifier
       
        parentVC.viewModel(showPreloader: true)
        
        Directions.shared.calculate(routeOptions) { [weak self] (session, result) in
            
            guard let strongSelf = self else { return }
            
            strongSelf.parentVC.viewModel(showPreloader: false)
            
            switch result {
            case .success(let response):
                guard let route = response.routes?.first, let strongSelf = self else {
                    return
                }
                strongSelf.openNavigationViewController(route: route, option: routeOptions)
            case .failure(let error):
                strongSelf.parentVC.viewModel(error: error)
            }
        }
    }
    
    public func resumeNavigation() {
        guard let navigation = mapNavigation else {return}
        TurnByTurnStepSaver(planId: planId).debug()
    
        parentVC.present(navigation, animated: true) { [weak self] in
            guard let strongSelf = self else {return}
            navigation.navigationService.routeProgress.legIndex = strongSelf.getRouteIndex()
            navigation.navigationService.start()
        }
    }
    
    private func getRouteIndex() -> Int {
        guard let lastPoint = TurnByTurnStepSaver(planId: planId).getLastCompletedPoi() else {return 0}
        for (index, item) in wayPoints.enumerated() {
            if let itemName = item.name, itemName.lowercased() == lastPoint.lowercased() {
                return index
            }
        }
        return 0
    }
    
    
    private func showArrivalInfoAlert(placeName: String) {
        let alertView = UIAlertController(title: "Arrival", message: "You are arriva at \(placeName)", preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alertView.addAction(ok)
        parentVC.present(alertView, animated: true, completion: nil)
    }
    
    deinit {
        print("TurnByTurnNavigationController deinit")
    }
    
}

//MARK: - LOGIC
extension TurnByTurnNavigationController {
    
    private func arrivalPoi(wayPoint: Waypoint, index: Int) {
        if let arrivalName = wayPoint.name, let lastName = wayPoints.last?.name {
            if arrivalName.lowercased() == lastName.lowercased() {
                print("Seyahatiniz tamamlandı")
            }
        }
        routeIndex = index + 1
    }
}


extension TurnByTurnNavigationController: NavigationViewControllerDelegate {
    
    private func openNavigationViewController(route: Route, option: NavigationRouteOptions) {
        mapNavigation = NavigationViewController(for: route, routeIndex: routeIndex, routeOptions: option)
        mapNavigation!.modalPresentationStyle = .fullScreen
        mapNavigation!.delegate = self
        parentVC.present(mapNavigation!, animated: true, completion: nil)
    }
    
    
    //Bir sonraki adıma geçip geçmeyeceğini berliler
    func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool {
        
        let routeIndex = navigationViewController.navigationService.routeProgress.legIndex
        arrivalPoi(wayPoint: waypoint, index: routeIndex)
        TurnByTurnStepSaver(planId: planId).completedPoi(name: waypoint.name ?? "Empty Name")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            navigationViewController.dismiss(animated: true) {
                self.showArrivalInfoAlert(placeName: waypoint.name ?? "")
            }
        }
        return false
    }
    
    func navigationViewController(_ navigationViewController: NavigationViewController, didFailToRerouteWith error: Error) {
        
    }
    
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        navigationViewController.navigationService.stop()
        navigationViewController.dismiss(animated: true, completion: nil)
    }
    
}

 */
