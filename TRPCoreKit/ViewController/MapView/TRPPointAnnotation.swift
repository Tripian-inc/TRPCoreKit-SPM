//
//  TRPPointAnnotation.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 3.08.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//
import MapboxMaps
import UIKit

public struct TRPPointAnnotation: Codable {
    var imageName: String?
    var order: Int?
    var poiId: String?
    var isOffer: Bool = false
    var lat: Double?
    var lon: Double?
    var cityIndex: Int = 0  // City index for multi-city marker coloring
    var isSelected: Bool = false  // Selection state for marker appearance
    var isCityMarker: Bool = false  // True for city markers on multi-destination days
    var cityId: String?  // City ID for city markers
}

extension TRPPointAnnotation {
    func asPointAnnotation( tapHandler: ((MapContentGestureContext) -> Bool)? = nil) -> PointAnnotation {
        guard let lat = lat, let lon = lon else {
            return PointAnnotation(point: Point(CLLocationCoordinate2D()))
        }
        var pointAnnotation = PointAnnotation(point: Point(CLLocationCoordinate2D(latitude: lat, longitude: lon)))
        pointAnnotation.image = .init(image: UIImage(named: imageName ?? "")!, name: "")
        if let jsonObject = self.convertToJSONObject() {
            pointAnnotation.customData = JSONObject.init(rawValue: jsonObject) ?? JSONObject()
        }
        pointAnnotation.tapHandler = tapHandler
        return pointAnnotation
    }
    
    func asViewAnnotation(annotationOrder: Int = 0, tapHandler: ((String) -> Void)? = nil) -> ViewAnnotation {
        guard let lat = lat, let lon = lon else {
            return ViewAnnotation(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), view: UIView())
        }

        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)

        // City marker - use TRPCityMarkerAnnotationView with 40x40 size
        if isCityMarker {
            let cityMarkerView = TRPCityMarkerAnnotationView()
            cityMarkerView.cityId = cityId
            cityMarkerView.onTapHandler = tapHandler

            // Wrap in a container with explicit size constraints for Mapbox
            let containerView = UIView()
            containerView.backgroundColor = .clear
            containerView.isUserInteractionEnabled = true
            containerView.translatesAutoresizingMaskIntoConstraints = false
            cityMarkerView.translatesAutoresizingMaskIntoConstraints = false

            containerView.addSubview(cityMarkerView)

            NSLayoutConstraint.activate([
                containerView.widthAnchor.constraint(equalToConstant: 40),
                containerView.heightAnchor.constraint(equalToConstant: 40),
                cityMarkerView.widthAnchor.constraint(equalToConstant: 40),
                cityMarkerView.heightAnchor.constraint(equalToConstant: 40),
                cityMarkerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                cityMarkerView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
            ])

            let pointAnnotation = ViewAnnotation(coordinate: coordinate, view: containerView)
            pointAnnotation.allowOverlap = true
            return pointAnnotation
        }

        // Step marker - use simplified annotation view with order (24x24)
        let displayOrder = order ?? 0
        let annotationView = TRPRotaAnnotationView(order: displayOrder, cityIndex: cityIndex, isSelected: isSelected)
        annotationView.poiId = poiId
        annotationView.onTapHandler = tapHandler

        // Wrap in a container with explicit size constraints for Mapbox
        let containerView = UIView()
        containerView.backgroundColor = .clear
        containerView.isUserInteractionEnabled = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        annotationView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(annotationView)

        // Add explicit size constraints
        NSLayoutConstraint.activate([
            containerView.widthAnchor.constraint(equalToConstant: 24),
            containerView.heightAnchor.constraint(equalToConstant: 24),
            annotationView.widthAnchor.constraint(equalToConstant: 24),
            annotationView.heightAnchor.constraint(equalToConstant: 24),
            annotationView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            annotationView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])

        // Create ViewAnnotation
        let pointAnnotation = ViewAnnotation(coordinate: coordinate, view: containerView)
        pointAnnotation.allowOverlap = true

        return pointAnnotation
    }
}
