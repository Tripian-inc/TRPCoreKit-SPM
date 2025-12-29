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
        
        // Get booked activities from current day
        let bookedActivities = viewModel.getBookedActivitiesForSelectedDay()
        
        // Mark that we've loaded initial data
        hasLoadedInitialMapData = true
        
        if allPois.isEmpty && bookedActivities.isEmpty {
            // Center on city if no POIs or booked activities
            let centerLocation = getMapCenterLocation()
            map.setCenter(centerLocation, zoomLevel: 12)
            // Remove any existing routes
            removeAllRoutesFromMap()
            return
        }
        
        // Add annotations for each segment with proper ordering
        addAnnotationsForSegments(segments)
        
        // Add booked activity annotations
        addBookedActivityAnnotations(bookedActivities)
        
        // Draw separate routes for each segment
        if segments.isEmpty {
            // No POI segments, center on booked activities if any
            if !bookedActivities.isEmpty, let firstActivity = bookedActivities.first {
                let coordinate = firstActivity.additionalData?.coordinate ?? firstActivity.coordinate
                if let coordinate = coordinate {
                    map.setCenter(coordinate, zoomLevel: 14)
                }
            }
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
            if let firstPoi = allPois.first, let coordinate = firstPoi.coordinate {
                map.setCenter(coordinate, zoomLevel: allPois.count == 1 ? 14 : 12)
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
                guard let coordinate = poi.coordinate else { continue }

                var annotation = TRPPointAnnotation()
//                annotation.imageName = TRPAppearanceSettings.MapAnnotations.getIcon(tag: poi.icon, type: .route)
                annotation.order = poiIndex + 1 // Order within segment (1-based for display)
                annotation.lat = coordinate.lat
                annotation.lon = coordinate.lon
                annotation.poiId = poi.id
                annotation.isOffer = !poi.offers.isEmpty
                annotations.append(annotation)
            }

            let segmentId = "timeline_segment_\(segmentIndex)_annotations"
            // annotationOrder determines the background color of the order badge
            map.addViewAnnotations(annotations, segmentId: segmentId, annotationOrder: segmentIndex)

        }
    }
    
    private func addBookedActivityAnnotations(_ bookedActivities: [TRPTimelineSegment]) {
        guard let map = map else { return }
        
        var annotations = [TRPPointAnnotation]()
        
        for activity in bookedActivities {
            // Use coordinate from segment or additionalData
            let coordinate = activity.additionalData?.coordinate ?? activity.coordinate
            guard let lat = coordinate?.lat, let lon = coordinate?.lon else { continue }
            
            var annotation = TRPPointAnnotation()
            annotation.imageName = "ic_booked_activity"
            annotation.order = -1 // -1 means no order label will be shown
            annotation.lat = lat
            annotation.lon = lon
            annotation.poiId = activity.additionalData?.activityId ?? ""
            annotation.isOffer = false
            annotations.append(annotation)
        }
        
        if !annotations.isEmpty {
            // Add booked activities as a separate segment with no specific order color
            map.addViewAnnotations(annotations, segmentId: "timeline_booked_activities", annotationOrder: -1)
        }
    }
    
    private func addPoiAnnotations(_ pois: [TRPPoi]) {
        guard let map = map else { return }

        var annotations = [TRPPointAnnotation]()

        for (index, poi) in pois.enumerated() {
            guard let coordinate = poi.coordinate else { continue }

            var annotation = TRPPointAnnotation()
//            annotation.imageName = TRPAppearanceSettings.MapAnnotations.getIcon(tag: poi.icon, type: .route)
            annotation.order = index
            annotation.lat = coordinate.lat
            annotation.lon = coordinate.lon
            annotation.poiId = poi.id
            annotation.isOffer = !poi.offers.isEmpty
            annotations.append(annotation)
        }

        map.addViewAnnotations(annotations, segmentId: "timeline_pois", annotationOrder: 0)
    }
    
    private func drawRouteForPois(_ pois: [TRPPoi]) {
        let locations = pois.compactMap { $0.coordinate }
        guard locations.count > 1 else { return }

        
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

            let locations = pois.compactMap { $0.coordinate }
            guard locations.count > 1 else { continue }
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
//        for segmentIndex in 0..<10 {
//            let segmentId = "timeline_segment_\(segmentIndex)"
//            map.removeRoute(segmentId: segmentId)
//        }
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
        // Collapse collection view when annotation is closed
        collapseCollectionView()
    }

    public func mapView(annotationPressed poiId: String, type: TRPAnnotationType) {
        // Find the index of the item in currentTimelineItems
        var itemIndex: Int? = nil
        
        for (index, item) in currentTimelineItems.enumerated() {
            switch item {
            case .poi(let poi):
                if poi.id == poiId {
                    itemIndex = index
                    break
                }
            case .bookedActivity(let segment):
                if let activityId = segment.additionalData?.activityId, activityId == poiId {
                    itemIndex = index
                    break
                }
            }
        }
        
        // Expand the collection view and scroll to the item
        if let index = itemIndex {
            let indexPath = IndexPath(item: index, section: 0)
            expandCollectionView {
                // Scroll to the item after expansion animation completes
                DispatchQueue.main.async {
                    self.poiPreviewCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                }
            }
        }
    }
    
    public func mapView(clickedLocation: TRPLocation) {
        // Collapse collection view when map is clicked
        collapseCollectionView()
    }
    
    public func mapView(_ mapView: TRPMapView, regionDidChangeAnimated animated: Bool) {
        // Collapse collection view when user moves the map
        collapseCollectionView()
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
        } else if let poi = pois.first, let coordinate = poi.coordinate {
            map.setCenter(coordinate, zoomLevel: 14)
        }
    }
    
    /// Center map on specific location
    public func centerMap(on location: TRPLocation, zoomLevel: Double = 14) {
        guard let map = map else { return }
        map.setCenter(location, zoomLevel: zoomLevel)
    }
}

