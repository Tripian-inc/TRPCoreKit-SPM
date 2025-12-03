//
//  TRPTimelineItineraryVC+Map.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 02.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
import MapboxDirections
import TRPFoundationKit
import SDWebImage

// MARK: - Map Setup and Management
extension TRPTimelineItineraryVC {
    
    internal func initializeMap() {
        guard map == nil else { return }
        
        // Reset the flag when initializing a new map
        hasLoadedInitialMapData = false
        
        let centerLocation = getMapCenterLocation()
        let startLocation = LocationCoordinate(lat: centerLocation.lat, lon: centerLocation.lon)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Ensure layout is complete before creating map
            self.mapContainerView.layoutIfNeeded()
            
            self.map = TRPMapView(
                frame: self.mapContainerView.bounds,
                startLocation: startLocation,
                zoomLevel: 12
            )
            
            if let map = self.map {
                map.translatesAutoresizingMaskIntoConstraints = false
                self.mapContainerView.addSubview(map)
                
                // Setup constraints for map
                NSLayoutConstraint.activate([
                    map.topAnchor.constraint(equalTo: self.mapContainerView.topAnchor),
                    map.leadingAnchor.constraint(equalTo: self.mapContainerView.leadingAnchor),
                    map.trailingAnchor.constraint(equalTo: self.mapContainerView.trailingAnchor),
                    map.bottomAnchor.constraint(equalTo: self.mapContainerView.bottomAnchor)
                ])
                
                map.delegate = self
                map.showUserLocation = true
                
                // Data will be loaded in mapViewDidFinishLoading
                // Also add a fallback to load data after a short delay to ensure map is ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                    guard let self = self else { return }
                    // Only load if map still exists, container is visible, and data hasn't been loaded yet
                    if self.map != nil && !self.mapContainerView.isHidden && !self.hasLoadedInitialMapData {
                        self.loadMapData()
                    }
                }
            }
        }
    }
    
    private func getMapCenterLocation() -> TRPLocation {
        // Get center from first segment or use default
        if let firstPlan = viewModel.getFirstPlan(),
           let city = firstPlan.city {
            return city.coordinate
        }
        
        // Default location if no data
        return TRPLocation(lat: 41.9028, lon: 12.4964) // Rome as default
    }
    
    internal func loadMapData() {
        guard let map = map else { 
            return 
        }
        
        // Get segments with POIs from current day
        let segments = viewModel.getSegmentsWithPoisForSelectedDay()
        let allPois = segments.flatMap { $0 }
        
        
        // Mark that we've loaded initial data
        hasLoadedInitialMapData = true
        
        if allPois.isEmpty {
            // Center on city if no POIs
            let centerLocation = getMapCenterLocation()
            map.setCenter(centerLocation, zoomLevel: 12)
            // Remove any existing routes
            removeAllRoutesFromMap()
            return
        }
        
        // Add annotations for each segment with proper ordering
        addAnnotationsForSegments(segments)
        
        // Draw separate routes for each segment
        if segments.isEmpty {
            return
        }
        
        var hasMultiplePoiSegments = false
        for segment in segments {
            if segment.count > 1 {
                hasMultiplePoiSegments = true
                break
            }
        }
        
        if hasMultiplePoiSegments {
            // Show loading indicator while calculating routes
            showLoader(true)
            drawRoutesForSegments(segments)
        } else {
            // No segments with multiple POIs, just center on all POIs
            if let firstPoi = allPois.first {
                map.setCenter(firstPoi.coordinate, zoomLevel: allPois.count == 1 ? 14 : 12)
            }
            removeAllRoutesFromMap()
        }
    }
    
    private func addAnnotationsForSegments(_ segments: [[TRPPoi]]) {
        guard let map = map else { return }
        
        // Add annotations for each segment separately with proper ordering
        // Each segment has:
        // - annotationOrder: segment index (0, 1, 2, ...) -> determines background color
        // - order: POI index within segment (1, 2, 3, ...) -> displayed on annotation
        //
        // Background colors cycle through: Blue, Green, Pink, Orange, Primary Text
        // Based on ColorSet.getMapColor(annotationOrder)
        
        for (segmentIndex, pois) in segments.enumerated() {
            var annotations = [TRPPointAnnotation]()
            
            for (poiIndex, poi) in pois.enumerated() {
                var annotation = TRPPointAnnotation()
                annotation.imageName = TRPAppearanceSettings.MapAnnotations.getIcon(tag: poi.icon, type: .route)
                annotation.order = poiIndex + 1 // Order within segment (1-based for display)
                annotation.lat = poi.coordinate.lat
                annotation.lon = poi.coordinate.lon
                annotation.poiId = poi.id
                annotation.isOffer = !poi.offers.isEmpty
                annotations.append(annotation)
            }
            
            let segmentId = "timeline_segment_\(segmentIndex)_annotations"
            // annotationOrder determines the background color of the order badge
            map.addViewAnnotations(annotations, segmentId: segmentId, annotationOrder: segmentIndex)
            
        }
    }
    
    private func addPoiAnnotations(_ pois: [TRPPoi]) {
        guard let map = map else { return }
        
        var annotations = [TRPPointAnnotation]()
        
        for (index, poi) in pois.enumerated() {
            var annotation = TRPPointAnnotation()
            annotation.imageName = TRPAppearanceSettings.MapAnnotations.getIcon(tag: poi.icon, type: .route)
            annotation.order = index
            annotation.lat = poi.coordinate.lat
            annotation.lon = poi.coordinate.lon
            annotation.poiId = poi.id
            annotation.isOffer = !poi.offers.isEmpty
            annotations.append(annotation)
        }
        
        map.addViewAnnotations(annotations, segmentId: "timeline_pois", annotationOrder: 0)
    }
    
    private func drawRouteForPois(_ pois: [TRPPoi]) {
        let locations = pois.map { $0.coordinate }
        
        
        viewModel.calculateRoute(for: locations) { [weak self] route, error in
            guard let self = self else { return }
            
            // Hide loader in all cases
            DispatchQueue.main.async {
                self.showLoader(false)
            }
            
            if let error = error {
                // Remove previous route on error
                DispatchQueue.main.async {
                    self.removeRouteFromMap()
                    
                    // Show error alert to user
                    let errorMessage = TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.map.routeError")
                    EvrAlertView.showAlert(contentText: errorMessage.isEmpty ? "Unable to calculate route" : errorMessage, 
                                          type: .error,
                                          bottomSpace: 80)
                }
                return
            }
            
            guard let route = route else {
                // Remove previous route if no route is returned
                DispatchQueue.main.async {
                    self.removeRouteFromMap()
                    
                    // Show error alert to user
                    let errorMessage = TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.map.routeError")
                    EvrAlertView.showAlert(contentText: errorMessage.isEmpty ? "Unable to calculate route" : errorMessage, 
                                          type: .error,
                                          bottomSpace: 80)
                }
                return
            }
            
            guard let map = self.map else {
                return
            }
            
            DispatchQueue.main.async {
                map.drawRoute(route, style: .rota)
            }
        }
    }
    
    private func drawRoutesForSegments(_ segments: [[TRPPoi]]) {
        guard segments.count > 0 else { return }
        
        var routesToCalculate = 0
        var routesCompleted = 0
        var hasError = false
        
        // Count how many routes we need to calculate
        for segment in segments {
            if segment.count > 1 {
                routesToCalculate += 1
            }
        }
        
        guard routesToCalculate > 0 else {
            showLoader(false)
            return
        }
        
        
        // Draw route for each segment
        for (segmentIndex, pois) in segments.enumerated() {
            guard pois.count > 1 else { continue }
            
            let locations = pois.map { $0.coordinate }
            let segmentId = "timeline_segment_\(segmentIndex)"
            
            viewModel.calculateRoute(for: locations) { [weak self] route, error in
                guard let self = self else { return }
                
                routesCompleted += 1
                
                if let error = error {
                    hasError = true
                } else if let route = route, let map = self.map {
                    DispatchQueue.main.async {
                        // Draw route with segment ID and order for different colors
                        map.drawRoute(route, segmentId: segmentId, segmentOrder: segmentIndex)
                    }
                } else {
                    hasError = true
                }
                
                // Hide loader and show error when all routes are done
                if routesCompleted == routesToCalculate {
                    DispatchQueue.main.async {
                        self.showLoader(false)
                        
                        if hasError {
                            let errorMessage = TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.map.routeError")
                            EvrAlertView.showAlert(
                                contentText: errorMessage.isEmpty ? "Unable to calculate some routes" : errorMessage,
                                type: .warning,
                                bottomSpace: 80
                            )
                        }
                    }
                }
            }
        }
    }
    
    internal func clearMapAnnotations() {
        guard let map = map else { 
            return 
        }
        
        // Clear all view annotations from the map
        map.clearViewAnnotation()
        
        // Also clear segment-specific annotations
        for segmentIndex in 0..<10 {
            let segmentId = "timeline_segment_\(segmentIndex)_annotations"
            // Note: clearViewAnnotation() should handle this, but we keep this for safety
        }
    }
    
    internal func removeRouteFromMap() {
        guard let map = map else { return }
        map.removeRoute(style: .rota)
    }
    
    internal func removeAllRoutesFromMap() {
        guard let map = map else { return }
        
        // Remove the legacy style-based route
        map.removeRoute(style: .rota)
        
        // Remove all segment-based routes
        // We'll try to remove routes for up to 10 segments (should be more than enough)
        for segmentIndex in 0..<10 {
            let segmentId = "timeline_segment_\(segmentIndex)"
            map.removeRoute(segmentId: segmentId)
        }
    }
    
    internal func refreshMap() {
        guard let map = map else { 
            // Map is still initializing, data will be loaded in mapViewDidFinishLoading
            return 
        }
        
        // Clear annotations and all routes
        clearMapAnnotations()
        removeAllRoutesFromMap()
        
        // Load new data which will draw new routes
        loadMapData()
    }
}

// MARK: - TRPMapViewDelegate
extension TRPTimelineItineraryVC: TRPMapViewDelegate {
    public func mapViewDidFinishLoading(_ mapView: TRPMapView) {
        // Load map data after map is ready
        loadMapData()
    }
    
    public func mapViewCloseAnnotation(_ mapView: TRPMapView) {
        guard let callOut = callOutController else {return}
        callOut.hidden()
    }
    
    
    public func mapView(clickedLocation: TRPLocation) {
        // Handle map click
    }
    
    public func mapView(annotationPressed poiId: String, type: TRPAnnotationType) {
        // Handle POI annotation tap
        if let poi = viewModel.getPoi(byId: poiId) {
            openCallOut(poi)
        }
    }
    
    public func mapView(_ mapView: TRPMapView, regionDidChangeAnimated animated: Bool) {
        // Handle map region changes
    }
}

// MARK: - Map Helper
extension TRPTimelineItineraryVC {
    
    /// Show specific POIs on map
    public func showPoisOnMap(_ pois: [TRPPoi]) {
        guard let map = map else {
            // Initialize map first
            initializeMap()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showPoisOnMap(pois)
            }
            return
        }
        
        clearMapAnnotations()
        addPoiAnnotations(pois)
        
        if pois.count > 1 {
            drawRouteForPois(pois)
        } else if let poi = pois.first {
            map.setCenter(poi.coordinate, zoomLevel: 14)
        }
    }
    
    /// Center map on specific location
    public func centerMap(on location: TRPLocation, zoomLevel: Double = 14) {
        guard let map = map else { return }
        map.setCenter(location, zoomLevel: zoomLevel)
    }
    
    /// Open callout for a POI
    private func openCallOut(_ poi: TRPPoi) {
        var category = poi.getCategoryName()
        var rating = poi.isRatingAvailable() ? poi.rating ?? 0 : 0
        rating = rating.rounded()
        
        var rightButton: AddRemoveNavButtonStatus? = nil
        // For timeline, we might not need add/remove functionality
        // But keeping it for consistency with TRPTripModeVC
        if poi.placeType == .poi {
            rightButton = .add // Default to add, can be customized based on your logic
        }
        
        let poiRating = poi.rating ?? 0
        let poiPrice = poi.price ?? 0
        
        let callOutCell = CallOutCellModel(id: poi.id,
                                           name: poi.name,
                                           poiCategory: category,
                                           starCount: Float(rating),
                                           reviewCount: Int(poiRating),
                                           price: poiPrice,
                                           rightButton: rightButton)
        
        callOutController?.cellPressed = { [weak self] id, inRoute in
            guard let self = self else { return }
            self.callOutController?.hidden()
            
            if id == TRPPoi.ACCOMMODATION_ID { return }
            
            if poi.placeType == .poi {
                // Get the step associated with this POI
                if let step = self.viewModel.getStep(forPoiId: id) {
                    self.delegate?.timelineItineraryDidSelectStep(self, step: step)
                }
            }
        }
        
        callOutController?.action = { [weak self] status, id in
            guard let self = self else { return }
            self.callOutController?.hidden()
            
            // Handle add/remove actions if needed
            // This can be customized based on your requirements
            if status == .add {
            } else if status == .remove {
            }
        }
        
        callOutController?.show(model: callOutCell)
        callOutController?.getCellImageView()?.image = nil
        
        // Load POI image
        guard let image = poi.image?.url else { return }
        guard let url = URL(string: image) else { return }
        
        SDWebImageManager.shared.loadImage(with: url, options: .lowPriority, context: nil, progress: nil) { [weak self] (downloadedImage, _, error, _, _, _) in
            guard let self = self else { return }
            if error != nil {
                return
            }
            guard let image = downloadedImage else {
                return
            }
            self.callOutController?.getCellImageView()?.image = image
        }
    }
}

