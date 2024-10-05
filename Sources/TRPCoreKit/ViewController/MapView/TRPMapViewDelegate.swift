//
//  TRPMapViewDelegate.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 6.08.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit
public typealias LocationCoordinate = (lat:Double, lon: Double)

public enum TRPAnnotationType {
    case styleAnnotation, viewAnnotation
}

public protocol TRPMapViewDelegate:AnyObject {
    
    func mapViewDidFinishLoading(_ mapView: TRPMapView)
    
    func mapViewImagesForFilteringLayers(_ mapView: TRPMapView) -> [TPRMapViewImages]?
    
    func mapViewChangedZoomLevel(_ mapView: TRPMapView, zoomLevel: CGFloat)

    func mapViewCloseAnnotation(_ mapView: TRPMapView)
    
    func mapView(_ mapView:TRPMapView, regionDidChangeAnimated animated: Bool)
    //func mapViewGeoJson(_ mapView: TRPMapView) -> GeoJson?
    
    func mapView(_ mapView: TRPMapView, annotationPressed annotationId: String, type: TRPAnnotationType)
    
    func mapView(_ mapView: TRPMapView, userLocationUpdate location: TRPLocation)

    func mapViewWillStartLocationingUser(_ mapView: TRPMapView)
    
    func mapViewDidStopLocationingUser(_ mapView: TRPMapView)
    
    func mapView(_ mapView: TRPMapView, didChange mode: TRPUserTrackingMode)
}

//Optional Delegation methods
extension TRPMapViewDelegate{
    
    
    public func mapViewImagesForFilteringLayers(_ mapView: TRPMapView) -> [TPRMapViewImages]? {
        
        var images: [TPRMapViewImages] = []
        
        for iconImage in TRPAppearanceSettings.MapAnnotations.getAllIcon(.normal) {
            if let img = TRPImageController().getImage(inFramework: iconImage.imageName, inApp: nil) {
                images.append(TPRMapViewImages(uiImage: img, tag:iconImage.tag))
            }
        }
        return images
    }
    
    
    public func mapViewChangedZoomLevel(_ mapView: TRPMapView, zoomLevel: CGFloat) {}
    
    public func mapView(_ mapView:TRPMapView, regionDidChangeAnimated animated: Bool) {}
    
    public func mapView(_ mapView: TRPMapView, userLocationUpdate location: TRPLocation){
        
    }
    
    public func mapViewWillStartLocationingUser(_ mapView: TRPMapView) {}
    
    public func mapViewDidStopLocationingUser(_ mapView: TRPMapView) {}
    
    public func mapView(_ mapView: TRPMapView, didChange mode: TRPUserTrackingMode) {}
}
