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

        hasLoadedInitialMapData = false

        let centerLocation = getMapCenterLocation()
        let startLocation = LocationCoordinate(lat: centerLocation.lat, lon: centerLocation.lon)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.mapContainerView.layoutIfNeeded()
            
            self.map = TRPMapView(
                frame: self.mapContainerView.bounds,
                startLocation: startLocation,
                zoomLevel: 12
            )
            
            if let map = self.map {
                map.translatesAutoresizingMaskIntoConstraints = false
                self.mapContainerView.addSubview(map)

                NSLayoutConstraint.activate([
                    map.topAnchor.constraint(equalTo: self.mapContainerView.topAnchor),
                    map.leadingAnchor.constraint(equalTo: self.mapContainerView.leadingAnchor),
                    map.trailingAnchor.constraint(equalTo: self.mapContainerView.trailingAnchor),
                    map.bottomAnchor.constraint(equalTo: self.mapContainerView.bottomAnchor)
                ])
                
                map.delegate = self
                map.showUserLocation = true

                // Fallback in case mapViewDidFinishLoading doesn't fire.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                    guard let self = self else { return }
                    if self.map != nil && !self.mapContainerView.isHidden && !self.hasLoadedInitialMapData {
                        self.loadMapData()
                    }
                }
            }
        }
    }
    
    private func getMapCenterLocation() -> TRPLocation {
        if let coordinate = viewModel.getPreferredCityCoordinate() {
            return coordinate
        }

        return TRPLocation(lat: 41.9028, lon: 12.4964) // Rome as default
    }
    
    internal func loadMapData() {
        guard let map = map else {
            return
        }

        let orderedItems = viewModel.getOrderedItemsForMap()

        hasLoadedInitialMapData = true

        if orderedItems.isEmpty {
            let centerLocation = getMapCenterLocation()
            map.setCenter(centerLocation, zoomLevel: 12)
            removeAllRoutesFromMap()
            selectedMarkerPoiIds.removeAll()
            return
        }

        isShowingStepMarkersInMultiCity = false

        if viewModel.hasMultipleCities() {
            selectedMarkerPoiIds.removeAll()

            if let firstItem = orderedItems.first {
                selectedMarkerPoiIds.insert(firstItem.item.itemId)
            }

            addCityAnnotations()

            addSelectedStepAnnotation(orderedItems: orderedItems)
        } else {
            if let firstItem = orderedItems.first {
                selectedMarkerPoiIds.removeAll()
                selectedMarkerPoiIds.insert(firstItem.item.itemId)
            }

            addAnnotationsForOrderedItems(orderedItems)
        }

        poiPreviewCollectionView.reloadData()

        // Open the map zoomed out with markers centered — cap the zoom so a tightly
        // clustered single-city day doesn't snap in close on first load.
        let fitCoordinates: [CLLocationCoordinate2D]
        if viewModel.hasMultipleCities() {
            // Frame the city markers themselves so every city is on-screen at the overview —
            // including cities whose steps are all no-location (no step coordinate to fit to).
            fitCoordinates = viewModel.getCitiesWithCoordinatesForSelectedDay().map {
                CLLocationCoordinate2D(latitude: $0.coordinate.lat, longitude: $0.coordinate.lon)
            }
        } else {
            fitCoordinates = orderedItems.compactMap { item -> CLLocationCoordinate2D? in
                guard let coordinate = item.item.coordinate else { return nil }
                return CLLocationCoordinate2D(latitude: coordinate.lat, longitude: coordinate.lon)
            }
        }
        // Multi-city opens to the all-cities overview: jump (no ease) so the camera
        // doesn't animate down through the city-marker zoom band and flicker markers.
        map.fitCamera(to: fitCoordinates, maxZoom: 12, animated: !viewModel.hasMultipleCities())

        drawRoutesForSelectedDay()
    }

    /// Routes the day's located items in display order, one route per city, and draws the legs
    /// (walking dashed, driving solid) in the route blue. Only when the host draws routes.
    internal func drawRoutesForSelectedDay() {
        removeAllRoutesFromMap()
        guard TRPCoreKit.shared.provider.drawsRoutesOnMap else { return }

        if viewModel.usesFlatTimeline {
            for entry in viewModel.flatMapRouteLegs() {
                map?.drawRouteLegs(entry.legs, segmentId: entry.segmentId, color: TRPMapView.DrawRouteStyle.rota.getColor())
            }
            return
        }

        let groups = viewModel.getRouteGroupsForMap()
        guard !groups.isEmpty else { return }

        mapRouteGeneration += 1
        let generation = mapRouteGeneration
        var remaining = groups.count
        showLoader(true)

        for group in groups {
            viewModel.calculateStepRoutes(for: group.locations) { [weak self] routes in
                guard let self = self, generation == self.mapRouteGeneration else { return }

                if let routes = routes {
                    let legs = routes.map { TRPMapRouteLeg(coordinates: $0.shape, isWalking: $0.isWalking) }
                    self.map?.drawRouteLegs(legs, segmentId: "timeline_city_\(group.cityIndex)", color: TRPMapView.DrawRouteStyle.rota.getColor())
                }

                remaining -= 1
                if remaining == 0 {
                    self.showLoader(false)
                }
            }
        }
    }

    internal func addAnnotationsForOrderedItems(_ orderedItems: [(order: Int, section: Int, cityIndex: Int, item: MapDisplayItem)]) {
        guard let map = map else { return }

        var annotations = [TRPPointAnnotation]()

        for (order, _, cityIndex, item) in orderedItems {
            // Skip no-location items — their coordinate is a city-center fallback.
            if item.isNoLocation { continue }
            guard let coordinate = item.coordinate else { continue }

            var annotation = TRPPointAnnotation()
            annotation.order = order
            annotation.lat = coordinate.lat
            annotation.lon = coordinate.lon
            annotation.poiId = item.itemId
            annotation.cityIndex = cityIndex
            annotation.isSelected = selectedMarkerPoiIds.contains(item.itemId)
            annotations.append(annotation)
        }

        map.addViewAnnotations(annotations, segmentId: "timeline_unified_annotations", annotationOrder: 0)
    }

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

    /// Add only the selected step marker (used in multi-city mode).
    private func addSelectedStepAnnotation(orderedItems: [(order: Int, section: Int, cityIndex: Int, item: MapDisplayItem)]) {
        guard let map = map else { return }
        guard let selectedId = selectedMarkerPoiIds.first else { return }

        guard let selectedItem = orderedItems.first(where: { $0.item.itemId == selectedId }) else { return }
        // No-location items never get a pin (their coordinate is the city fallback).
        if selectedItem.item.isNoLocation { return }
        guard let coordinate = selectedItem.item.coordinate else { return }

        var annotation = TRPPointAnnotation()
        annotation.order = selectedItem.order
        annotation.lat = coordinate.lat
        annotation.lon = coordinate.lon
        annotation.poiId = selectedItem.item.itemId
        annotation.cityIndex = selectedItem.cityIndex
        annotation.isSelected = true

        map.addViewAnnotations([annotation], segmentId: "timeline_selected_step", annotationOrder: 0)
    }

    internal func updateSelectedMarker(poiId: String?) {
        guard let poiId = poiId else { return }

        selectedMarkerPoiIds.removeAll()

        selectedMarkerPoiIds.insert(poiId)

        guard map != nil else { return }

        let orderedItems = viewModel.getOrderedItemsForMap()

        if viewModel.hasMultipleCities() && !isShowingStepMarkersInMultiCity {
            map?.cleanAnnotationList(for: "timeline_selected_step")
            addSelectedStepAnnotation(orderedItems: orderedItems)
        } else {
            clearMapAnnotations()
            addAnnotationsForOrderedItems(orderedItems)
        }
    }
    
    private func addAnnotationsForSegments(_ segments: [[TRPPoi]]) {
        guard let map = map else { return }

        // annotationOrder (segment index) drives the badge background color; order is the POI index within the segment.
        for (segmentIndex, pois) in segments.enumerated() {
            var annotations = [TRPPointAnnotation]()

            for (poiIndex, poi) in pois.enumerated() {
                guard let coordinate = poi.coordinate else { continue }

                var annotation = TRPPointAnnotation()
                annotation.imageName = TRPAppearanceSettings.MapAnnotations.getIcon(tag: poi.icon ?? "", type: .route)
                annotation.order = poiIndex + 1
                annotation.lat = coordinate.lat
                annotation.lon = coordinate.lon
                annotation.poiId = poi.id
                annotation.isOffer = !poi.offers.isEmpty
                annotations.append(annotation)
            }

            let segmentId = "timeline_segment_\(segmentIndex)_annotations"
            map.addViewAnnotations(annotations, segmentId: segmentId, annotationOrder: segmentIndex)

        }
    }
    
    private func addBookedActivityAnnotations(_ bookedActivities: [TRPTimelineSegment]) {
        guard let map = map else { return }
        
        var annotations = [TRPPointAnnotation]()
        
        for activity in bookedActivities {
            let coordinate = activity.additionalData?.coordinate ?? activity.coordinate
            guard let lat = coordinate?.lat, let lon = coordinate?.lon else { continue }

            var annotation = TRPPointAnnotation()
            annotation.imageName = "ic_booked_activity"
            annotation.order = -1 // no order label shown
            annotation.lat = lat
            annotation.lon = lon
            annotation.poiId = activity.additionalData?.activityId ?? ""
            annotation.isOffer = false
            annotations.append(annotation)
        }
        
        if !annotations.isEmpty {
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

            DispatchQueue.main.async {
                self.showLoader(false)
            }

            if let error = error {
                DispatchQueue.main.async {
                    self.removeRouteFromMap()

                    let errorMessage = TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.map.routeError")
                    EvrAlertView.showAlert(contentText: errorMessage.isEmpty ? "Unable to calculate route" : errorMessage,
                                          type: .error,
                                          bottomSpace: 80)
                }
                return
            }

            guard let route = route else {
                DispatchQueue.main.async {
                    self.removeRouteFromMap()

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
    
    internal func clearMapAnnotations() {
        guard let map = map else {
            return
        }

        map.clearViewAnnotation()

        for segmentIndex in 0..<10 {
            let segmentId = "timeline_segment_\(segmentIndex)_annotations"
        }
    }
    
    internal func removeRouteFromMap() {
        guard let map = map else { return }
        map.removeRoute(style: .rota)
    }
    
    internal func removeAllRoutesFromMap() {
        guard let map = map else { return }

        map.removeRoute(style: .rota)
        map.removeAllRouteLegs()
    }

    internal func refreshMap() {
        guard let map = map else {
            return
        }

        clearMapAnnotations()
        removeAllRoutesFromMap()

        loadMapData()
    }
}

// MARK: - TRPMapViewDelegate
extension TRPTimelineItineraryVC: TRPMapViewDelegate {
    public func mapViewDidFinishLoading(_ mapView: TRPMapView) {
        loadMapData()
    }

    public func mapViewCloseAnnotation(_ mapView: TRPMapView) {
        toggleCollectionView()
    }

    public func mapView(annotationPressed poiId: String, type: TRPAnnotationType) {
        var itemIndex: Int?
        var itemCoordinate: TRPLocation?

        for (index, (_, _, _, item)) in mapDisplayItems.enumerated() {
            if item.itemId == poiId {
                itemIndex = index
                itemCoordinate = item.coordinate
                break
            }
        }

        updateSelectedMarker(poiId: poiId)

        if let coordinate = itemCoordinate {
            map?.setCenter(coordinate, zoomLevel: 15)
        }

        if let index = itemIndex {
            let indexPath = IndexPath(item: index, section: 0)

            updateMainViewButtonVisibility()

            expandCollectionView {
                DispatchQueue.main.async {
                    self.poiPreviewCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                    self.poiPreviewCollectionView.reloadData()
                }
            }
        }
    }

    public func mapView(clickedLocation: TRPLocation) {
    }

    public func mapView(_ mapView: TRPMapView, regionDidChangeAnimated animated: Bool) {
        collapseCollectionView()
    }

    public func mapViewChangedZoomLevel(_ mapView: TRPMapView, zoomLevel: CGFloat) {
        guard viewModel.hasMultipleCities() else { return }

        let shouldShowStepMarkers = zoomLevel > multiCityZoomThreshold

        guard shouldShowStepMarkers != isShowingStepMarkersInMultiCity else { return }

        isShowingStepMarkersInMultiCity = shouldShowStepMarkers

        let orderedItems = viewModel.getOrderedItemsForMap()

        if shouldShowStepMarkers {
            clearMapAnnotations()
            addAnnotationsForOrderedItems(orderedItems)

            updateMainViewButtonVisibility()
        } else {
            clearMapAnnotations()
            addCityAnnotations()
            addSelectedStepAnnotation(orderedItems: orderedItems)

            updateMainViewButtonVisibility()
        }
    }

    public func mapView(cityAnnotationPressed cityId: String) {
        // Swap to step markers immediately rather than waiting on the async camera
        // callback — that callback no-ops at the exact threshold and can lag the tap.
        if viewModel.hasMultipleCities() && !isShowingStepMarkersInMultiCity {
            isShowingStepMarkersInMultiCity = true
            clearMapAnnotations()
            addAnnotationsForOrderedItems(viewModel.getOrderedItemsForMap())
        }

        // Frame ALL of the tapped city's steps (same as a single-city open) instead of
        // snapping the camera onto the first step. Skip no-location items — their
        // coordinate is just a city-center fallback.
        let cityCoordinates: [CLLocationCoordinate2D] = mapDisplayItems.compactMap { (_, _, _, item) in
            let belongsToCity: Bool
            switch item {
            case .poi(_, let segment, _):
                belongsToCity = "\(segment.city?.id ?? 0)" == cityId
            case .activity(let segment):
                belongsToCity = "\(segment.city?.id ?? 0)" == cityId
            }
            guard belongsToCity, !item.isNoLocation, let coordinate = item.coordinate else { return nil }
            return CLLocationCoordinate2D(latitude: coordinate.lat, longitude: coordinate.lon)
        }

        if !cityCoordinates.isEmpty {
            // animated: false → jump instead of easing through the city-marker zoom band.
            // The fit lands well above `multiCityZoomThreshold`, so the step markers stay up.
            map?.fitCamera(to: cityCoordinates, maxZoom: 12, animated: false)
        } else if let cityCoordinate = viewModel.getCitiesWithCoordinatesForSelectedDay()
            .first(where: { "\($0.city.id)" == cityId })?.coordinate {
            // No real pins for this city (all no-location) — just center on it above the threshold.
            map?.setCenter(cityCoordinate, zoomLevel: Double(multiCityZoomThreshold) + 1)
        }

        updateMainViewButtonVisibility()
    }
}

// MARK: - Main View Button
extension TRPTimelineItineraryVC {

    /// Shows whenever the bottom POI list is visible in multi-city map mode.
    /// Tied to the bottom list — collapsing/hiding the list hides the button, showing the list shows it again.
    internal func updateMainViewButtonVisibility() {
        let shouldShow = isShowingMap && hasMultipleCitiesOnSelectedDay && isCollectionViewExpanded
        if shouldShow {
            mainViewButton.showAnimated()
        } else {
            mainViewButton.hideAnimated()
        }
    }

    @objc internal func mainViewButtonTapped() {
        fitCameraToAllMarkers()

        isShowingStepMarkersInMultiCity = false
        updateMainViewButtonVisibility()

        let orderedItems = viewModel.getOrderedItemsForMap()

        // Keep the current selection — don't reset selectedMarkerPoiIds.
        clearMapAnnotations()
        if viewModel.hasMultipleCities() {
            addCityAnnotations()
            addSelectedStepAnnotation(orderedItems: orderedItems)
        } else {
            addAnnotationsForOrderedItems(orderedItems)
        }

        poiPreviewCollectionView.reloadData()

        collapseCollectionView()
    }

    private func fitCameraToAllMarkers() {
        guard let map = map else { return }

        let allCoordinates = mapDisplayItems.compactMap { item -> CLLocationCoordinate2D? in
            guard let coordinate = item.item.coordinate else { return nil }
            return CLLocationCoordinate2D(latitude: coordinate.lat, longitude: coordinate.lon)
        }

        guard !allCoordinates.isEmpty else { return }
        // Jump (no ease): mainViewButtonTapped flips isShowingStepMarkersInMultiCity off
        // right after this call, so an animated descent through the threshold band would
        // briefly re-add step markers mid-flight and flicker.
        map.fitCamera(to: allCoordinates, animated: false)
    }
}

// MARK: - Map Helper
extension TRPTimelineItineraryVC {
    
    public func showPoisOnMap(_ pois: [TRPPoi]) {
        guard let map = map else {
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
    
    public func centerMap(on location: TRPLocation, zoomLevel: Double = 14) {
        guard let map = map else { return }
        map.setCenter(location, zoomLevel: zoomLevel)
    }
}

