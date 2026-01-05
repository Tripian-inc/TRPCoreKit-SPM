//
//  MapTableViewCell.swift
//  TRPCoreKit
//
//  Created by Rozeri Dilar on 3/18/20.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import MapboxMaps
import TRPFoundationKit
import UIKit

final class MapTableViewCell: UITableViewCell {
    
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
//        setMapView()
    }
    
    fileprivate func setMapView() {
    }
    
    func setMapView(_ location: TRPLocation, iconTag: String) {
        let center = CLLocationCoordinate2D(latitude: location.lat, longitude: location.lon)
//        let cameraOptions = CameraOptions(center: center, zoom: 15)
//        mapView.camera.ease(to: cameraOptions, duration: 0)
        
        let camera = CameraOptions(center: center, zoom: 15)
        let options = MapInitOptions(cameraOptions: camera)
        let mapView = MapView(frame: CGRect(x: 0, y: 0, width: 200, height: 220), mapInitOptions: options)
        
        // Create point annotation
        var pointAnnotation = PointAnnotation(coordinate: center)
        let imgName = TRPAppearanceSettings.MapAnnotations.getIcon(tag: iconTag, type: .route)
        let image = UIImage(named: imgName) ?? UIImage()
        pointAnnotation.image = .init(image: image, name: imgName)
        
        // Create annotation manager if needed
        let pointAnnotationManager = mapView.annotations.makePointAnnotationManager()
        pointAnnotationManager.annotations = [pointAnnotation]
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.gestures.options.pinchZoomEnabled = true
        mapView.gestures.options.quickZoomEnabled = true
//        mapView.gestures.options.isScrollEnabled = true
        mapView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mapView)
        mapView.topAnchor.constraint(equalTo: topAnchor, constant: 16).isActive = true
        mapView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0).isActive = true
        mapView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
        mapView.heightAnchor.constraint(equalToConstant: 220).isActive = true
        mapView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16).isActive = true
        setNeedsLayout()
    }
    
}
