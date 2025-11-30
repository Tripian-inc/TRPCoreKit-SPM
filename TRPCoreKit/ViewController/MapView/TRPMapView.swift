//
//  TRPMapView.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 3.08.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import UIKit
import Mapbox
import MapboxDirections
import TRPFoundationKit


public class TRPMapView: UIView {
    
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
    private var mapView: MGLMapView?;
    private var startLocation: CLLocationCoordinate2D?
    private var didMapLoaded: Bool = false {
        didSet {
            runMap()
        }
    }
    //private var rotaAnnotations = [TRPPointAnnotation]();
    fileprivate var runTimeRoute: CustomPolyLine?
    
    public var showUserLocation: Bool = true{
        didSet {
            mapView?.showsUserLocation = showUserLocation
        }
    }
    
    public var userLocation: TRPLocation? {
        get {
            guard let location = mapView?.userLocation else {
                return nil
            }
            return TRPLocation(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
        }
    }
    
    public var centerCoordinate: TRPLocation {
        get{return TRPLocation(lat: mapView?.centerCoordinate.latitude ?? 0, lon: mapView?.centerCoordinate.longitude ?? 0)}
    }
    
    public var visibleCoordinateBounds:  (nE:TRPLocation, sW: TRPLocation)? {
        guard let ne = mapView?.visibleCoordinateBounds.ne, let sw = mapView?.visibleCoordinateBounds.sw else {return nil}
        let northEast = TRPLocation(lat: ne.latitude, lon: ne.longitude)
        let southWest = TRPLocation(lat: sw.latitude, lon: sw.longitude)
        return (nE: northEast, sW: southWest)
    }
    
    
    public var zoomLevel: Double {
        get {return mapView?.zoomLevel ?? 0}
    }
    
    public var showRadius: Double {
        get {
            guard let mapView = mapView else {return 3}
            let currentLocation = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
            let neLocation = CLLocation(latitude: mapView.visibleCoordinateBounds.ne.latitude, longitude: mapView.visibleCoordinateBounds.ne.longitude)
            return neLocation.distance(from: currentLocation) / 1000
        }
    }
    
    fileprivate var isImagesAdded = false
    fileprivate var pointsSource: MGLShapeSource?
    public weak var delegate: TRPMapViewDelegate?
    public var clickableLayerTags = [String]()
    private var startZoomLevel: Double = 12
    private var viewDidLoad = false
    
    
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
    public func addAnnotations(_ annotations: [TRPPointAnnotation]){
        //rotaAnnotations.append(contentsOf: annotations)
        mapView?.addAnnotations(annotations)
    }
    
    
    //Remove all annotation on MapView
    public func clearAnnotation()  {
        if let annotations = mapView?.annotations {
            mapView?.removeAnnotations(annotations)
        }
    }
    
    private func runMap() {
        addSyleImages()
    }
    
    public func getVisibleCoordBounds() -> (LocationCoordinate, LocationCoordinate)? {
        guard let mapView = mapView else {return nil}
        let ne = LocationCoordinate(mapView.visibleCoordinateBounds.ne.latitude, mapView.visibleCoordinateBounds.ne.longitude)
        let sw = LocationCoordinate(mapView.visibleCoordinateBounds.sw.latitude, mapView.visibleCoordinateBounds.sw.longitude)
        return (ne,sw)
    }
    
    public func setTrackingMode(_ mode: TRPUserTrackingMode, animated:Bool) {
        guard let mapView = mapView else {return}
        var trackingMode = MGLUserTrackingMode.none
        switch mode {
        case .none:
            trackingMode = .none
            break
        case .follow:
            trackingMode = .follow
            break
        case .followWithCourse:
            trackingMode = .followWithCourse
            break
        case .followWithHeading:
            trackingMode = .followWithHeading
            break
        }
        mapView.setUserTrackingMode(trackingMode, animated: animated, completionHandler: nil)
        mapView.showsUserHeadingIndicator = true
    }
    
    public func setCenter(_ location: TRPLocation, zoomLevel: Double? = nil){
        guard let mapView = mapView else { return }
        if let zoom = zoomLevel {
            mapView.setCenter(CLLocationCoordinate2D(latitude: location.lat, longitude: location.lon), zoomLevel: zoom, animated: true)
        }else {
            mapView.setCenter(CLLocationCoordinate2D(latitude: location.lat, longitude: location.lon), animated: true)
        }
    }
    
    public func setZoomLevel(_ zoomLevel: Double) {
        if let map = mapView {
            map.zoomLevel = zoomLevel
        }
    }
    
    deinit {
        Log.deInitialize()
    }
}


// MARK: - MapBox settings
extension TRPMapView: MGLMapViewDelegate{
    
    //Setup Map View
    func setupMapView() {
        //styleURL:MGLStyle.outdoorsStyleURL
        // MGLStyle.streetsStyleURL
        // let style = URL(string: "mapbox://styles/evrenyasar/ckg6adve327t719qiw9276go1")
        
        mapView = MGLMapView(frame: self.bounds,
                             styleURL: MGLStyle.streetsStyleURL)
        guard let mapView = mapView else {return}
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if let start = startLocation {
            mapView.setCenter(start, zoomLevel: startZoomLevel, animated: false)
        }
        
        mapView.delegate = self
        mapView.compassView.isHidden = true
        mapView.showsUserLocation = showUserLocation
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
        guard let mapView =  mapView else {return}
        
        let spot = sender.location(in: mapView)
        let features = mapView.visibleFeatures(at: spot, styleLayerIdentifiers: Set(clickableLayerTags))
        let f1 = mapView.visibleAnnotations(in: CGRect(x: spot.x - 10, y: spot.y - 10, width: 20, height: 20))
        
        if let annotation = f1?.first, let trpAnnotation = annotation as? TRPPointAnnotation, let id = trpAnnotation.poiId {
            delegate?.mapView(self, annotationPressed: id, type: .viewAnnotation)
        }else if let feature = features.first, let placeId = feature.attribute(forKey: "placeId") as? String {
            if (feature.attribute(forKey: "image") as? String) == "NexusTour" {
                delegate?.mapView(self, annotationPressed: placeId, type: .tourAnnotation)
            } else {
                delegate?.mapView(self, annotationPressed: placeId, type: .styleAnnotation)
            }
        } else {
            
            delegate?.mapViewCloseAnnotation(self)
        }
    }
    
    public func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        if didMapLoaded == false {
            addRouteSource(features: [])
            delegate?.mapViewDidFinishLoading(self)
        }
        didMapLoaded = true
    }
    
    public func mapView(_ mapView: MGLMapView, regionDidChangeAnimated animated: Bool) {
        delegate?.mapView(self, regionDidChangeAnimated: animated)
    }
    
    public func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {
        if let trpAnnotation = annotation as? TRPPointAnnotation, let id = trpAnnotation.poiId {
            delegate?.mapView(self, annotationPressed: id, type: .viewAnnotation)
        }
    }
    
    public func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        guard let castAnnotation = annotation as? TRPPointAnnotation,
              let imageName = castAnnotation.imageName else {
            return nil
        }
        let reuseIdentifier = imageName
        let annotationView = TRPRotaAnnotationView(reuseIdentifier: reuseIdentifier,
                                                   imageName: imageName,
                                                   order: castAnnotation.order,
                                                   isOffer: castAnnotation.isOffer)
        annotationView.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        return annotationView
    }
    
    public func mapView(_ mapView: MGLMapView, didChange mode: MGLUserTrackingMode, animated: Bool) {
        switch mode {
        case .follow:
            delegate?.mapView(self, didChange: TRPUserTrackingMode.follow)
        case .followWithCourse:
            delegate?.mapView(self, didChange: TRPUserTrackingMode.followWithCourse)
        case .followWithHeading:
            delegate?.mapView(self, didChange: TRPUserTrackingMode.followWithHeading)
        case .none:
            delegate?.mapView(self, didChange: TRPUserTrackingMode.none)
        @unknown default:
            ()
        }
    }
    
    public func mapView(_ mapView: MGLMapView, didUpdate userLocation: MGLUserLocation?) {
        if let location = userLocation?.coordinate {
            delegate?.mapView(self, userLocationUpdate: TRPLocation(lat: location.latitude, lon: location.longitude))
        }
    }
    
    public func mapViewWillStartLocatingUser(_ mapView: MGLMapView) {
        delegate?.mapViewWillStartLocationingUser(self)
    }
    
    public func mapViewDidStopLocatingUser(_ mapView: MGLMapView) {
        delegate?.mapViewDidStopLocationingUser(self)
    }
    
    public func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        if let annotation = annotation as? CustomPolyLine {
            // Return orange if the polyline does not have a custom color.
            return annotation.color ?? .blue
        }
        // Fallback to the default tint color.
        return mapView.tintColor
    }
}

//Load Style
extension TRPMapView {
    
    //To add Image on mapview
    fileprivate func addSyleImages() {
        if isImagesAdded == true {return}
        guard let style = mapView?.style else {return}
        for image in delegate?.mapViewImagesForFilteringLayers(self) ?? [] {
            style.setImage(image.uiImage, forName: image.tag)
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
                                        styleAnnotation:StyleAnnotatoin,
                                        clickAble: Bool = true) {
        let points = points.map{trpPointToMGLPointsFeature($0)}
        if clickAble {
            clickableLayerTags.append(styleAnnotation.rawValue)
        }
        addItemsToMap(features: points, sourseIdentifier: styleAnnotation.rawValue)
    }
    
    public func removePointsForAlternative(styleAnnotation:StyleAnnotatoin) {
        guard let style = mapView?.style else {return}
        if let source = style.source(withIdentifier: styleAnnotation.rawValue) as? MGLShapeSource{
            source.shape = MGLShapeCollectionFeature(shapes: [])
            let symbols = MGLSymbolStyleLayer(identifier: styleAnnotation.rawValue, source: source)
            style.removeLayer(symbols)
            style.removeSource(source)
        }
    }
    public func addPointsForNexusTours(_ points: [JuniperProduct],
                                        styleAnnotation:StyleAnnotatoin,
                                        clickAble: Bool = true) {
        var mglPoints = [MGLPointFeature]()
        for point in points {
            if let lat = point.serviceInfo?.latitude, let lon = point.serviceInfo?.longitude {
                let pointFeature = MGLPointFeature()
                pointFeature.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                pointFeature.attributes = ["image":"NexusTour", "placeId": point.code, "title": point.serviceInfo?.name ?? "" ]
                mglPoints.append(pointFeature)
            }
        }
//        let points = points.map{trpPointToMGLPointsFeature($0)}
        if clickAble {
            clickableLayerTags.append(styleAnnotation.rawValue)
        }
        addItemsToMap(features: mglPoints, sourseIdentifier: styleAnnotation.rawValue)
    }
    
    public func removePointsForNexusTours(styleAnnotation:StyleAnnotatoin) {
        guard let style = mapView?.style else {return}
        if let source = style.source(withIdentifier: styleAnnotation.rawValue) as? MGLShapeSource{
            source.shape = MGLShapeCollectionFeature(shapes: [])
            let symbols = MGLSymbolStyleLayer(identifier: styleAnnotation.rawValue, source: source)
            style.removeLayer(symbols)
            style.removeSource(source)
        }
    }
    
    private func trpPointToMGLPointsFeature(_ trpPoint: TRPPointAnnotationFeature) -> MGLPointFeature {
        let mgl = MGLPointFeature()
        mgl.coordinate = CLLocationCoordinate2D(latitude: trpPoint.lat, longitude: trpPoint.lon)
        mgl.attributes = ["image":trpPoint.iconType, "placeId":trpPoint.id, "title":trpPoint.name]
        return mgl
    }
    
    private func addItemsToMap(features: [MGLPointFeature], sourseIdentifier sourceId: String) {
        guard let style = mapView?.style else {return}
        
        if let source = style.source(withIdentifier: sourceId) as? MGLShapeSource{
            source.shape = MGLShapeCollectionFeature(shapes: features)
        }else {
            
            let newSource = MGLShapeSource(identifier: sourceId,
                                           features: features,
                                           options: [.clustered: false])
            style.addSource(newSource)
            let symbols = MGLSymbolStyleLayer(identifier: sourceId, source: newSource)
            symbols.iconImageName = NSExpression(format: "image")
            symbols.iconAllowsOverlap = NSExpression(forConstantValue: "true")
            //symbols.predicate = NSPredicate(format: "cluster != YES")
            style.addLayer(symbols)
            
            //Cluster Layer stili. Yeni  oluşacak annotation.
//            let clusterLayer = MGLSymbolStyleLayer(identifier: "\(sourceId)clustered", source: newSource)
//            clusterLayer.textColor = NSExpression(forConstantValue: UIColor.white)
//            clusterLayer.textFontSize = NSExpression(forConstantValue: NSNumber(value: 14))
//            clusterLayer.iconAllowsOverlap = NSExpression(forConstantValue: true)
//            
//            // Style image clusters
//            if let blueAnnotation = TRPImageController().getImage(inFramework: TRPAppearanceSettings.MapAnnotations.clustersImage.imageName, inApp: nil) {
//                style.setImage(blueAnnotation, forName: TRPAppearanceSettings.MapAnnotations.clustersImage.tag)
//            }
//            
//            //Zoom levelda görüntülenecek annotationlar
//            let stops = [
//                100: NSExpression(forConstantValue: TRPAppearanceSettings.MapAnnotations.clustersImage.tag)
//            ]
//            
//            //Default annotation
//            let defaultShape = NSExpression(forConstantValue: TRPAppearanceSettings.MapAnnotations.clustersImage.tag)
//            clusterLayer.iconImageName = NSExpression(format: "mgl_step:from:stops:(point_count, %@, %@)", defaultShape, stops)
//            clusterLayer.text = NSExpression(format: "CAST(point_count, 'NSString')")
//            style.addLayer(clusterLayer)
        }
    }
    
    
}

// MARK: calculateRoute
extension TRPMapView {
    
    public func drawRuntimeRoute(_ route: Route, color: UIColor = UIColor.blue, edge: UIEdgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)) {
        if runTimeRoute != nil {
            self.mapView?.removeAnnotation(runTimeRoute!)
        }
        
        guard var routeCoordinates = route.shape?.coordinates, routeCoordinates.count > 0 else {
            return
        }
        let routeCount = UInt(routeCoordinates.count)
        
        
        let routeLine = CustomPolyLine(coordinates: &routeCoordinates, count: routeCount)
        routeLine.color = color
        runTimeRoute = routeLine
        self.mapView?.addAnnotation(routeLine)
        self.mapView?.setVisibleCoordinates(&routeCoordinates, count: routeCount, edgePadding: edge, animated: true)
    }
    
    public func drawRoute(_ route: Route, style: DrawRouteStyle, edge: UIEdgeInsets = UIEdgeInsets(top: 40, left: 40, bottom: 80, right: 40)) {
        guard var routeCoordinates = route.shape?.coordinates, routeCoordinates.count > 0 else {
            return
        }
        let routeCount = UInt(routeCoordinates.count)
        
        drawRouteDottedLine(route, tag: style.rawValue, color: style.getColor())
        
        self.mapView?.setVisibleCoordinates(&routeCoordinates,
                                            count: routeCount,
                                            edgePadding: edge,
                                            animated: true)
    }
    
    public func drawCarRoute(_ route: Route, edge: UIEdgeInsets = UIEdgeInsets(top: 40, left: 40, bottom: 80, right: 40)) {
        //TODO: - EVREN
        guard var routeCoordinates = route.shape?.coordinates, routeCoordinates.count > 0 else {
            return
        }
        let routeCount = UInt(routeCoordinates.count)
       
        drawRouteLine(route, color: DrawRouteStyle.rota.getColor())
        
        self.mapView?.setVisibleCoordinates(&routeCoordinates,
                                            count: routeCount,
                                            edgePadding: edge,
                                            animated: true)
    }
    public func removeRoute(style: DrawRouteStyle) {
        guard let map = mapView else {return}
        if let source = map.style?.source(withIdentifier: style.rawValue) as? MGLShapeSource {
            
            source.shape = MGLShapeCollectionFeature(shapes: [])
        }
    }
    
    //Todo: - mapView guard yapılacak
    private func drawRouteDottedLine(_ route: Route, tag: String, color: UIColor = UIColor.blue) {
        
        guard route.legs.count > 0 else {return}
        guard var routeCoordinates = route.shape?.coordinates, routeCoordinates.count > 0 else {return}
        
        let polyLine = MGLPolylineFeature(coordinates: &routeCoordinates, count: UInt(routeCoordinates.count))
        if let source = mapView!.style?.source(withIdentifier: tag) as? MGLShapeSource {
            source.shape = polyLine
        }else {
            let source = MGLShapeSource(identifier: tag, features: [polyLine], options: nil)
            let lineStyle = MGLLineStyleLayer(identifier: "\(tag)-style", source: source)
            lineStyle.lineJoin = NSExpression(forConstantValue: "round")
            lineStyle.lineCap = NSExpression(forConstantValue: "round")
            lineStyle.lineColor = NSExpression(forConstantValue: color)
            lineStyle.lineWidth = NSExpression(forConstantValue: 4)
            lineStyle.lineDashPattern = NSExpression(forConstantValue: [1, 2.0])
            mapView?.style?.addSource(source)
            mapView?.style?.addLayer(lineStyle)
        }
        
    }
    
    
    public func drawRouteLine(_ route: Route, color: UIColor = UIColor.blue ) {
        
        guard var routeCoordinates = route.shape?.coordinates, routeCoordinates.count > 0 else {
            return
        }
        let routeCount = UInt(routeCoordinates.count)
        
        let routeLine = CustomPolyLine(coordinates: &routeCoordinates, count: routeCount)
        routeLine.color = color
        let edge = UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40)
        self.mapView?.addAnnotation(routeLine)
        self.mapView?.setVisibleCoordinates(&routeCoordinates,
                                            count: routeCount,
                                            edgePadding: edge,
                                            animated: true)
        
    }
    
    
    private func routeToPoints(_ route: Route) -> [CLLocationCoordinate2D] {
        guard let steps = route.legs.first?.steps else { return []}
        var points = [CLLocationCoordinate2D]()
        for step in steps {
            points.append(step.maneuverLocation)
        }
        return points
    }
    
    
    /**
     Rota cizildiğinde Z INDEX sorunu oluyor.
     Z Index sorunun çözmek için öncelikle direk rota source haritaya ekleniyor.
     Note: this code is an alternative for DrawRoute
     */
    fileprivate func addRouteSource(features : [MGLPolylineFeature]) {
        
        let source = MGLShapeSource(identifier: "route-source", features: features, options: nil)
        let lineStyle = MGLLineStyleLayer(identifier: "route-style", source: source)
        lineStyle.lineColor = NSExpression(forConstantValue: #colorLiteral(red: 0.1115320227, green: 1, blue: 1, alpha: 1))
        lineStyle.lineWidth = NSExpression(forConstantValue: 4)
        lineStyle.lineOpacity = NSExpression(forConstantValue: 5)
        
        //lineStyle.lineJoin = MGLStyleValue(rawValue: NSValue(mglLineJoin: .round))
        //lineStyle.lineCap = MGLStyleValue(rawValue: NSValue(mglLineCap: .round))
        // lineStyle.lineJoin = NSExpression(forConstantValue: "round")
        // lineStyle.lineCap = NSExpression(forConstantValue: "round")
        // lineStyle.lineDashPattern = NSExpression(forConstantValue: [0, 1.5])
        mapView?.style?.addSource(source)
        mapView?.style?.addLayer(lineStyle)
    }
}
//TODO: Rozeri Report a Problem da a title a message geliyor 

class CustomPolyLine: MGLPolyline {
    var color: UIColor?
}
