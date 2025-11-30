//
//  TRPPointAnnotation.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 3.08.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//
import MapboxMaps

public struct TRPPointAnnotation: Codable {
    var imageName: String?
    var order: Int?
    var poiId: String?
    var isOffer: Bool = false
    var lat: Double?
    var lon: Double?
}

extension TRPPointAnnotation {
    func asPointAnnotation( tapHandler: ((MapContentGestureContext) -> Bool)? = nil) -> PointAnnotation {
        guard let lat = lat, let lon = lon else {
            return PointAnnotation(point: Point(CLLocationCoordinate2D()))
        }
        var pointAnnotation = PointAnnotation(point: Point(CLLocationCoordinate2D(latitude: lat, longitude: lon)))
        pointAnnotation.image = .init(image: UIImage(named: imageName ?? "")!, name: "")
        if let jsonObject = convertToJSONObject(from: self)  {
            pointAnnotation.customData = JSONObject.init(rawValue: jsonObject) ?? JSONObject()
        }
        pointAnnotation.tapHandler = tapHandler
        return pointAnnotation
    }
    
    func asViewAnnotation(annotationOrder: Int = 0, tapHandler: ((String) -> Void)? = nil) -> ViewAnnotation {
        guard let lat = lat, let lon = lon , let imageName = imageName else {
            return ViewAnnotation(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), view: UIView())
        }
        let annotationView = TRPRotaAnnotationView(reuseIdentifier: imageName,
                                                   imageName: imageName,
                                                   order: order,
                                                   annotationOrder: annotationOrder)
        annotationView.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        annotationView.poiId = poiId
        annotationView.onTapHandler = tapHandler
        let pointAnnotation = ViewAnnotation(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon), view: annotationView)
        pointAnnotation.allowOverlap = true
        return pointAnnotation
    }
}
