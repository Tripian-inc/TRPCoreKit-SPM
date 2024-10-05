//
//  MapTableViewCellController.swift
//  TRPCoreKit
//
//  Created by Rozeri Dilar on 3/18/20.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import TRPUIKit
import Mapbox

final class MapTableViewCellController: GenericCellController<MapTableViewCell> {
    private let item: MapCellModel
    
    init(mapCellModel: MapCellModel) {
        self.item = mapCellModel
    }
    
    override func configureCell(_ cell: MapTableViewCell) {
        setMapView(cell)
    }
    
    override func didSelectCell() {
    }
    
    override func cellSize() -> CGFloat {
        return 170
    }
    
}

//MARK: Calculations
extension MapTableViewCellController{
    func setMapView(_ cell: MapTableViewCell){
        cell.mapView.setCenter(CLLocationCoordinate2D(latitude: item.location.lat, longitude: item.location.lon), zoomLevel: 15, animated: false)
        let hello = MGLPointAnnotation()
        hello.coordinate = CLLocationCoordinate2D(latitude: item.location.lat, longitude: item.location.lon)
        cell.mapView.addAnnotation(hello)
    }
}
