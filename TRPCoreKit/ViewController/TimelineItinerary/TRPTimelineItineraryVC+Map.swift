//
//  TRPTimelineItineraryVC+Map.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 02.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
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
        // Get center from preferred city (selected day > timeline.city > first plan)
        if let coordinate = viewModel.getPreferredCityCoordinate() {
            return coordinate
        }

        // Default location if no valid city data
        return TRPLocation(lat: 41.9028, lon: 12.4964) // Rome as default
    }
    
    internal func loadMapData() {
        guard let map = map else {
            return
        }

        // Get ordered items for map (uses unified order matching list view)
        let orderedItems = viewModel.getOrderedItemsForMap()

        // Mark that we've loaded initial data
        hasLoadedInitialMapData = true

        if orderedItems.isEmpty {
            // Center on city if no items
            let centerLocation = getMapCenterLocation()
            map.setCenter(centerLocation, zoomLevel: 12)
            // Remove any existing routes
            removeAllRoutesFromMap()
            selectedMarkerPoiIds.removeAll()
            return
        }

        // Reset multi-city zoom state on data reload
        isShowingStepMarkersInMultiCity = false

        // Check if there are multiple cities
        if viewModel.hasMultipleCities() {
            // Multi-destination day: Show city markers + selected step marker
            selectedMarkerPoiIds.removeAll()

            // Auto-select first step
            if let firstItem = orderedItems.first {
                selectedMarkerPoiIds.insert(firstItem.item.itemId)
            }

            // Add city markers
            addCityAnnotations()

            // Add selected step marker
            addSelectedStepAnnotation(orderedItems: orderedItems)
        } else {
            // Single city day: Show step markers
            // Auto-select first item on initial load
            if let firstItem = orderedItems.first {
                selectedMarkerPoiIds.removeAll()
                selectedMarkerPoiIds.insert(firstItem.item.itemId)
            }

            // Add annotations with unified order
            addAnnotationsForOrderedItems(orderedItems)
        }

        // Reload collection view to reflect initial selection state
        poiPreviewCollectionView.reloadData()

        // Collect all annotation coordinates and fit camera to show them all
        let allCoordinates = orderedItems.compactMap { item -> CLLocationCoordinate2D? in
            guard let coordinate = item.item.coordinate else { return nil }
            return CLLocationCoordinate2D(latitude: coordinate.lat, longitude: coordinate.lon)
        }
        map.fitCamera(to: allCoordinates)

        // Get POIs for routing
        let segments = viewModel.getSegmentsWithPoisForSelectedDay()

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
            removeAllRoutesFromMap()
        }
    }

    /// Add annotations for ordered items with unified order, city-specific coloring, and selection state
    internal func addAnnotationsForOrderedItems(_ orderedItems: [(order: Int, section: Int, cityIndex: Int, item: MapDisplayItem)]) {
        guard let map = map else { return }

        var annotations = [TRPPointAnnotation]()

        for (order, _, cityIndex, item) in orderedItems {
            guard let coordinate = item.coordinate else { continue }

            var annotation = TRPPointAnnotation()
            annotation.order = order
            annotation.lat = coordinate.lat
            annotation.lon = coordinate.lon
            annotation.poiId = item.itemId
            annotation.cityIndex = cityIndex  // Set city index for multi-city coloring
            annotation.isSelected = selectedMarkerPoiIds.contains(item.itemId)  // Set selection state
            annotations.append(annotation)
        }

        // Add all annotations as a single group
        map.addViewAnnotations(annotations, segmentId: "timeline_unified_annotations", annotationOrder: 0)
    }

    /// Add city marker annotations for multi-destination days
    /// Shows one marker per city instead of individual step markers
    private func addCityAnnotations() {
        guard let map = map else { return }

        let citiesWithCoords = viewModel.getCitiesWithCoordinatesForSelectedDay()
        var annotations = [TRPPointAnnotation]()

        for (city, coordinate) in citiesWithCoords {
            var annotation = TRPPointAnnotation()
            annotation.isCityMarker = true
            annotation.cityId = "\(city.id)"
            annotation.lat = coordinate.lat
            annotation.lon = coordinate.lon
            annotations.append(annotation)
        }

        map.addCityAnnotations(annotations, segmentId: "timeline_city_markers")
    }

    /// Add only the selected step marker (used in multi-city mode)
    /// Shows the selected step alongside city markers
    private func addSelectedStepAnnotation(orderedItems: [(order: Int, section: Int, cityIndex: Int, item: MapDisplayItem)]) {
        guard let map = map else { return }
        guard let selectedId = selectedMarkerPoiIds.first else { return }

        // Find the selected item
        guard let selectedItem = orderedItems.first(where: { $0.item.itemId == selectedId }) else { return }
        guard let coordinate = selectedItem.item.coordinate else { return }

        // Create annotation for selected step
        var annotation = TRPPointAnnotation()
        annotation.order = selectedItem.order
        annotation.lat = coordinate.lat
        annotation.lon = coordinate.lon
        annotation.poiId = selectedItem.item.itemId
        annotation.cityIndex = selectedItem.cityIndex
        annotation.isSelected = true  // Always selected

        // Add with separate segmentId to manage independently
        map.addViewAnnotations([annotation], segmentId: "timeline_selected_step", annotationOrder: 0)
    }

    /// Update selected marker and refresh map annotations
    /// Only one marker can be selected at a time across the entire map
    internal func updateSelectedMarker(poiId: String?) {
        guard let poiId = poiId else { return }

        // Clear all previous selections (single selection mode)
        selectedMarkerPoiIds.removeAll()

        // Add new selection
        selectedMarkerPoiIds.insert(poiId)

        // Refresh annotations to show updated selection state
        guard map != nil else { return }

        let orderedItems = viewModel.getOrderedItemsForMap()

        if viewModel.hasMultipleCities() && !isShowingStepMarkersInMultiCity {
            // Multi-city (city markers mode): Only update selected step marker, keep city markers
            map?.cleanAnnotationList(for: "timeline_selected_step")
            addSelectedStepAnnotation(orderedItems: orderedItems)
        } else {
            // Single city OR multi-city zoomed in (step markers mode): Update all step markers
            clearMapAnnotations()
            addAnnotationsForOrderedItems(orderedItems)
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
                annotation.imageName = TRPAppearanceSettings.MapAnnotations.getIcon(tag: poi.icon ?? "", type: .route)
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
            annotation.imageName = TRPAppearanceSettings.MapAnnotations.getIcon(tag: poi.icon ?? "", type: .route)
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
        // Toggle collection view visibility on map tap
        toggleCollectionView()
    }

    public func mapView(annotationPressed poiId: String, type: TRPAnnotationType) {
        // Find the index and coordinate of the item in mapDisplayItems
        var itemIndex: Int?
        var itemCoordinate: TRPLocation?

        for (index, (_, _, _, item)) in mapDisplayItems.enumerated() {
            if item.itemId == poiId {
                itemIndex = index
                itemCoordinate = item.coordinate
                break
            }
        }

        // Update selected marker appearance
        updateSelectedMarker(poiId: poiId)

        // Zoom to marker (like collection view selection)
        if let coordinate = itemCoordinate {
            map?.setCenter(coordinate, zoomLevel: 15)
        }

        // Expand the collection view and scroll to the item
        if let index = itemIndex {
            let indexPath = IndexPath(item: index, section: 0)

            // Mark as focused for Main View button
            isMarkerFocused = true
            updateMainViewButtonVisibility()

            expandCollectionView {
                // Scroll to the item after expansion animation completes
                DispatchQueue.main.async {
                    self.poiPreviewCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                    // Reload to update badge styles
                    self.poiPreviewCollectionView.reloadData()
                }
            }
        }
    }
    
    public func mapView(clickedLocation: TRPLocation) {
        // Toggle is handled by mapViewCloseAnnotation
    }
    
    public func mapView(_ mapView: TRPMapView, regionDidChangeAnimated animated: Bool) {
        // Collapse collection view when user moves the map
        collapseCollectionView()
    }

    public func mapViewChangedZoomLevel(_ mapView: TRPMapView, zoomLevel: CGFloat) {
        // Only handle zoom-based marker switching in multi-city mode
        guard viewModel.hasMultipleCities() else { return }

        let shouldShowStepMarkers = zoomLevel > multiCityZoomThreshold

        // Only update if state changed
        guard shouldShowStepMarkers != isShowingStepMarkersInMultiCity else { return }

        isShowingStepMarkersInMultiCity = shouldShowStepMarkers

        let orderedItems = viewModel.getOrderedItemsForMap()

        if shouldShowStepMarkers {
            // Zoomed in: Switch to step markers
            clearMapAnnotations()
            addAnnotationsForOrderedItems(orderedItems)

            // Show Main View button
            isMarkerFocused = true
            updateMainViewButtonVisibility()
        } else {
            // Zoomed out: Switch back to city markers + selected step
            clearMapAnnotations()
            addCityAnnotations()
            addSelectedStepAnnotation(orderedItems: orderedItems)

            // Hide Main View button (unless marker was manually focused)
            isMarkerFocused = false
            updateMainViewButtonVisibility()
        }
    }

    public func mapView(cityAnnotationPressed cityId: String) {
        // Find first step of this city to get its coordinate for zooming
        guard let firstIndex = mapDisplayItems.firstIndex(where: { (_, _, _, item) -> Bool in
            switch item {
            case .poi(_, let segment, _):
                return "\(segment.city?.id ?? 0)" == cityId
            case .activity(let segment):
                return "\(segment.city?.id ?? 0)" == cityId
            }
        }) else { return }

        let (_, _, _, item) = mapDisplayItems[firstIndex]

        // Zoom to city coordinate only — do NOT change selected step/marker
        if let coordinate = item.coordinate {
            map?.setCenter(coordinate, zoomLevel: 13)
        }

        // Mark as focused for Main View button
        isMarkerFocused = true
        updateMainViewButtonVisibility()
    }
}

// MARK: - Main View Button
extension TRPTimelineItineraryVC {

    /// Update Main View button visibility
    /// Shows when: map mode + multiple cities + marker is focused
    internal func updateMainViewButtonVisibility() {
        let shouldShow = isShowingMap && hasMultipleCitiesOnSelectedDay && isMarkerFocused
        if shouldShow {
            mainViewButton.showAnimated()
        } else {
            mainViewButton.hideAnimated()
        }
    }

    /// Called when Main View button is tapped - returns to overview zoom
    @objc internal func mainViewButtonTapped() {
        // Fit camera to show all markers
        fitCameraToAllMarkers()

        // Reset focus state
        isMarkerFocused = false
        isShowingStepMarkersInMultiCity = false
        updateMainViewButtonVisibility()

        let orderedItems = viewModel.getOrderedItemsForMap()

        // Refresh annotations based on multi-city state
        // Keep the current selection - don't reset selectedMarkerPoiIds
        clearMapAnnotations()
        if viewModel.hasMultipleCities() {
            // Multi-city: Show city markers + selected step marker
            addCityAnnotations()
            addSelectedStepAnnotation(orderedItems: orderedItems)
        } else {
            // Single city: Show step markers
            addAnnotationsForOrderedItems(orderedItems)
        }

        // Refresh collection view badges
        poiPreviewCollectionView.reloadData()

        // Collapse collection view
        collapseCollectionView()
    }

    /// Fit camera to show all markers on the map
    private func fitCameraToAllMarkers() {
        guard let map = map else { return }

        let allCoordinates = mapDisplayItems.compactMap { item -> CLLocationCoordinate2D? in
            guard let coordinate = item.item.coordinate else { return nil }
            return CLLocationCoordinate2D(latitude: coordinate.lat, longitude: coordinate.lon)
        }

        guard !allCoordinates.isEmpty else { return }
        map.fitCamera(to: allCoordinates)
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

