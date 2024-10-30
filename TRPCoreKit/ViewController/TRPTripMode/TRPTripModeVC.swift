//
//  TRPTripModeMap.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 13.11.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit


import MapboxDirections
import SDWebImage


var globalNavBarImage: UIImage?
var globalNavBarShadow: UIImage?

public protocol TRPTripModeVCDelegate: AnyObject {
    func trpTripModeViewControllerOpenPlaces(_ viewController: UIViewController)
    func trpTripModeViewControllerOpenFavorites(_ viewController: UIViewController)
    func trpTripModeViewControllerOpenExperience(_ viewController: UIViewController)
    func trpTripModeViewControllerOpenBooking(_ viewController: UIViewController)
    func trpTripModeViewControllerOpenItinerary(_ viewController: UIViewController)
    func trpTripModeViewControllerPoiDetail(_ viewController: UIViewController, poi: TRPPoi, parentStep: TRPStep?)
    func trpTripModeViewControllerClearAndEditTrip(_ completionHandler: (_ competed: Bool) -> Void )
    func trpTripModeViewControllerIsMovingFrom()
    func trpTripModeViewControllerOpenMyOffers(_ viewController: UIViewController)
    func trpTripModeViewControllerSetDestinationIdAndName(destinationId: Int, cityEngName: String)
}

//Kullanici baska sehirdeyse ve kendi lokasyonuna tikladiysa, mevcut rotasindan uzaklasiyor.
//Bu durumda search buttonunu gostermemek icin MapStatus eklendi.
enum MapStatus{ case mapIsReady, mapWillShow, mapDidShow}

@objc(SPMTRPTripModeVC)
public class TRPTripModeVC: TRPBaseUIViewController {
    
    @IBOutlet weak var blackTabbar: BlackTabbar!
    @IBOutlet weak var bottomSpace: UIView!
    @IBOutlet weak var mapContainer: UIView!
    private var callOutController: TRPCallOutController?
    public var viewModel: TRPTripModeViewModel!
    private var map: TRPMapView?
    public weak var delegate: TRPTripModeVCDelegate?
//    fileprivate var showCityCenterBtn: TRPCirleButton?
    fileprivate var searchAreaBtn: TRPSearchAreaButton?
    fileprivate var userLocation: TRPLocation?
    fileprivate var isUserInCity: TRPUserLocationController.UserStatus?
    fileprivate var rotaCenter: TRPLocation?
    fileprivate var trpTabBar: TRPTabBar?
    fileprivate var routeInfoView: RouteInfoShower1?
    //fileprivate var turnByTurnNavigation: TurnByTurnNavigationController<TRPTripModeVC>?
    private var alternativePois = [TRPPointAnnotationFeature]()
    private var alternativeIsAdded = false {
        didSet {
            let imageName = alternativeIsAdded ? "btn_alternatives_pressed" : "btn_alternatives"
            alternativesBtn.setImage(TRPImageController().getImage(inFramework: imageName, inApp: nil)!, for: .normal)
        }
    }
    private var nexusToursAdded = false {
        didSet {
            let imageName = nexusToursAdded ? "icon_nexus_orange" : "icon_nexus"
            nexusToursBtn.setImage(TRPImageController().getImage(inFramework: imageName, inApp: nil)!, for: .normal)
        }
    }
    private var isUserLocationCentered = false {
        didSet {
            let imageName = isUserLocationCentered ? "btn_user_location_pressed" : "btn_user_location"
            userLocationBtn.setImage(TRPImageController().getImage(inFramework: imageName, inApp: nil)!, for: .normal)
            showCityCenterBtn.isHidden = !isUserLocationCentered
        }
    }
    public var didViewLoad: Bool = false
//    private var showAlternativeBtn: TRPCirleButton?
    private var isSearchThisArea = true {
        didSet {
            if isSearchThisArea {
                searchAreaBtn?.title = TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.searchThisArea.title")
            }else {
                searchAreaBtn?.title = TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.searchThisArea.clear")
            }
        }
    }
    private var routeInfoViewPosition: CGFloat = 0 {
        didSet {
            self.setSearchThisAreaButtonPosition()
        }
    }
    
    @IBOutlet weak var alternativesBtn: UIButton!
    @IBOutlet weak var nexusToursBtn: UIButton!
    @IBOutlet weak var userLocationBtn: UIButton!
    @IBOutlet weak var searchOfferBtn: UIButton!
    @IBOutlet weak var googleExportBtn: UIButton!
    @IBOutlet weak var searchOfferView: UIView!
    @IBOutlet weak var showCityCenterBtn: UIButton!
    var isSearchingOffer: Bool = false
    
    private var dayChanged: (day: Date, selected: Bool) = (Date(), false){
        didSet{
            dayChangedPoi = dayChanged
        }
    }
    
    private var navBarTitleView: UIView?
    
    // MARK: - Map Variables
    var mapStatus: MapStatus?
    var mapsInAnotherCity: Bool = false
    
    // Declare gesture recognizer
    var tapGestureRecognizer: UITapGestureRecognizer!
    
    @objc func changeDayPressed() {
        showDailyList()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.title = ""
    }
    
    public override func setupViews() {
        super.setupViews()
        addBackButton(position: .left)
        setupButtons()
        setupNavigationBar()
        setupTRPMap()
        setupBlackTabbar()
//        setupShowCityCenterButton()
//        addAlternativeButton()
        setupCallOutController();
        createSearchThisArea()
//        setupListOfRouting()
//        createTurnByTurnNavigation()
        loader = TRPLoaderView(superView: view)
        TRPUserLocationController.shared.isUserInCity { [weak self] (cityId, status, location) in
            guard let strongSelf = self else {return}
            strongSelf.isUserInCity = status
            strongSelf.userLocation = location
            strongSelf.sendAnalytics(cityId,location)
        }
        /*let timeFrame = TRPImageController().getImage(inFramework: "timeframe", inApp: TRPAppearanceSettings.TripModeMapView.timeFrameImage)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: timeFrame,
                                                            style: UIBarButtonItem.Style.plain,
                                                            target: self,
                                                            action: #selector(changeTimePressed))  */
        hiddenBackButtonTitle()
        checkShowAlternative()
    }
    
    
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tapGestureRecognizer = UITapGestureRecognizer(target:self, action: #selector(self.navigationBarTapped(_:)))
        self.navigationController?.navigationBar.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer.cancelsTouchesInView = false
        
        mapStatus = .mapIsReady
        self.navigationController?.navigationBar.topItem?.title = ""
        //Note: data elinde olduğu için önceden yükleniyor
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        if !didViewLoad {
            didViewLoad.toggle()
            delegate?.trpTripModeViewControllerClearAndEditTrip({ _ in})
            viewModel.start()
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.removeGestureRecognizer(tapGestureRecognizer)
        if isMovingFromParent {
            self.delegate?.trpTripModeViewControllerIsMovingFrom()
        }
    }
    
    private func checkShowAlternative() {
        //Fixme: - UserDefault a gerek yok. Refactor et.
        let altenativesIds = UserDefaults.standard.array(forKey: "IsAlternativeShowedAr") as? [String] ?? [String]()
        if altenativesIds.contains(viewModel.tripHash) == false {
            var tempAr = altenativesIds
            tempAr.append(viewModel.tripHash)
            UserDefaults.standard.set(tempAr, forKey: "IsAlternativeShowedAr")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                //self.showAlternativeBtn!.open()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                //self.showAlternativeBtn!.close()
            }
        }
    }
    
    private func sendAnalytics(_ cityId: Int, _ location: TRPLocation?){
        guard let userLocation = userLocation else {return}
        let mapViewKeys = [Notification.MapViewKeys.hash: hash,
                           Notification.MapViewKeys.cityId: cityId,
                           Notification.MapViewKeys.userLocation: userLocation as TRPLocation] as [Notification.MapViewKeys : Any]
        
        NotificationCenter.default.post(name: .mapViewed, object:nil, userInfo: mapViewKeys)
        guard let userName = TRPUserPersistent.getUserEmail() else {return}
        let userLocatedKeys = [Notification.UserLocationKeys.userName: userName as String,
                               Notification.UserLocationKeys.userLocation: userLocation as TRPLocation] as [Notification.UserLocationKeys : Any]
        NotificationCenter.default.post(name: .userLocated, object:nil, userInfo: userLocatedKeys)
    }
    
    private func setupCallOutController() {
        let addImage = TRPImageController().getImage(inFramework: "add_btn", inApp: TRPAppearanceSettings.Common.addButtonImage)
        let removeImage = TRPImageController().getImage(inFramework: "remove_btn", inApp: TRPAppearanceSettings.Common.removeButtonImage)
        let navImage = TRPImageController().getImage(inFramework: "navigation_btn", inApp: TRPAppearanceSettings.Common.navigationButtonImage)
        
        var bottomSpace: CGFloat = 136
        
        if let tabBar = trpTabBar {
            if #available(iOS 11.0, *) {
                bottomSpace = tabBar.frame.height + 10
            }
        }
        
        callOutController = TRPCallOutController(inView: self.view,
                                                 addBtnImage: addImage,
                                                 removeBtnImage: removeImage,
                                                 navigationBtnImage: navImage,
                                                 bottomSpace: bottomSpace)
        callOutController?.cellPressed = { [weak self] id, inRoute in
            guard let strongSelf = self else {return}
            strongSelf.callOutController?.hidden()
            if id == TRPPoi.ACCOMMODATION_ID {return}
            strongSelf.viewModel.getPoiInfo(id) { poi in
                if poi == nil {return}
                if poi!.placeType == TRPPoi.PlaceType.poi {
                    strongSelf.delegate?.trpTripModeViewControllerPoiDetail(strongSelf, poi: poi!, parentStep: nil)
                }
            }
        }
        
        callOutController?.action =  { [weak self] status, id in
            guard let strongSelf = self else {return}
            guard let strongCallOut = strongSelf.callOutController else {return}
            strongCallOut.hidden()
            if status == .remove {
                strongSelf.viewModel.removePoiInRoute(poiId: id)
            }else if status == .add {
                strongSelf.viewModel.addPoiInRoute(poiId: id)
            }
        }
    }
    
    //Fixme: - Lokasyonu parametre olarak al. SideEffect yapma.
    public func drawRoute(poi: TRPPoi) {
        guard let map = map, let user = TRPUserLocationController.shared.userLatestLocation else {return}
        map.showUserLocation = true
        viewModel.fetchRoutes(locations: [user, poi.coordinate]) {[weak self] (route, waypoints, error) in
            guard let strongSelf = self else {return}
            if let error = error {
                strongSelf.viewModel(error: error)
                return
            }
            if let route = route {
                map.drawRoute(route, style: TRPMapView.DrawRouteStyle.runtime)
                map.addPointsForAlternative([strongSelf.placeToMapFeature(poi)], styleAnnotation: TRPMapView.StyleAnnotatoin.runTimeRoutePoi)
                //Fixme: - Close ile return etmeli.
                strongSelf.showReadableRouteTime(route.expectedTravelTime, distance: route.distance)
            }
        }
    }
    
    private func showReadableRouteTime(_ time:TimeInterval, distance: CLLocationDistance) {
        let readable = ReadableDistance.calculate(distance: Float(distance), time: time)
        let startY = UIApplication.shared.statusBarFrame.size.height + (navigationController?.navigationBar.frame.height ?? 0.0)
        let cgRect = CGRect(x: 0, y: startY, width: self.view.frame.width, height: 60)
        if let oldRouteView = routeInfoView {
            oldRouteView.removeFromSuperview()
            routeInfoView = nil
        }
        if let hour = Date().addMin(component: Calendar.Component.minute, value: readable.time) {
            let readableHours = hour.toStringWithoutTimeZone(format:"HH:mm")
            routeInfoView = RouteInfoShower1(frame: cgRect,
                                             arrivalHours: readableHours,
                                             min: readable.time,
                                             meters: Int(distance))
            routeInfoView?.setHandler({ [weak self] (status) in
                guard let strongSelf = self else {return}
                strongSelf.routeInfoViewPosition = status.get()
            })
            view.addSubview(routeInfoView!)
        }
    }
    
    @IBAction func userLocationPressed(_ sender: UIButton) {
        let permission = isLocationPermissionAccessable()
        if permission.showAlert {
            EvrAlertView.showAlert(contentText: TRPLanguagesController.shared.getLanguageValue(for: "location_permission_denied"), type: .warning)
        }
        if !permission.access {return}
        isUserLocationCentered = true
//        if !isUserLocationCentered {
            map?.setTrackingMode(TRPUserTrackingMode.followWithCourse, animated: true)
//            checkCityCentered()
//        }else {
//            map?.setTrackingMode(TRPUserTrackingMode.none, animated: true)
//        }
    }
    
    @IBAction func searchOfferPressed(_ sender: Any) {
        self.searchOffers()
    }
    
    @IBAction func googleExportPressed(_ sender: Any) {
        viewModel.exportPlan() { [weak self] url in
            guard let self = self, let url = url.url else {return}
            self.openGoogleMap(url: url)
        }
    }
    @IBAction func alternativesPressed(_ sender: Any) {
        showAlternativePressed()
    }
    @IBAction func nexusToursPressed(_ sender: Any) {
        showHideNexusTours()
    }
    @IBAction func showCityCenterPressed(_ sender: Any) {
        showCityCenterPressed()
        isUserLocationCentered = false
    }
    
    func openGoogleMap(url: String) {
        if UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!){
            let embedUrl = url.replacingOccurrences(of: "https://", with: "")
            if let mapsUrl = URL(string: "comgooglemapsurl://\(embedUrl)") {
                UIApplication.shared.open(mapsUrl, options: [:])
            }
        } else {
            if let urlDestination = URL.init(string: url) {
                UIApplication.shared.open(urlDestination)
            }
        }
    }
}

//MARK: - Buttons
extension TRPTripModeVC {
    private func setupButtons() {
        searchOfferBtn.isHidden = true
        searchOfferBtn.addShadow(withRadius: 10)
        googleExportBtn.addShadow(withRadius: 10)
        userLocationBtn.addShadow(withRadius: 10)
        alternativesBtn.addShadow(withRadius: 10)
        nexusToursBtn.addShadow(withRadius: 10)
        showCityCenterBtn.addShadow(withRadius: 10)
    }
}
//MARK: - NavigationBar
extension TRPTripModeVC {
    
    private func setupNavigationBar() {
/*        let favorite = TRPImageController().getImage(inFramework: "nav_favorite_small", inApp: TRPAppearanceSettings.TripModeMapView.favoriteImage)
        let favoriteBtn = UIBarButtonItem(image: favorite?.withRenderingMode(.alwaysOriginal),
                                          style: UIBarButtonItem.Style.plain,
                                          target: self,
                                          action: #selector(favoriteBtnPressed))
//        favoriteBtn.imageInsets = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)*/
//        let booking = TRPImageController().getImage(inFramework: "nav_my_bookings", inApp: TRPAppearanceSettings.TripModeMapView.notificationImage)
//        let bookingBtn = UIBarButtonItem(image: booking?.withRenderingMode(.alwaysOriginal),
//                                          style: UIBarButtonItem.Style.plain,
//                                          target: self,
//                                          action: #selector(bookingBtnPressed))
//        bookingBtn.imageInsets = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
//
//        navigationItem.rightBarButtonItems = [bookingBtn]
//        let myOffers = TRPImageController().getImage(inFramework: "nav_my_offers", inApp: TRPAppearanceSettings.TripModeMapView.favoriteImage)
//        let myOffersBtn = UIBarButtonItem(image: myOffers?.withRenderingMode(.alwaysOriginal),
//                                          style: UIBarButtonItem.Style.plain,
//                                          target: self,
//                                          action: #selector(myOffersBtnPressed))
//        myOffersBtn.imageInsets = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
//        navigationItem.rightBarButtonItems = [myOffersBtn]
    }
    
    func setDayTitle(day: Int, date dateStr:String) {
        var readableDay = ""
        if let mainDate = dateStr.toDate(format: "yyyy-MM-dd"){
            dayChanged = (mainDate,true)
            readableDay = mainDate.toString(format: "MMM d", locale: TRPClient.shared.language)
        }
        let dayS = TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.day")
        let navTitle = CustomNavTitle()
        navTitle.dateLbl.text = "\(dayS) \(day) - \(readableDay)"
        navTitle.cityNameLbl.text = viewModel.city.name
        navigationItem.titleView = navTitle.vStackView
        
    }
    
    @objc func navigationBarTapped(_ sender: UITapGestureRecognizer){
        let location = sender.location(in: self.navigationController?.navigationBar)
        let hitView = self.navigationController?.navigationBar.hitTest(location, with: nil)
        
        guard !(hitView is UIControl) else { return }
        // Here, we know that the user wanted to tap the navigation bar and not a control inside it
        changeDayPressed()
    }
    
    fileprivate func showDailyList() {
        //todo:
        /*if self.viewModel.isCurrentDay(planId: plan.planId) {
            button.setValue(true, forKey: "checked")
        }*/
        let days = viewModel.getDayList().map{ TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.day") + " \($0.day) - \($0.date)" }
        var selectedDayOrder: Int?
        for (index, item) in viewModel.getDayList().enumerated() {
            if viewModel.isCurrentDay(planId: item.planId) {
                selectedDayOrder = index
            }
        }
        
        
        let actionVC = UIStoryboard.actionViewController()
        let model = ActionModel(TRPLanguagesController.shared.getLanguageValue(for: "change_day"),nil, days, TRPLanguagesController.shared.getCancelBtnText())
        actionVC.config(model)
        actionVC.checkOrder = selectedDayOrder
        actionVC.btnAction  = {
            actionVC.dismissView(completion: nil)
        }
        actionVC.itemAction = { item in
            let planId = self.viewModel.getDayList()[item].planId
            self.viewModel.changeDay(planId: planId)
        }
        presentVCWithModal(actionVC)
//        present(actionVC, animated: false, completion: nil)
       
    }
    
    @objc func favoriteBtnPressed() {
        delegate?.trpTripModeViewControllerOpenFavorites(self)
    }
    
    @objc func notificationBtnPressed() {}
    
    @objc func bookingBtnPressed() {
        delegate?.trpTripModeViewControllerOpenBooking(self)
    }
    @objc func myOffersBtnPressed() {
        delegate?.trpTripModeViewControllerOpenMyOffers(self)
    }
}

// MARK: - TABBAR
extension TRPTripModeVC {
    
    private func setupBlackTabbar() {
        bottomSpace.backgroundColor = trpTheme.color.tabbarColor
        blackTabbar.action = { [weak self] item in
            guard let strongSelf = self else {return}
            switch item {
            case .itinerary: ()
                /*if let itinerary = stronSelf.listOfRoutingPoisVC {
                    itinerary.openMenu()
                }*/
                strongSelf.delegate?.trpTripModeViewControllerOpenItinerary(strongSelf)
            case .experiences: ()
//                stronSelf.showMessage("Juniper Tours will be implemented soon.", type: .info)
                strongSelf.delegate?.trpTripModeViewControllerOpenExperience(strongSelf)
//            case .offer:
//                NotificationCenter.default.post(name: Notification.Name("TripianOpenOfferVC"), object: self, userInfo: ["vc": stronSelf, "cityId": stronSelf.viewModel.city.id])
            case .favourite:
                strongSelf.favoriteBtnPressed()
            case .search:
                strongSelf.delegate?.trpTripModeViewControllerOpenPlaces(strongSelf)
            }
        }
    }
}

// MARK: - Set time field
extension TRPTripModeVC{
    @objc func changeTimePressed() {
        // showTimeDialog()
        let changeTimeAlert =  TimeAlert(title: TRPLanguagesController.shared.getLanguageValue(for: "tripPlan.header"),
                                         saveActionTitle: TRPLanguagesController.shared.getUpdateBtnText(),
                                         cancelActionTitle: TRPLanguagesController.shared.getCancelBtnText(),
                                         applyButtonTitle: TRPLanguagesController.shared.getApplyBtnText(),
                                         doneButtonTitle: TRPLanguagesController.shared.getDoneBtnText(),
                                         startTimePlaceHolder: TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.customPoiModal.visitTime.from") + " 9:00",
                                         endTimePlaceHolder: TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.customPoiModal.visitTime.to") + " 21:00")
            .setDelegate(timeDelegate: self)
            .build()
        
        DispatchQueue.main.async {
            self.present(changeTimeAlert,animated: true){
                changeTimeAlert.view.superview?.isUserInteractionEnabled = true
                changeTimeAlert.view.superview?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.timeAlertBackgroundTapped)))
            }
        }
    }
    
    func updateDailyPlanHour(start: String, end: String) {
        viewModel.updateDailyPlanHour(start: start, end: end)
    }
}

//MARK: - Set Time Field Delegate
extension TRPTripModeVC: TimeAlertDelegate{
    public func timeChanged(_ startTime: String, _ endTime: String) {
        viewModel.updateDailyPlanHour(start: startTime, end: endTime)
    }
    
    public func dismissTimeAlert() {
        dismiss()
    }
    
    @objc func timeAlertBackgroundTapped(){
        dismiss()
    }
    
    private func dismiss(){
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - TURN BY TURN NAVIGATIOM
extension TRPTripModeVC {
    private func createTurnByTurnNavigation() {
        //turnByTurnNavigation = TurnByTurnNavigationController(parentVC: self)
        
    }
}

// MARK: - MapView
extension TRPTripModeVC: TRPMapViewDelegate {
    
    fileprivate func setupTRPMap() {
        let lat = viewModel.startLocation.lat
        let lon = viewModel.startLocation.lon
        let startLocation = LocationCoordinate(lat:lat, lon:lon)
        
        //todo: bottomtabbar çıkarılmayacak. orada bi sorun var
        mapContainer.backgroundColor = UIColor.white
        map = TRPMapView(frame: CGRect(x: 0, y: 0, width:mapContainer.frame.width + 50, height: mapContainer.frame.height + 70), startLocation: startLocation,zoomLevel:12)
        mapContainer.addSubview(map!)
        map!.delegate = self
        map!.showUserLocation = false
        print("[Info] MapContaioner2 \(mapContainer.frame.height)")
    }
    
    public func mapView(_ mapView: TRPMapView, regionDidChangeAnimated animated: Bool) {
        //Map ilk acildiginda,search buttonu gostermemek icin yazildi(zoom in olsa bile).
        switch mapStatus {
        case .mapWillShow?:
            mapStatus = .mapDidShow
            break
        case . mapIsReady?:
            searchAreaBtn?.hidden()
            mapStatus = .mapWillShow
            break
        case .mapDidShow?:
            if mapsInAnotherCity {
                searchAreaBtn?.hidden()
            }else {
                searchAreaBtn?.setZoomLevelTreshold(12.4)
                searchAreaBtn?.zoomLevel(mapView.zoomLevel)
            }
            
            break
        default:
            break
        }
        //Kullanici baska sehirdeyse, search area butonu gosterilmesin.
        
        callOutController?.hidden()
    }
    
    public func mapViewCloseAnnotation(_ mapView: TRPMapView) {
        guard let callOut = callOutController else {return}
        callOut.hidden()
    }
    
    public func mapViewDidFinishLoading(_ mapView: TRPMapView) {}
    
    public func mapView(_ mapView: TRPMapView, annotationPressed annotationId: String, type: TRPAnnotationType) {
        if type == .tourAnnotation {
            guard let tour = viewModel.getJuniperTour(from: annotationId) else { return  }
            openCallOutForNexus(tour)
            return
        }
        viewModel.getPoiInfo(annotationId) { [weak self] poi in
            guard let poi = poi else {
                Log.w("Annotaion clicked on \(annotationId) but data didn't find")
                return
            }
            self?.openCallOut(poi)
        }
    }
    
    private func openCallOut(_ poi: TRPPoi) {
        var category = ""
        if let name = poi.categories.first?.name {
            category = name
        }
        let raitingIsShow = TRPAppearanceSettings.ShowRating.type.contains { (category) -> Bool in
            if let id = poi.categories.first?.id {
                if category.getId() == id {
                    return true
                }
            }
            return false
        }
        var raiting = raitingIsShow ? poi.rating : 0
        raiting = raiting?.rounded()
        
        var rightButton: AddRemoveNavButtonStatus? = nil
        if poi.placeType == .poi {
            rightButton = viewModel.isPoiInRoute(poiId: poi.id) ? AddRemoveNavButtonStatus.remove : AddRemoveNavButtonStatus.add
        }
        
        let poiRating = poi.rating ?? 0
        let poiPrice = poi.price ?? 0
        
        let callOutCell: CallOutCellMode = CallOutCellMode(id: poi.id,
                                                           name: poi.name,
                                                           poiCategory: category,
                                                           startCount: Float(raiting ?? 0),
                                                           reviewCount: Int(raitingIsShow ? poiRating : 0),
                                                           price: poiPrice,
                                                           rightButton: rightButton)
        changeYpositionOfCallOut()
        
        callOutController?.cellPressed = { [weak self] id, inRoute in
            guard let strongSelf = self else {return}
            strongSelf.callOutController?.hidden()
            if id == TRPPoi.ACCOMMODATION_ID {return}
            strongSelf.viewModel.getPoiInfo(id) { poi in
                if poi == nil {return}
                if poi!.placeType == TRPPoi.PlaceType.poi {
                    strongSelf.delegate?.trpTripModeViewControllerPoiDetail(strongSelf, poi: poi!, parentStep: nil)
                }
            }
        }
        callOutController?.show(model: callOutCell)
        callOutController?.getCellImageView()?.image = nil
        
        guard let image = TRPImageResizer.generate(withUrl: poi.image.url, standart: .small) else {return}
        guard let url = URL(string: image) else {return}
        
        SDWebImageManager.shared.loadImage(with: url, options: SDWebImageOptions.lowPriority, context: nil, progress: nil) { [weak self] (downloadedImage, _, error, _, _, _) in
            guard let strongSelf = self else {return}
            if error != nil {
                Log.e(error!.localizedDescription)
                return
            }
            guard let image = downloadedImage else{
                Log.e("Image can not loaded")
                return
            }
            strongSelf.callOutController?.getCellImageView()?.image = image
        }
    }
    
    private func openCallOutForNexus(_ tour: JuniperProduct) {
        let category = tour.getCategories()
        
        let callOutCell: CallOutCellMode = CallOutCellMode(id: tour.code,
                                                           name: tour.serviceInfo?.name ?? "",
                                                           poiCategory: category,
                                                           startCount: 0,
                                                           reviewCount: 0,
                                                           price: 0,
                                                           rightButton: AddRemoveNavButtonStatus.none)
        changeYpositionOfCallOut()
        
        callOutController?.cellPressed = { [weak self] id, inRoute in
            guard let strongSelf = self else {return}
            strongSelf.callOutController?.hidden()
            if let productUrl = strongSelf.viewModel?.getJuniperTourUrl(from: id) {
                UIApplication.shared.open(productUrl)
            }
        }
        callOutController?.show(model: callOutCell)
        callOutController?.getCellImageView()?.image = nil
        
        guard let url = URL(string: tour.getImage()) else {return}
        
        SDWebImageManager.shared.loadImage(with: url, options: SDWebImageOptions.lowPriority, context: nil, progress: nil) { [weak self] (downloadedImage, _, error, _, _, _) in
            guard let strongSelf = self else {return}
            if error != nil {
                Log.e(error!.localizedDescription)
                return
            }
            guard let image = downloadedImage else{
                Log.e("Image can not loaded")
                return
            }
            strongSelf.callOutController?.getCellImageView()?.image = image
        }
    }
    
    fileprivate func changeYpositionOfCallOut() {
        let bottomSpace: CGFloat = 62
        /*if let listSpace = listOfRoutingPoisVC?.closeShowHeight {
            bottomSpace = listSpace + 10
        }*/
        if let callOut = callOutController {
            callOut.bottomSpace = bottomSpace
        }
    }
    
//    public func mapView(_ mapView: TRPMapView, didChange mode: TRPUserTrackingMode) {
//        guard let btn = userLocationBtn else {return}
//        if mode == .none {
//            btn.setImage(TRPImageController().getImage(inFramework: "btn_navigation_map", inApp: nil)!, for: .normal)
//        }else {
//            btn.setImage(TRPImageController().getImage(inFramework: "btn_navigation_map_pressed", inApp: nil)!, for: .normal)
//        }
//    }
    
}

// MARK: - CircleMenu
extension TRPTripModeVC {
    
    fileprivate func placeToMapFeature(_ place: TRPPoi)-> TRPPointAnnotationFeature{
        var iconType = place.icon
        if !place.offers.isEmpty {
            iconType += "WithOffer"
        }
        return TRPPointAnnotationFeature(id: place.id, name: place.name, lat: place.coordinate.lat, lon: place.coordinate.lon, iconType: iconType)
    }
}

extension TRPTripModeVC: TRPTripModeViewModelDelegate {
    public func viewModelNexusToursFetched(_ tours: [JuniperProduct]) {
        selectTypeOfNexusTourSearch()
//        showNexusTours(tours: tours)
    }
    
    public func setDestinationIdAndEngName(_ id: Int, cityEngName: String) {
        self.delegate?.trpTripModeViewControllerSetDestinationIdAndName(destinationId: id, cityEngName: cityEngName)
    }
    
    public func viewModelRoutingError(_ message: String, mapBoxError: String) {
        EvrAlertView.showAlert(contentText: message, type: .error, showTime: 4)
    }
    
    public func viewModelNoReccomendationAlert(_ message: String) {
        /*if let listView = listOfRoutingPoisVC {
            listView.setEmptyAlert(message)
        }*/
        EvrAlertView.showAlert(contentText: message, type: .info, showTime: 2)
    }
    
    public func viewModelCurrentDayChanged(_ currentDay: TRPPlan, order: Int) {
        setDayTitle(day: order + 1, date: currentDay.date)
    }
    
    public func viewModelShowInfoMessage(_ message: String) {

        EvrAlertView.showAlert(contentText: message.toLocalizedFromServer(), type: .info)
    }
    
    
    public func viewModel(drawRoute: Route?, wayPoints: [TRPLocation]) {
        guard let map = map, let route = drawRoute else {return}
        //Haritaya rota cizdirir.
        map.drawRoute(route, style: TRPMapView.DrawRouteStyle.rota)
    }
    
    public func viewModelCleanAnnotation() {
        guard let map = map else {return}
        // haritadaki annotationları temizler.
        if let oldRouteView = routeInfoView {
            oldRouteView.removeFromSuperview()
            routeInfoView = nil
        }
        map.clearAnnotation()
        searchAreaBtn?.setZoomLevelTreshold(20)
        
        mapStatus = .mapIsReady
        alternativeIsAdded = false
        isSearchThisArea = true
        map.removeRoute(style: TRPMapView.DrawRouteStyle.rota)
        map.removeRoute(style: TRPMapView.DrawRouteStyle.runtime)
        map.removePointsForAlternative(styleAnnotation: TRPMapView.StyleAnnotatoin.searchThisAreaPois)
        map.removePointsForAlternative(styleAnnotation: TRPMapView.StyleAnnotatoin.alternativePois)
    }
    
    
    // Annotation eklemek için
    public func viewModel(rotaPois: [TRPPoi]) {
        //FIXME: - Step e taşınabilir emin değilim
        guard let map = map else {return}
        var newAnnotations = [TRPPointAnnotation]()
        var poiData = [TRPLocation]()
        
        for (index, element) in rotaPois.enumerated() {
            let customAno = TRPPointAnnotation()
            var iconTag = element.icon
            //with offer icon
            if !element.offers.isEmpty {
                iconTag += "WithOffer"
            }
            customAno.imageName = TRPAppearanceSettings.MapAnnotations.getIcon(tag: iconTag, type: .route)
            //Hotel adresi varsa tespit eder.
            if viewModel.isHotelInTrip() {
                if index == 0 {
                    customAno.order = 1
                }else if index == rotaPois.count - 1 { // hotel varsa son poi  ekrana eklenmez.
                    break
                }
            }
            customAno.order = element.placeType == .hotel ? nil : index
            customAno.coordinate = CLLocationCoordinate2D(latitude: element.coordinate.lat, longitude: element.coordinate.lon)
            customAno.poiId = element.id
            customAno.isOffer = !element.offers.isEmpty
            newAnnotations.append(customAno)
            poiData.append(element.coordinate)
        }
        map.addAnnotations(newAnnotations)
        
        viewModel.calculateRouteForRotutinPoi(rotaPois)
        //Rotada sadece 1 mekan varsa cizim yapılmadığı için eklenen poi center yapılıyor
        if rotaPois.count == 1 {
            if let firstPoi =  rotaPois.first {
                rotaCenter = firstPoi.coordinate
                map.setCenter(rotaCenter!)
            }
        }else {
            if let firstPoi =  rotaPois.first {
                rotaCenter = firstPoi.coordinate
            }
        }
    }
    
    public func viewMode(steps: [TRPStep]) {
        //listOfRoutingPoisVM.setData(steps: steps)
    }
    
    public func viewModel(alternativePois pois: [TRPPoi]) {
        let annotations = pois.map{self.placeToMapFeature($0)}
        alternativePois = annotations
    }
    
    public func viewModel(searchThisArea: [TRPPoi], isOffer: Bool) {
        ////self.places = convertedData
        isSearchThisArea = false
        isSearchingOffer = false
        if searchThisArea.count > 0 {
            
            searchAreaBtn?.setZoomLevelTreshold(6)
            searchAreaBtn?.isHidden = false
        }else {
            let alertText = isOffer ? TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.offers.emptyOffersMessage") : TRPLanguagesController.shared.getLanguageValue(for: "no_results_in_area")
            EvrAlertView.showAlert(contentText: alertText, type: .info)
        }
        let annotations = searchThisArea.map{self.placeToMapFeature($0)}
        self.map?.addPointsForAlternative(annotations, styleAnnotation: TRPMapView.StyleAnnotatoin.searchThisAreaPois, clickAble: true)
    }
    
    
    
}

extension TRPTripModeVC: ListOfRoutingPoisVCDelegate {
    
    
    public func listOfRoutingTimeFramePressed() {
        changeTimePressed()
    }
    
    
    public func listOfRoutingStepReOrder(_ step: TRPStep, newOrder: Int) {
        viewModel.stepReOrder(stepId: step.id, newOrder: newOrder)
    }
    //TODO: REMOVE
    public func listOfRoutingShowStepAlternative(step: TRPStep) {
        
        var alternatives = [TRPPoi]()
        
        let alertName = TRPLanguagesController.shared.getLanguageValue(for: "alternative_locations") + " \(step.poi.name)"
        let alertController = UIAlertController(title: alertName, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        let actionButtonHandler = {(index:Int) in
            { (action: UIAlertAction!) -> Void in
                self.delegate?.trpTripModeViewControllerPoiDetail(self, poi: alternatives[index], parentStep: step)
            }
        }
        
        viewModel.getStepAlternatives(step) { pois in
            alternatives = pois
            for (index,poi) in pois.enumerated() {
                let button = UIAlertAction(title: "\(poi.name)", style: UIAlertAction.Style.default, handler: actionButtonHandler(index))
                alertController.addAction(button)
            }
        }
        
        let cancelButton = UIAlertAction(title: TRPLanguagesController.shared.getCancelBtnText(), style: UIAlertAction.Style.cancel) { (action) in}
        cancelButton.setValue(TRPAppearanceSettings.Common.cancelButtonColor, forKey: "titleTextColor")
        alertController.addAction(cancelButton)
        self.present(alertController, animated: true, completion: nil)
    }
    
    public func listOfRoutingOpenPoiDetail(poiId: String) {
        viewModel.getPoiInfo(poiId) { [weak self] poi in
            guard let poi = poi, let strongSelf = self else {return}
            strongSelf.delegate?.trpTripModeViewControllerPoiDetail(strongSelf, poi: poi, parentStep: nil)
        }
    }
    
    public func listOfRoutingRemoveStep(_ step: TRPStep) {
        viewModel.removePoiInRoute(poiId: step.poi.id)
    }
    
}

extension TRPTripModeVC {
    
//    func setupShowCityCenterButton() {
//
//        let circleR: CGFloat = 40
//        // guard let normalImg = TRPImageController().getImage(inFramework: "user_location", inApp: TRPAppearanceSettings.TripModeMapView.userLocationNormalImage) else {return}
//        guard let selectedImg = TRPImageController().getImage(inFramework: "route_location", inApp: TRPAppearanceSettings.TripModeMapView.userLocationSelectedImage) else {return}
//
//        showCityCenterBtn = TRPCirleButton(frame: CGRect.zero,
//                                           normalImage:selectedImg,
//                                           selectedImage: selectedImg,
//                                           isAutoSelection:false)
//        showCityCenterBtn!.translatesAutoresizingMaskIntoConstraints = false
//        showCityCenterBtn!.normalBg = UIColor.clear
//        showCityCenterBtn!.addTarget(self, action: #selector(showCityCenterPressed), for: UIControl.Event.touchUpInside)
//        view.addSubview(showCityCenterBtn!)
//        showCityCenterBtn!.widthAnchor.constraint(equalToConstant: circleR).isActive = true
//        showCityCenterBtn!.heightAnchor.constraint(equalToConstant: circleR).isActive = true
//        showCityCenterBtn!.centerXAnchor.constraint(equalTo: userLocationBtn.centerXAnchor, constant: 0).isActive = true
//        showCityCenterBtn!.bottomAnchor.constraint(equalTo: userLocationBtn.topAnchor, constant: -8).isActive = true
//        showCityCenterBtn!.isHidden = true
////        showCityCenterBtn!.isUserInteractionEnabled = false
//    }
    
    @objc func showCityCenterPressed() {
        guard let showCityCenterBtn = showCityCenterBtn else {return}
        showCityCenterBtn.isHidden = true
//        showCityCenterBtn.isUserInteractionEnabled = false
        if let center = rotaCenter {
            map?.setTrackingMode(TRPUserTrackingMode.none, animated: true)
            map?.setCenter(center, zoomLevel: 14)
            mapsInAnotherCity = false
        }
    }
    
    func checkCityCentered() {
        guard let userInCity = isUserInCity else {return}
        if userInCity == .outCity {
            showCityCenterBtn!.isHidden = false
            searchAreaBtn?.hidden()
//            showCityCenterBtn!.isUserInteractionEnabled = true
            mapsInAnotherCity = true
        }
    }
}

// MARK: User Location Button
extension TRPTripModeVC {
    
    private func openNavigation() {
        //TODO: BURAYA MEKANLARIN LİSTESİ VE STAR
        /*guard let turnByNavigation = turnByTurnNavigation else {return}
        openTurnByTurnAction()

        if turnByNavigation.routeIndex == 0 {
            turnByNavigation.wayPoints = viewModel.getRouteWayPoints()
            turnByNavigation.openNavigation()
        }else {
            turnByNavigation.resumeNavigation()
        }*/
    }
    
    
    private func openTurnByTurnAction() {
        let alertController = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        
        
        for place in viewModel.getPoiInRoute() {
            let placeButton = UIAlertAction(title: place.name, style: .default) { clicked in
                
            }
            let editIcon = TRPImageController().getImage(inFramework: "mytrip_edit", inApp: TRPAppearanceSettings.MyTrip.editTripImage)
            placeButton.setValue(editIcon?.withRenderingMode(.automatic), forKey: "image")
            alertController.addAction(placeButton)
        }
        
        let resumeButton = UIAlertAction(title: "Resume Navigation", style: UIAlertAction.Style.cancel) { (action) in
            
        }
        
        alertController.addAction(resumeButton)
        
        present(alertController, animated: true, completion: nil)
    }
    
    
    private func isLocationPermissionAccessable() -> (access:Bool,showAlert:Bool) {
        if CLLocationManager.locationServicesEnabled()  {
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined, .restricted, .denied:
                return (false, true)
            case .authorizedAlways, .authorizedWhenInUse:
                return (true, false)
            @unknown default:
                return (false, true)
            }
        }else {
            return (true, false)
        }
    }
    
}


extension TRPTripModeVC {
    
    func createSearchThisArea() {
        let title = TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.searchThisArea.title")
        searchAreaBtn = TRPSearchAreaButton(frame: calculateSearchButtonPosition(), title: title)
        guard let searchAreaBtn = searchAreaBtn else {return}
        
        searchAreaBtn.titleColor = UIColor(red: 41/255, green: 41/255, blue: 41/255, alpha: 1)
        searchAreaBtn.fontSize = 12
        searchAreaBtn.zoomLevelTrashHold = 20
        searchAreaBtn.addTarget(self, action: #selector(searchThisAreaPressed), for: UIControl.Event.touchUpInside)
        view.addSubview(searchAreaBtn)
        
        searchAreaBtn.backgroundColor = trpTheme.color.extraSub
        searchAreaBtn.layer.borderColor = trpTheme.color.extraShadow.cgColor
    }
    
    fileprivate func setSearchThisAreaButtonPosition() {
        guard let searchAreaBtn = searchAreaBtn else {return}
        searchAreaBtn.frame = calculateSearchButtonPosition()
    }
    
    fileprivate func calculateSearchButtonPosition() -> CGRect {
        let height: CGFloat = 30
        var width: CGFloat  = 140
        var topSpace: CGFloat = 0
        if let value = UIApplication.shared.keyWindow?.safeAreaInsets.top {
            topSpace = value
        }
        let startY: CGFloat = 24 + routeInfoViewPosition + topSpace
        
        if TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.searchThisArea.title").count > 20 {
            width = 200
        }
        return CGRect(x: (self.view.frame.width - width) / 2, y: startY, width: width, height: height)
    }
    
    @objc func searchThisAreaPressed() {
        if isSearchThisArea {
            selectTypeOfSearchProperty()
        }else {
            searchAreaBtn?.isHidden = true
            isSearchingOffer = false
            isSearchThisArea = true
            guard let map = map else {return}
            map.addPointsForAlternative([], styleAnnotation: TRPMapView.StyleAnnotatoin.searchThisAreaPois, clickAble: true)
        }
    }
    
    private func selectTypeOfSearchProperty() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        
        let restaurant = SearchAreaTypes(name: TRPPoiCategory.restaurants.getSingler(), ids: [TRPPoiCategory.restaurants.getId()])
        let cafes = SearchAreaTypes(name: TRPPoiCategory.cafes.getSingler(), ids: [TRPPoiCategory.cafes.getId()])
        
        let attractionTypes = AddPlaceMenu.attractions.addPlaceType().subTypes
        let attraction = SearchAreaTypes(name: TRPPoiCategory.attractions.getSingler(), ids:attractionTypes)
        
        let all = SearchAreaTypes(name: TRPLanguagesController.shared.getLanguageValue(for: "all"), ids: [])
        let types = [restaurant, cafes, attraction, all]
        
        let actionButtonHandler = { (index:Int) in
            { [weak self](action: UIAlertAction!) -> Void in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.searchPoi(types: types[index].ids)
            }
        }
        
        for (index, type) in types.enumerated() {
            let button = UIAlertAction(title: "\(type.name)", style: UIAlertAction.Style.default, handler: actionButtonHandler(index))
            alertController.addAction(button)
        }
        let cancelButton = UIAlertAction(title: TRPLanguagesController.shared.getCancelBtnText(), style: UIAlertAction.Style.cancel) { [weak self] (action) in
            self?.searchAreaBtn?.isHidden = true
        }
        cancelButton.setValue(TRPAppearanceSettings.Common.cancelButtonColor, forKey: "titleTextColor")
        alertController.addAction(cancelButton)
        present(alertController, animated: true, completion: nil)
    }
    
    fileprivate func searchPoi(types: [Int]? = nil) {
        loader!.show()
        /* if let clean = cleanResult {
         clean.hidden()
         } */
        
        guard let bounds = map?.visibleCoordinateBounds else { return }
        viewModel.searchThisArea(boundaryNorthEast: bounds.nE, boundarySouthWest: bounds.sW, typeId: types)
    }
    
    fileprivate func searchOffers() {
        if isSearchingOffer {
            return
        }
        isSearchingOffer = true
        guard let bounds = map?.visibleCoordinateBounds else { return }
        viewModel.searchOffers(boundaryNorthEast: bounds.nE, boundarySouthWest: bounds.sW)
    }
    
}

extension TRPTripModeVC {
    
    @objc func showAlternativePressed() {
        guard let map = map else {return}
        if alternativeIsAdded == false {
            map.addPointsForAlternative(alternativePois, styleAnnotation: TRPMapView.StyleAnnotatoin.alternativePois, clickAble: true)
            alternativeIsAdded.toggle()
        }else {
            map.addPointsForAlternative([], styleAnnotation: TRPMapView.StyleAnnotatoin.alternativePois, clickAble: true)
            alternativeIsAdded.toggle()
        }
    }
    
}


//MARK: - Nexus Tours
extension TRPTripModeVC {
    
    
    func showHideNexusTours() {
        guard let map = map else {return}
        if nexusToursAdded == false {
            viewModel.fetchJuniperTours()
        }else {
            map.addPointsForNexusTours([], styleAnnotation: TRPMapView.StyleAnnotatoin.nexusTours, clickAble: true)
            nexusToursAdded.toggle()
        }
    }
    
    func showNexusTours(tours: [JuniperProduct]) {
        if tours.isEmpty {
            showMessage(TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.localExperiences.toursEmpty"), type: .error)
            return
        }
        guard let map = map else {return}
        map.addPointsForNexusTours(tours, styleAnnotation: TRPMapView.StyleAnnotatoin.nexusTours, clickAble: true)
        nexusToursAdded.toggle()
    }
    
    private func selectTypeOfNexusTourSearch() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        
        let actionButtonHandler = { (category: String) in
            { [weak self](action: UIAlertAction!) -> Void in
                guard let strongSelf = self else {
                    return
                }
                let tours = strongSelf.viewModel.getJuniperTours(from: category)
                strongSelf.showNexusTours(tours: tours)
            }
        }
        
        for category in viewModel.getJuniperTourCategories() {
            let button = UIAlertAction(title: category, style: UIAlertAction.Style.default, handler: actionButtonHandler(category))
            alertController.addAction(button)
        }
        let cancelButton = UIAlertAction(title: TRPLanguagesController.shared.getCancelBtnText(), style: UIAlertAction.Style.cancel) { [weak self] (action) in
            self?.searchAreaBtn?.isHidden = true
        }
        cancelButton.setValue(TRPAppearanceSettings.Common.cancelButtonColor, forKey: "titleTextColor")
        alertController.addAction(cancelButton)
        present(alertController, animated: true, completion: nil)
    }
}

struct SearchAreaTypes {
    var name: String
    var ids: [Int]
}



class TurnByTurnStepSaver {
    
    private let TAG = "turn_by_turn_plan_step"
    private let planId: Int
    let userDefault = UserDefaults.standard
    
    
    
    init(planId: Int) {
        self.planId = planId
    }
    
    
    public func getLastCompletedPoi() -> String? {
        return getSteps().last
    }
  
    
    public func completedPoi(name: String) {
        guard var completedPlan = getModel() else {
            let data = ["\(planId)": [name]]
            userDefault.setValue(data, forKey: TAG)
            return
        }
        
        if completedPlan["\(planId)"] == nil {
            completedPlan["\(planId)"] = []
        }
        
        completedPlan["\(planId)"]!.append(name)
        userDefault.setValue(completedPlan, forKey: TAG)
    }
    
    private func getSteps() -> [String] {
        if let savedPlans = userDefault.object(forKey: TAG) as? [String: [String]] {
            if let plan = savedPlans.first(where: {$0.key == "\(planId)"}) {
                return plan.value
            }
        }
        return []
    }
    
    private func getModel() -> [String: [String]]?  {
        if let savedPlans = userDefault.object(forKey: TAG) as? [String: [String]] {
            return savedPlans
        }
        return nil
    }
    
    
    public func debug() {
        guard let model = getModel() else {
            print("[Error] Saved Navigation Model is nil")
            return
        }
        for item in model {
            for poi in item.value {
                print("TurnByTurn Plan: \(item.key) Place: \(poi)")
            }
        }
    }
    
}
