//
//  OnlyMap.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2020-12-18.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import UIKit


class OnlyMap: UIViewController {
    var map:TRPMapView?
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        map = TRPMapView(frame: view.frame, startLocation: nil,zoomLevel:12)
        view.addSubview(map!)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let startLocation = TRPLocation(lat: 52.5268366, lon: 13.3927687)
        let endLocation = TRPLocation(lat: 48.1354094, lon: 11.5465997)
        fetchRouteFromMapBoxServer(pois: [startLocation,endLocation])
    }
}



extension OnlyMap{
    
    private func fetchRouteFromMapBoxServer(pois: [TRPLocation]) {
        
        let accessToken = "sk.eyJ1IjoiZXZyZW55YXNhciIsImEiOiJja2hhZmF3aG8xMHRuMnBuemJndTNubm95In0.BZPh4bRMHv1YDBaSL3wx2A"
        let calculater = TRPRouteCalculator(providerApiKey: accessToken, wayPoints: pois, dailyPlanId: 1)
        calculater.calculateRoute { (route, error, location, id) in
            if let error = error {
                let errorMessage = "Something went wrong with routing. Please delete this trip and re-create it.".toLocalized()
                print(error.localizedDescription)
                print(errorMessage)
                return
            }
            
            guard let route = route else {return}
            var steps = [StepInfoForListOfRouting]()
            for (index, element) in route.legs.enumerated() {
                steps.append(StepInfoForListOfRouting(planId: 0, stepOrder: index, time: element.expectedTravelTime, distance: Float(element.distance)))
            }
            DispatchQueue.main.async {
                self.map?.drawCarRoute(route)
            }
        }
    }
}
