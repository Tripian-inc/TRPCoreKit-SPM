//
//  MapTableViewCell.swift
//  TRPCoreKit
//
//  Created by Rozeri Dilar on 3/18/20.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import TRPUIKit
import Mapbox
import TRPFoundationKit
final class MapTableViewCell: UITableViewCell {
    
    lazy var mapView: MGLMapView = {
           let mapView = MGLMapView(frame: CGRect(x: 0, y: 0, width: 200, height: 220))
           mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
           mapView.isMultipleTouchEnabled = true
           mapView.isZoomEnabled = true
           mapView.isPitchEnabled = true
           mapView.isScrollEnabled = true
           mapView.translatesAutoresizingMaskIntoConstraints = false
           return mapView
       }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
        self.contentView.isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: - UI Design
extension MapTableViewCell {
    
    fileprivate func setup() {
        self.selectionStyle = .none
        setMapView()
    }
    
    fileprivate func setMapView() {
        addSubview(mapView)
        mapView.topAnchor.constraint(equalTo: topAnchor, constant: 16).isActive = true
        mapView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
        mapView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
        mapView.heightAnchor.constraint(equalToConstant: 220).isActive = true
        mapView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16).isActive = true
    }
    
    func setMapView(_ location: TRPLocation){
        mapView.setCenter(CLLocationCoordinate2D(latitude: location.lat, longitude: location.lon), zoomLevel: 15, animated: false)
        let hello = MGLPointAnnotation()
        hello.coordinate = CLLocationCoordinate2D(latitude: location.lat, longitude: location.lon)
        mapView.addAnnotation(hello)
    }
    
}
