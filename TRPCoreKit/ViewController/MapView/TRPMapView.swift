//
//  TRPMapView.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 3.08.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import UIKit
import MapboxMaps
import MapboxDirections
import TRPFoundationKit


public class TRPMapView: UIView {
    private var cancelables = Set<AnyCancelable>()
    private var locationTrackingCancellation: AnyCancelable?
    
    public enum StyleAnnotatoin: String {
        case alternativePois = "alternativePoisAnnotation"
        case searchThisAreaPois = "searchThisAreaPoisAnnotation"
        case runTimeRoutePoi = "runTimeRoutePoiAnnotation"
        case nexusTours = "nexusToursAnnotation"
    }
    
    public enum DrawRouteStyle: String {
        case rota = "rotaRouting"
        case runtime = "runtimeRouting"
        
        func getColor() -> UIColor {
            switch self {
            case .rota:
                return UIColor(red: 62/255, green: 147/255, blue: 254/255, alpha: 1)
            case .runtime:
                return TRPColor.pink
            }
        }
    }
    
    enum DrawStyle {
        case line, dotted
    }
    
    private var drawStyle: DrawStyle = .dotted
    private var mapView: MapView?;
    private var startLocation: CLLocationCoordinate2D?
    
    fileprivate var isImagesAdded = false
//    fileprivate var pointsSource: MGLShapeSource?
    public weak var delegate: TRPMapViewDelegate?
    public var clickableLayerTags = [String]()
    private var startZoomLevel: Double = 12
    private var viewDidLoad = false
    
    private var addedAnnotations = [String: [ViewAnnotation]]()
    private var addedRoutes = [String: [Route]]()
    
    
    private var didMapLoaded: Bool = false {
        didSet {
            runMap()
        }
    }
    
//    fileprivate var runTimeRoute: CustomPolyLine?
    
    public var showUserLocation: Bool = true{
        didSet {
            mapView?.location.options.puckType = showUserLocation ? .puck2D() : nil
            mapView?.location.options.puckBearingEnabled = showUserLocation
        }
    }
    
    public var userLocation: TRPLocation? {
        get {
            guard let center = mapView?.mapboxMap.cameraState.center else {
                return TRPLocation(lat: 0, lon: 0)
            }
            return TRPLocation(lat: center.latitude, lon: center.longitude)
        }
    }
    
    public var centerCoordinate: TRPLocation {
        get {
            guard let center = mapView?.mapboxMap.cameraState.center else {
                return TRPLocation(lat: 0, lon: 0)
            }
            return TRPLocation(lat: center.latitude, lon: center.longitude)
        }
    }
    
    public var visibleCoordinateBounds: (nE: TRPLocation, sW: TRPLocation)? {
        guard let mapView = mapView else { return nil }
        let bounds = mapView.mapboxMap.coordinateBounds(for: mapView.bounds)
        let ne = TRPLocation(lat: bounds.northeast.latitude, lon: bounds.northeast.longitude)
        let sw = TRPLocation(lat: bounds.southwest.latitude, lon: bounds.southwest.longitude)
        
        return (nE: ne, sW: sw)
    }
    
    public var zoomLevel: Double {
        get {return Double(mapView?.mapboxMap.cameraState.zoom ?? 0)}
    }
    
    public var showRadius: Double {
        get {
            guard let mapView = mapView else {return 3}
            let bounds = mapView.mapboxMap.coordinateBounds(for: mapView.bounds)
            let currentLocation = CLLocation(latitude: mapView.mapboxMap.cameraState.center.latitude,
                                             longitude: mapView.mapboxMap.cameraState.center.longitude)
            let neLocation = CLLocation(latitude: bounds.northeast.latitude,
                                      longitude: bounds.northeast.longitude)
            return neLocation.distance(from: currentLocation) / 1000
        }
    }
    
    
    init(frame: CGRect, startLocation: LocationCoordinate? = nil, zoomLevel: Double? = nil) {
        if let sL = startLocation {
            self.startLocation = CLLocationCoordinate2D(latitude: sL.lat, longitude: sL.lon)
        }
        if let zoom = zoomLevel {
            startZoomLevel = zoom
        }
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func layoutSubviews() {
        if viewDidLoad == true {return}
        viewDidLoad = true
        setupMapView()
    }
    
    // Add Route Annotations with order Label (Kullancının gideceği mekanların olduğu)
    public func addViewAnnotations(_ annotations: [TRPPointAnnotation], annotationOrder: Int = 0) -> [ViewAnnotation] {
        
        let viewAnnotations = annotations.map { $0.asViewAnnotation(annotationOrder: annotationOrder, tapHandler: { [weak self, placeId = $0.poiId] _ in
            if let placeId = placeId {
                self?.delegate?.mapView(annotationPressed: placeId, type: .styleAnnotation)
            }
        })}
        addAnnotationToMap(viewAnnotations)
        return viewAnnotations
    }
    
    private func addAnnotationToMap(_ viewAnnotations: [ViewAnnotation]) {
        viewAnnotations.forEach {
            mapView?.viewAnnotations.add($0)
        }
    }
    
    // Add Route Annotations with order Label (Kullancının gideceği mekanların olduğu)
    public func addViewAnnotations(_ annotations: [TRPPointAnnotation], segmentId: String, annotationOrder: Int){
        let viewAnnotations = self.addViewAnnotations(annotations, annotationOrder: annotationOrder)
        addedAnnotations[segmentId] = viewAnnotations
    }
    
    public func cleanAllAnnotations() {
        addedAnnotations.removeAll()
        clearViewAnnotation()
        addedRoutes.keys.forEach { removeRoute(segmentId: $0) }
        addedRoutes.removeAll()
    }
    
    public func cleanAnnotationList(for segmentId: String) {
        addedAnnotations.removeValue(forKey: segmentId)
        clearViewAnnotation()
        // Yeniden ekle
        for annos in addedAnnotations.values {
            addAnnotationToMap(annos)
        }
        
        removeRoute(segmentId: segmentId)
    }

    public func clearViewAnnotation()  {
        mapView?.viewAnnotations.removeAll()
    }
    
    public func showHideMapLayers(isShow: Bool)  {
        mapView?.viewAnnotations.allAnnotations.forEach { anno in
            anno.visible = isShow
        }
        do {
            try addedRoutes.keys.forEach { key in
                try mapView?.mapboxMap.updateLayer(withId: key + "_line", type: LineLayer.self) { layer in
                    layer.visibility = .constant(isShow ? .visible : .none)
                }
            }
          // Where LAYER_ID is the layer ID for an existing layer
            try mapView?.mapboxMap.updateLayer(withId: TRPMapView.DrawRouteStyle.runtime.rawValue, type: LineLayer.self) { layer in
                layer.visibility = .constant(isShow ? .visible : .none)
            }
            try mapView?.mapboxMap.updateLayer(withId: TRPMapView.DrawRouteStyle.rota.rawValue, type: LineLayer.self) { layer in
                layer.visibility = .constant(isShow ? .visible : .none)
            }
        } catch {
          print("Failed to hide layer due to error: (error)")
        }
    }
    
    private func runMap() {
        addSyleImages()
    }
    
    public func getVisibleCoordBounds() -> (LocationCoordinate, LocationCoordinate)? {
        guard let mapView = mapView else { return nil }
        let bounds = mapView.mapboxMap.coordinateBounds(for: mapView.bounds)
        let ne = LocationCoordinate(bounds.northeast.latitude, bounds.northeast.longitude)
        let sw = LocationCoordinate(bounds.southwest.latitude, bounds.southwest.longitude)
        return (ne, sw)
    }
    
    public func setTrackingMode(_ mode: TRPUserTrackingMode, animated:Bool) {
        guard let mapView = mapView else {return}
        switch mode {
        case .none:
            locationTrackingCancellation = nil
            break
        case .follow, .followWithCourse, .followWithHeading:
            locationTrackingCancellation = mapView.location.onLocationChange.observe { [weak mapView] newLocation in
                guard let location = newLocation.last, let mapView else { return }
                mapView.camera.ease(
                    to: CameraOptions(center: location.coordinate, zoom: 12),
                    duration: 1.3)
            }
            break
        }
    }
    
    public func setCenter(_ location: TRPLocation, zoomLevel: Double? = nil){
        guard let mapView = mapView else { return }
        if let zoom = zoomLevel {
            mapView.setMapCenter(latitude: location.lat, longitude: location.lon, zoomLevel: zoom)
        }
    }
    
    public func setZoomLevel(_ zoomLevel: Double) {
        if let map = mapView {
            map.camera.ease(to: CameraOptions(zoom: zoomLevel), duration: 0)
        }
    }
    
    deinit {
        Log.deInitialize()
    }
}


// MARK: - MapBox settings
extension TRPMapView {
    
    //Setup Map View
    func setupMapView() {
        let camera = CameraOptions(center: startLocation, zoom: startZoomLevel)
        
        // Use light style for white/light roads
        let styleURI = StyleURI.streets
        let options = MapInitOptions(cameraOptions: camera, styleURI: styleURI)
        
        mapView = MapView(frame: self.bounds, mapInitOptions: options)
        
        guard let mapView = mapView else { return }
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        mapView.camera.ease(to: camera, duration: 0)
        
        mapView.location.options.puckType = .puck2D()
        mapView.location.options.puckBearingEnabled = true
        
        // Hide Mapbox attribution, logo, and scale bar by moving them off screen
        mapView.ornaments.options.logo.margins = CGPoint(x: -1000, y: -1000)
        mapView.ornaments.options.attributionButton.margins = CGPoint(x: -1000, y: -1000)
        mapView.ornaments.options.scaleBar.visibility = .hidden
        
        // Setup delegates and gestures
        mapView.gestures.delegate = self
        mapView.mapboxMap.onMapLoaded.observeNext {  [weak self] _ in
            self?.didMapLoaded = true
        }.store(in: &cancelables)
        
        addClickPropetyForAnnotations()
        addSubview(mapView)
    }
    
    /// Tüm maps üzerine clickable yapı haline getirir.
    /// Style ikonlarının İDlerini almak için kullanılır.
    private func addClickPropetyForAnnotations() {
        guard let mapView =  mapView else {return}
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(sender:)))
        //FİXME: MAP E İKİ KERE TIKLAYIP ANNOTATİON IN KAPATILMA NEDENİ BURASI.
        for recognizer in mapView.gestureRecognizers! where recognizer is UITapGestureRecognizer {
            //singleTap.require(toFail: recognizer)
        }
        mapView.addGestureRecognizer(singleTap)
    }
    
    @objc fileprivate func handleMapTap(sender: UITapGestureRecognizer) {
        delegate?.mapViewCloseAnnotation(self)
        guard let mapView = mapView else {return}
        let coordinate = mapView.mapboxMap.coordinate(for: sender.location(in: mapView))
        delegate?.mapView(clickedLocation: TRPLocation(lat: coordinate.latitude, lon: coordinate.longitude))
    }
}

extension TRPMapView: GestureManagerDelegate {
    public func gestureManager(_ gestureManager: MapboxMaps.GestureManager, didBegin gestureType: MapboxMaps.GestureType) {
        
    }
    
    public func gestureManager(_ gestureManager: MapboxMaps.GestureManager, didEndAnimatingFor gestureType: MapboxMaps.GestureType) {
        if gestureType == .pan {
            delegate?.mapView(self, regionDidChangeAnimated: true)
        }
    }
    
    public func gestureManager(_ gestureManager: MapboxMaps.GestureManager, didEnd gestureType: MapboxMaps.GestureType, willAnimate: Bool) {
        
    }
}

//Load Style
extension TRPMapView {
    
    //To add Image on mapview
    fileprivate func addSyleImages() {
        if isImagesAdded == true {return}
        for image in delegate?.mapViewImagesForFilteringLayers(self) ?? [] {
            try? mapView?.mapboxMap.addImage(image.uiImage, id: image.tag)
        }
        isImagesAdded = true
    }
    
}

// MARK: Layer
extension TRPMapView {
    
    /// Alternatif mekanların olduğu Annotaoinlardır
    /// Kücük yuvarlark STYLE POINT ekler.
    /// Her ekleme işlemince eski POINT ler silinir.
    /// Her point in tıklandığında ID sini dondururlur
    /// - Parameter points: Eklenecek Pointlerini ozelliklerini dizisi
    public func addPointsForAlternative(_ points: [TRPPointAnnotationFeature],
                                        styleAnnotation: StyleAnnotatoin,
                                        clickable: Bool = true) {
        if clickable {
            clickableLayerTags.append(styleAnnotation.rawValue)
        }
        addItemsToMap(features: points, sourseIdentifier: styleAnnotation.rawValue)
    }
    
    public func removePointsForAlternative(styleAnnotation: StyleAnnotatoin) {
        guard let mapView = mapView else {return}
        do {
            try mapView.mapboxMap.removeLayer(withId: styleAnnotation.rawValue)
        } catch {
            Log.e("Failed to remove layer due to error: (error)")
        }
    }
    
    private func addItemsToMap(features: [TRPPointAnnotationFeature], sourseIdentifier sourceId: String) {
        guard let mapView = mapView else { return }
        
        let featureList = features.map { feature -> Feature in
            let properties = ["image": feature.iconType,
                              "placeId": feature.id,
                              "title": feature.name]
            var feature = Feature(geometry: .point(Point(CLLocationCoordinate2D(latitude: feature.lat, longitude: feature.lon))))
            feature.properties = JSONObject(rawValue: properties)
            return feature
        }
        
        let featureCollection = FeatureCollection(features: featureList)
        
        if isMapSourceExist(id: sourceId) {
            mapView.mapboxMap.updateGeoJSONSource(withId: sourceId, geoJSON: .featureCollection(featureCollection))
        } else {
            var source = GeoJSONSource(id: sourceId)
            source.data = .featureCollection(featureCollection)
            try? mapView.mapboxMap.addSource(source)
            
            var layer = SymbolLayer(id: sourceId, source: sourceId)
            layer.iconImage = .expression(
                Exp(.get) { "image" }
            )
            layer.iconAllowOverlap = .constant(true)
            try? mapView.mapboxMap.addLayer(layer)
            mapView.gestures.onLayerTap(layer.id) { [weak self] queriedFeature, _ in
                if let selectedFeatureProperties = queriedFeature.feature.properties?.dictionary, let placeId = selectedFeatureProperties["placeId"] as? String {
                    self?.delegate?.mapView(annotationPressed: placeId, type: .styleAnnotation)
                    return true
                }
                return false
            }.store(in: &cancelables)
        }
    }
    
    
}

// MARK: calculateRoute
extension TRPMapView {
    
    public func drawRoute(_ route: Route, style: DrawRouteStyle? = nil, segmentId: String? = nil, segmentOrder: Int = 0) {
        guard let routeCoordinates = route.shape?.coordinates, routeCoordinates.count > 0 else {
            return
        }
        
        if let style {
            drawRouteDottedLine(route, tag: style.rawValue, color: style.getColor())
        }
        if let segmentId {
            var routes = [route]
            if let addedRoute = addedRoutes[segmentId] {
                routes.append(contentsOf: addedRoute)
            }
            
            addedRoutes[segmentId] = routes
            
            if routes.count > 1 {
                
            }
            drawRouteDottedLine(route, tag: segmentId + "_line", color: ColorSet.getMapColor(segmentOrder))
        }
        
        let referenceCamera = CameraOptions(zoom: zoomLevel, bearing: 0)
        
        // Fit camera to the given coordinates.
        if let camera = try? mapView?.mapboxMap.camera(
            for: routeCoordinates,
            camera: referenceCamera,
            coordinatesPadding: .zero,
            maxZoom: nil,
            offset: nil) {
            mapView?.mapboxMap.setCamera(to: camera)
        }
    }
    
    public func removeRoute(style: DrawRouteStyle) {
        if isMapSourceExist(id: style.rawValue) {
            try? mapView?.mapboxMap.removeSource(withId: style.rawValue)
        }
    }
    
    public func removeRoute(segmentId: String) {
        let id = segmentId + "_line"
        let layersUsingSource = mapView?.mapboxMap.allLayerIdentifiers
            .filter { $0.id == id }
            .map { $0.id } ?? []
        // Remove top-most first to avoid dependency complaints
        for id in layersUsingSource.reversed() {
            do { try mapView?.mapboxMap?.removeLayer(withId: id) }
            catch { print("Could not remove layer \(id): \(error)") }
        }
        if isMapSourceExist(id: id) {
            try? mapView?.mapboxMap.removeSource(withId: id)
            //            try? mapView?.mapboxMap?.removeLayer(withId: id)
        }
    }
    
    private func isMapSourceExist(id: String) -> Bool {
        return (mapView?.mapboxMap.sourceExists(withId: id)) ?? false
    }
    
    private func drawRouteDottedLine(_ route: Route, tag: String, color: UIColor = UIColor.blue) {
        
        guard let mapView = mapView else { return }
        guard route.legs.count > 0 else {return}
        guard let routeCoordinates = route.shape?.coordinates, routeCoordinates.count > 0 else {return}
        
        let lineString = LineString(routeCoordinates.compactMap({$0}))
        let geoJsonObject: GeoJSONObject = .feature(Feature(geometry: lineString))
        if isMapSourceExist(id: tag) {
            mapView.mapboxMap.updateGeoJSONSource(withId: tag, geoJSON: geoJsonObject)
        } else {
            
            var source = GeoJSONSource(id: tag)
            source.data = .feature(Feature(geometry: lineString))
            try? mapView.mapboxMap.addSource(source)
            
            var layer = LineLayer(id: tag, source: source.id)
            layer.lineJoin = .constant(.round)
            layer.lineCap = .constant(.round)
            layer.lineColor = .constant(StyleColor(color))
            layer.lineWidth = .constant(4)
            layer.lineDasharray = .constant([1, 2.0])
            try? mapView.mapboxMap.addLayer(layer)
        }
        
    }
}


extension MapView {
    func setMapCenter(latitude: Double, longitude: Double, zoomLevel: Double? = nil) {
        if let zoom = zoomLevel {
            camera.ease(to: CameraOptions(center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), zoom: zoom), duration: 0)
        }
    }
}
