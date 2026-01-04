//
//  TRPTripModeCoordinater.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 13.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

public class TRPTripModeCoordinater {
    
    private var navigationController: UINavigationController
    private var tripModeViewController: TRPTripModeVC?
    private var userProfileAnswers = [Int]()
    public var user: TRPUser?
    private var yelpCoordinater: YelpCoordinater?
    private var experiencesCoordinater: TRPExperiencesCoordinater?
    private var selectedCity: TRPCity?
    private var addPlaceNavigation: UINavigationController?
    private var mustTryNavigation: UINavigationController?
    
    private var destinationId: Int = 0
    private var cityEngName: String = ""
    private var planDate: String = ""
    
    // USE CASES
    private(set) var tripRepository: TRPTripRepository
    private(set) var tripModelRepository: TripModelRepository
    public var fetchUserInfoUseCase: FetchUserInfoUseCase?
    
    
    private lazy var favoriteUseCases: TRPFavoriteUseCases = {
        return TRPFavoriteUseCases()
    }()
    
    private var poiRepository: PoiRepository = {
        return TRPPoiRepository()
    }()
    
    private lazy var tripModeUseCases: TRPTripModeUseCases = {
        return TRPTripModeUseCases(tripRepository: self.tripRepository, tripModelRepository: self.tripModelRepository, poiRepository: self.poiRepository)
    }()
    
    private lazy var poiUseCases: TRPPoiUseCases = {
        return TRPPoiUseCases(repository: self.poiRepository)
    }()
    
    private lazy var lastSearchUseCases: TRPLastSearchUseCases = {
        return TRPLastSearchUseCases()
    }()
    
    private lazy var reservationUseCases: TRPReservationUseCases = {
        return TRPReservationUseCases()
    }()
    
    private var reactionUseCases: TRPUserReactionUseCases = {
        return TRPUserReactionUseCases()
    }()
    
    private lazy var tourOptionsUseCases: TRPTourOptionsUseCases = {
        return TRPTourOptionsUseCases()
    }()
    
    private lazy var mapRouteUseCases: MapRouteUseCases = {
        return MapRouteUseCases()
    }()
    
    private lazy var offerUseCases: TRPOfferUseCases = {
        return TRPOfferUseCases()
    }()
    
    private lazy var bookingUseCases: TRPMakeBookingUseCases = {
        let useCases = TRPMakeBookingUseCases()
        useCases.optionDataHolder = tourOptionsUseCases
        return useCases
    }()
    
    
    
    public init(navigationController: UINavigationController,
                tripRepository: TRPTripRepository? = nil,
                tripModelRepository: TripModelRepository? = nil) {
        
        self.navigationController = navigationController
        self.tripRepository = tripRepository ?? TRPTripRepository()
        self.tripModelRepository = tripModelRepository ?? TRPTripModelRepository()
    }
    
    private lazy var fetchTripAllDay: TRPTripCheckAllPlanUseCases? = {
        return TRPTripCheckAllPlanUseCases(tripRepository: tripRepository, tripModelRepository: tripModelRepository)
    }()
    
    public func start() {
        
    }
    
    
}

extension TRPTripModeCoordinater {
    
    public func openTripModeVC(hash:String, city: TRPCity, startDay: Int = 0) {
        
        
        self.prepareDataControllers(hash: hash, city: city, startDay: startDay)
        //openOverView(tripHash: hash)
        
        let viewModel = TRPTripModeViewModel(tripHash: hash, city: city)
        viewModel.fetchTripUseCase = self.tripModeUseCases
        viewModel.tripModelObserverUseCase = self.tripModeUseCases
        viewModel.changeDayUseCase = self.tripModeUseCases
        viewModel.addStepUseCase = self.tripModeUseCases
        viewModel.removeStepUseCase = self.tripModeUseCases
        viewModel.editPlanUseCase = self.tripModeUseCases
        viewModel.fetchStepAlternative = self.tripModeUseCases
        viewModel.fetchPlanAlternative = self.tripModeUseCases
//        viewModel.reOrderStepUseCase = self.tripModeUseCases
        viewModel.searchThisAreaUseCase = self.poiUseCases
        viewModel.fetchPoiUseCase = self.poiUseCases
        viewModel.tripObserverUseCase = self.tripModeUseCases
        
        viewModel.fetchReactionUseCase = self.reactionUseCases
        viewModel.addReactionUseCase = self.reactionUseCases
        viewModel.updateReactionUseCase = self.reactionUseCases
        viewModel.deleteReactionUseCase = self.reactionUseCases
        viewModel.observeUserReaction = self.reactionUseCases
        viewModel.mapRouteUseCases = self.mapRouteUseCases
        
        viewModel.fetchOfferUseCase = self.offerUseCases
        viewModel.fetchOptInOfferUseCase = self.offerUseCases
        viewModel.observeOptInOfferUseCase = self.offerUseCases
        
        viewModel.exportItineraryUseCase = self.tripModeUseCases
        
        self.tripModeViewController = UIStoryboard.makeTripMode()
        self.tripModeViewController!.viewModel = viewModel
        viewModel.delegate = self.tripModeViewController!
        self.tripModeViewController!.delegate = self
        DispatchQueue.main.async {
            self.navigationController.pushViewController(self.tripModeViewController!, animated: true)
        }
        
        
    }
}

//MARK: - TRPTripMode Delegate
extension TRPTripModeCoordinater: TRPTripModeVCDelegate {
    public func trpTripModeViewControllerSetPlanDate(planDate: String) {
        self.planDate = planDate
    }
    
    public func trpTripModeViewControllerSetDestinationIdAndName(destinationId: Int, cityEngName: String) {
        self.destinationId = destinationId
        self.cityEngName = cityEngName
    }
    
    
    public func trpTripModeViewControllerOpenPlaces(_ viewController: UIViewController) {
        let placesContainer = makeAddPlacesContainer()
        let navigation = UINavigationController(rootViewController: placesContainer)
        navigation.modalPresentationStyle = .fullScreen
        navigation.navigationBar.prefersLargeTitles = false
        navigation.navigationItem.largeTitleDisplayMode = .always
        addPlaceNavigation = navigation
        
        setNavigationStyleFor(addPlaceNavigation!)
        viewController.present(addPlaceNavigation!, animated: true, completion: nil)
    }
    
    public func trpTripModeViewControllerOpenFavorites(_ viewController: UIViewController) {
        
        guard let favoriteViewController = makeFavoriteViewController() else {return }
        let navigation = UINavigationController(rootViewController: favoriteViewController)
        navigation.modalPresentationStyle = .fullScreen
        
        setupNavigationBar(navigation.navigationBar)
        viewController.present(navigation, animated: true, completion: nil)
    }
    
    public func trpTripModeViewControllerOpenExperience(_ viewController: UIViewController, startDate: String?, endDate: String?) {
        let navigation = UINavigationController()
        navigation.modalPresentationStyle = .fullScreen
        openExperienceCoordinater(nav: navigation, startDate: startDate, endDate: endDate)
        viewController.present(navigation, animated: true, completion: nil)
        setupNavigationBar(navigation.navigationBar)
    }
    
    public func trpTripModeViewControllerOpenBooking(_ viewController: UIViewController) {
        let bookingViewController = makeBookingViewController()
        let navigation = UINavigationController(rootViewController: bookingViewController)
        navigation.modalPresentationStyle = .fullScreen
        setNavigationStyleFor(navigation)
        setupNavigationBar(navigation.navigationBar)
        viewController.present(navigation, animated: true, completion: nil)
    }
    
    public func trpTripModeViewControllerPoiDetail(_ viewController: UIViewController, poi: TRPPoi, parentStep: TRPStep?) {
        let viewController = makePoiDetail(poi: poi, parentStep: parentStep)
        navigationController.present(viewController, animated: true)
    }
    
    public func trpTripModeViewControllerClearAndEditTrip(_ completionHandler: (Bool) -> Void) {
        var startIndex: Int?
        var endIndex: Int?
        for (index, vc) in navigationController.viewControllers.enumerated() {
            if vc.isKind(of: MyTripVC.self) {
                startIndex = index + 1
            }else if vc.isKind(of: TRPTripModeVC.self) {
                endIndex = index
            }
        }
        if let start = startIndex, let end = endIndex {
            navigationController.viewControllers.removeSubrange(start..<end)
        }
    }
    
    public func trpTripModeViewControllerOpenItinerary(_ viewController: UIViewController) {
        let navigation = UINavigationController(rootViewController: makeItineraryViewController())
        navigation.modalPresentationStyle = .fullScreen
        setupNavigationBar(navigation.navigationBar)
        viewController.present(navigation, animated: true, completion: nil)
    }
    
    public func trpTripModeViewControllerIsMovingFrom() {
        tripModeViewController = nil
    }
    
    public func trpTripModeViewControllerOpenMyOffers(_ viewController: UIViewController) {
        
        guard let myOffersViewController = makeMyOffersViewController() else {return }
        let navigation = UINavigationController(rootViewController: myOffersViewController)
        navigation.modalPresentationStyle = .fullScreen
        
        setupNavigationBar(navigation.navigationBar)
        viewController.present(navigation, animated: true, completion: nil)
    }
    
    public func trpTripModeViewControllerOpenCateogrySelect(_ viewController: UIViewController) {
        
        let viewModel = PoiCategoryViewModel(selectedCategories: [])
        let poiVC = UIStoryboard.makePoiCategoryViewController()
        poiVC.viewModel = viewModel
        poiVC.delegate = viewController as? any PoiCategoryVCDelegate
        viewModel.poiCategoriesUseCase = poiUseCases
        viewModel.delegate = poiVC
        viewController.present(poiVC, animated: true, completion: nil)
    }
    
    
    /// To set NavigationBar style.
    /// - Parameter nav: Target Naivgatation controller
    private func setNavigationStyleFor(_ nav: UINavigationController) {
        nav.navigationBar.barTintColor = trpTheme.color.extraBG
        nav.navigationBar.isTranslucent = false
        nav.navigationBar.setBackgroundImage(UIImage(), for:.default)
        nav.navigationBar.shadowImage = UIImage()
        nav.navigationBar.layoutIfNeeded()
    }
    
}

//MARK: - PrepareDatas
extension TRPTripModeCoordinater {
    
    private func prepareDataControllers(hash:String, city: TRPCity, startDay: Int = 0) {
        selectedCity = city
        poiUseCases.cityId = city.id
        favoriteUseCases.executeFetchFavorites(cityId: city.id, completion: nil)
        
        //        let currentDay = Date().toString(format: "yyyy-MM-dd", dateStyle: nil, timeStyle: nil)
        let beforeDay = Date().localDate().addDay(-1)!.toString(format: "yyyy-MM-dd", dateStyle: nil, timeStyle: nil)
        
        reservationUseCases.executefetchReservation(cityId: city.id, from: beforeDay, to: nil, completion: nil)
        
        fetchUserInfoUseCase?.executeFetchUserInfo(completion: { [weak self] result in
            if case .success(let userProfile) = result {
                self?.user = userProfile
            }
        })
        
        TRPUserLocationController.shared.start(city: city)
    }
    
}

extension TRPTripModeCoordinater: ItineraryViewControllerDelegate {
    func itineraryViewControllerChangeStepHour(_ viewController: ItineraryViewController, step: TRPStep?) {
        let selectHourVC = UIStoryboard.makeItineraryChangeTimeViewController() as ItineraryChangeTimeVC
        let viewModel = ItineraryChangeTimeViewModel()
        viewModel.step = step
        viewModel.start()
        viewModel.delegate = viewController
        selectHourVC.viewModel = viewModel
        viewController.present(selectHourVC, animated: true)
    }
    
    func itineraryViewControllerPoiDetail(_ viewController: ItineraryViewController, poi: TRPPoi, parentStep: TRPStep?) {
        let createdPlaceDetail = makePoiDetail(poi: poi, parentStep: parentStep, closeParent: viewController)
        viewController.present(createdPlaceDetail, animated: true, completion: nil)
    }
    
    
    private func makeItineraryViewController() -> UIViewController {
        let viewModel = ListOfRoutingPoisViewModel()
        let viewController = UIStoryboard.makeItineraryViewController()
        viewController.delegate = self
        viewController.viewModel = viewModel
        //listOfRoutingPoisVC.delegate = self
        viewModel.delegate = viewController
        
        viewModel.addReactionUseCase = reactionUseCases
        viewModel.deleteReactionUseCase  = reactionUseCases
        viewModel.updateReactionUseCase = reactionUseCases
        viewModel.fetchReactionUseCase = reactionUseCases
        viewModel.observeUserReaction = reactionUseCases
        viewModel.removeStepUseCase = tripModeUseCases
        viewModel.tripModelObserverUseCase = tripModeUseCases
        viewModel.editPlanUseCase = tripModeUseCases
        viewModel.editStepUseCase = tripModeUseCases
        viewModel.mapRouteUseCases = mapRouteUseCases
        viewModel.fetchStepAlternative = tripModeUseCases
        return viewController
    }
}

//MARK: - ADD PLACES
extension TRPTripModeCoordinater: AddPlacesContainerViewControllerDelegate, AddPoiTableViewVCDelegate {
    
    /// AddPlaceContainer ViewController'ı oluşturur
    /// - Returns: ViewController
    private func makeAddPlacesContainer() -> UIViewController {
        let viewModel = AddPlacesContainerViewModel()
        
        let viewController = UIStoryboard.makeAddPlacesContainer()
        viewController.viewModel = viewModel
        viewModel.tripModelObserverUseCase = tripModeUseCases
        viewModel.fetchCategoryPoiUseCase = poiUseCases
        viewModel.fetchNearByPoiUseCase = poiUseCases
        viewModel.searchPoiUseCase = poiUseCases
        viewModel.nextUrlPoiUseCase = poiUseCases
        viewModel.tripModelUseCase = tripModeUseCases
        viewModel.fetchAlternativeUseCase = tripModeUseCases
        
        viewModel.delegate = viewController
        viewController.delegate = self
        
        return viewController
    }
    
    
    /// AddPlace için child ViewController'ı AddPlaceType a göre oluşturur.
    /// - Parameter type: Restaurant, cafe etc için AddPlacesTypes
    /// - Returns: ViewController
    private func makeAddPlacesListView(type: AddPlaceTypes) -> UIViewController {
        
        let viewModel = AddPoisTableViewViewModel(placeType: type, contentMode: AddPlaceListContentType.recommendation)
        
        let viewController = UIStoryboard.makeAddPlaceViewController()
        viewController.viewModel = viewModel
        viewModel.tripModelObserverUseCase = tripModeUseCases
        viewModel.fetchCategoryPoiUseCase = poiUseCases
        viewModel.fetchNearByPoiUseCase = poiUseCases
        viewModel.searchPoiUseCase = poiUseCases
        viewModel.nextUrlPoiUseCase = poiUseCases
        viewModel.tripModelUseCase = tripModeUseCases
        viewModel.fetchAlternativeUseCase = tripModeUseCases
        
        viewModel.delegate = viewController
        viewController.delegate = self
        
        return viewController
    }
    
    
    public func addPlaceOpenPlace(_ viewController: UIViewController, poi: TRPPoi) {
        let createdPlaceDetail = makePoiDetail(poi: poi, closeParent: viewController)
        viewController.present(createdPlaceDetail, animated: true, completion: nil)
    }
    
    public func addPlaceTableViewViewControllerOpenPlace(_ viewController: UIViewController, poi: TRPPoi) {
        let createdPlaceDetail = makePoiDetail(poi: poi, closeParent: viewController)
        viewController.present(createdPlaceDetail, animated: true, completion: nil)
    }
    
    public func addPlaceSelectCategory(_ navigationController: UINavigationController, viewController: UIViewController, selectedCategories: [TRPPoiCategory]?) {
        
        let viewModel = PoiCategoryViewModel(selectedCategories: selectedCategories ?? [], forAddPlace: true)
        let poiVC = UIStoryboard.makePoiCategoryViewController()
        poiVC.viewModel = viewModel
        poiVC.delegate = viewController as? PoiCategoryVCDelegate
        viewModel.poiCategoriesUseCase = poiUseCases
        viewModel.delegate = poiVC
        viewController.present(poiVC, animated: true, completion: nil)
        
    }
    
}

//MARK: - Search Poi
//extension TRPTripModeCoordinater: PoiSearchVCDelegate {
//    
//    public func openPoiSearch(city: TRPCity){
//        
//        guard let city = selectedCity, let nav = addPlaceNavigation else {return}
//        let vc = makePoiSearchViewController(city: city)
//        nav.pushViewController(vc, animated: true)
//    }
//    
//    public func poiSearchOpenPlaceDetail(viewController:UIViewController, poi: TRPPoi) {
//        let createdPlaceDetail = makePoiDetail(poi: poi, closeParent: viewController)
//        viewController.present(createdPlaceDetail, animated: true, completion: nil)
//    }
//    
//    
//    public func makePoiSearchViewController(city: TRPCity, categoryType: AddPlaceTypes? = nil) -> UIViewController {
//        
//        lastSearchUseCases.poiCategory = categoryType?.id
//        
//        let viewModel = PoiSearchVM(city: city)
//        viewModel.searchPoiUseCases = poiUseCases
//        viewModel.addLastSearchUseCase = lastSearchUseCases
//        viewModel.deleteLastSearchUseCase = lastSearchUseCases
//        viewModel.fetchLastSearchUseCase = lastSearchUseCases
//        viewModel.observeLastSearchUseCase = lastSearchUseCases
//        
//        viewModel.categoryType = categoryType
//        
//        let viewController = PoiSearchVC(viewModel: viewModel)
//        viewModel.delegate = viewController
//        viewController.delegate = self
//        
//        viewModel.start()
//        return viewController
//    }
//}

//MARK: - Must Try
extension TRPTripModeCoordinater: MustTryTableViewViewControllerDelegate {
    
    
    private func makeMustTryTableView(tastes: [TRPTaste]) -> UIViewController {
        let viewModel = MustTryTableViewViewModel(tastes: tastes)
        let viewController = UIStoryboard.makeMustTryContainer()// MustTryTableViewViewController(viewModel: viewModel)
        viewController.viewModel = viewModel
        viewController.delegate = self
        return viewController
    }
    
    public func mustTryTableViewVCOpenTasteDetail(_ navigationController: UINavigationController?,
                                                  viewController: UIViewController,
                                                  taste: TRPTaste) {
        let _viewController = makeMustTryDetail(taste: taste)
        //        let nav = UINavigationController(rootViewController: _viewController)
        //        nav.modalPresentationStyle = .fullScreen
        //        nav.navigationBar.prefersLargeTitles = true
        //        setNavigationStyleFor(nav)
        //        mustTryNavigation = nav
        viewController.present(_viewController, animated: true, completion: nil)
    }
    
}

//MARK: - Must Try
extension TRPTripModeCoordinater: MustTryDetailVCDelegate {
    
    
     private func makeMustTryDetail(taste: TRPTaste) -> UIViewController {
        
        let viewModel = MustTryDetailViewModel(taste: taste)
        
        let viewController = MustTryDetailViewController(viewModel: viewModel)
        viewController.delegate = self
        
        viewModel.fetchTastePoisUseCase = poiUseCases
        viewModel.tripModelUseCase = tripModeUseCases
        
        viewModel.delegate = viewController
        
        let navigation = UINavigationController()
        navigation.pushViewController(viewController, animated: false)
        navigation.modalPresentationStyle = .fullScreen
        return navigation
    }
    
     public func mustTryDetailVCDelegateOpenPlaceDetail(_ viewController: UIViewController, poi: TRPPoi) {
        let createdPlaceDetail = makePoiDetail(poi: poi, closeParent: viewController)
        viewController.present(createdPlaceDetail, animated: true, completion: nil)
    }
    
}

//MARK: - Favorite
extension TRPTripModeCoordinater: FavoritesVCDelegate {
    
     func makeFavoriteViewController() -> UIViewController? {
        guard let city = selectedCity else {return nil}
        
        let viewModel = FavoritesViewModel(cityId: city.id)
        viewModel.fetchPoiWithIdUseCase = poiUseCases
        viewModel.observeFavoriteUseCase = favoriteUseCases
        
        let viewController = UIStoryboard.makeFavoriteViewController()
        viewController.viewModel = viewModel
        
        viewController.delegate = self
        viewModel.delegate = viewController
        
        
        return viewController
    }
    
     public func favoriteVCOpenPlaceDetail(viewController: UIViewController, poi: TRPPoi) {
        let createdPlaceDetail = makePoiDetail(poi: poi, closeParent: viewController)
        viewController.present(createdPlaceDetail, animated: true, completion: nil)
    }
}


//MARK: - Booking
extension TRPTripModeCoordinater {
    
     private func makeBookingViewController() -> UIViewController {
        let viewModel = BookingListViewModel()
        viewModel.observerReservationUseCase = reservationUseCases
        viewModel.deleteReservartionUseCase = reservationUseCases
        viewModel.updateReservationUseCase = reservationUseCases
        
        let viewController = BookingListViewController(viewModel: viewModel)
        viewModel.delegate = viewController
        viewModel.start()
        return viewController
    }
    
}


//MARK: - PlaceDetail
extension TRPTripModeCoordinater: PlaceDetailVCProtocol {
    
    public func placeDetail(addRemoveStatus: AddRemovePoiStatus, place: TRPPoi) {}
    
     public func placeDetail(navigation place: TRPPoi) {
        guard let tripMode = tripModeViewController else {return}
        tripMode.drawRoute(poi: place)
    }
    
     public func closeParent(parentVc: UIViewController?) {
        parentVc?.dismiss(animated: true, completion: nil)
        if addPlaceNavigation != nil {
            addPlaceNavigation?.dismiss(animated: true, completion: nil)
        }
        if mustTryNavigation != nil {
            mustTryNavigation?.dismiss(animated: true, completion: nil)
        }
    }
    
     public func placeDetailMakeAReservation(_ viewController: UIViewController, booking: TRPBooking?, poi: TRPPoi) {
        if let businessId = booking?.products?.first?.id {
            openYelpCoordinater(businessId: businessId, poi: poi, parentViewController: viewController)
        }
    }
    
}

extension TRPTripModeCoordinater: PoiDetailViewControllerDelegate {
    
    func poiDetailDrawNavigation(_ viewController: UIViewController, place: TRPPoi) {
        guard let tripMode = tripModeViewController else {return}
        tripMode.drawRoute(poi: place)
    }
    
    func poiDetailCloseParentViewController(_ viewController: UIViewController, parentViewController: UIViewController?) {
        parentViewController?.dismiss(animated: true, completion: nil)
        if addPlaceNavigation != nil {
            addPlaceNavigation?.dismiss(animated: true, completion: nil)
        }
        if mustTryNavigation != nil {
            mustTryNavigation?.dismiss(animated: true, completion: nil)
        }
    }
    
    func poiDetailOpenMakeAReservation(_ viewController: UIViewController, booking: TRPBooking?, poi: TRPPoi) {
        
        //        openYelpCoordinater(businessId: "rC5mIHMNF5C1Jtpb2obSkA", poi: poi, parentViewController: viewController)
        //TODO: TÜM RESTAURANTLARDA BOOKİNG GÖRÜNMESİ İÇİN KONTROL KAPATILDI
        if let businessId = booking?.products?.first?.id {
            openYelpCoordinater(businessId: businessId, poi: poi, parentViewController: viewController)
        }
    }
    
    
    func poiDetailVCOpenTourDetail(_ navigationController: UINavigationController?,
                                   viewController: UIViewController,
                                   bookingProduct: TRPBookingProduct) {
        
        guard let tourId = Int(bookingProduct.id) else {return}
        
        let navigation = UINavigationController()
        navigation.modalPresentationStyle = .fullScreen
        openExperienceCoordinater(nav: navigation, tourId: tourId)
        viewController.present(navigation, animated: true, completion: nil)
        setupNavigationBar(navigation.navigationBar)
    }
    
    fileprivate func makePoiDetail(poi: TRPPoi,
                                   parentStep: TRPStep? = nil,
                                   closeParent: UIViewController? = nil) -> UINavigationController {
        
        let viewModel = PoiDetailViewModel(place: poi,
                                           parentStep: parentStep,
                                           destinationId: destinationId,
                                           cityEngName: cityEngName,
                                           planDate: planDate)
        
        viewModel.addFavoriteUseCase = favoriteUseCases
        viewModel.deleteFavoriteUseCase = favoriteUseCases
        viewModel.observeFavoriteUseCase = favoriteUseCases
        viewModel.addStepUseCase = tripModeUseCases
        viewModel.deleteStepUseCase = tripModeUseCases
        viewModel.replaceWithAlternativeUseCase = tripModeUseCases
        viewModel.observeReservationUseCase = reservationUseCases
        viewModel.deleteReservationUseCase = reservationUseCases
        viewModel.tripModelUseCases = tripModeUseCases
        
        viewModel.addOptInOfferUseCase = offerUseCases
        viewModel.deleteOptInOfferUseCase = offerUseCases
        viewModel.observeOptInOfferUseCase = offerUseCases
        viewModel.fetchOptInOfferUseCase = offerUseCases
        
        let viewController = UIStoryboard.makePoiDetailViewController()
        viewController.viewModel = viewModel
        //        let viewController = PoiDetailViewController(viewModel: viewModel)
        viewController.delegate = self
        viewController.closeParent = closeParent
        viewModel.delegate = viewController
        
        let navigation = UINavigationController()
        navigation.pushViewController(viewController, animated: false)
        navigation.modalPresentationStyle = .fullScreen
        
        return navigation
    }
    
}

//MARK: - LOCAL EXPERIENCE
extension TRPTripModeCoordinater {
    
    private func openExperienceCoordinater(nav: UINavigationController, tourId: Int? = nil, startDate: String? = nil, endDate: String? = nil) {
//        guard let cityName = selectedCity?.name else {return}
        experiencesCoordinater = TRPExperiencesCoordinater(navigationController: nav, cityName: cityEngName, destinationId: destinationId, tourId: tourId, startDate: startDate, endDate: endDate)
        experiencesCoordinater?.tripModeUseCases = tripModeUseCases
        experiencesCoordinater?.reservationUseCases = reservationUseCases
        experiencesCoordinater?.start()
    }
    
}



//MARK: - YELP COORDİNATER
extension TRPTripModeCoordinater: YelpCoordinaterDelegate {
    
     private func openYelpCoordinater(businessId: String, poi: TRPPoi, parentViewController: UIViewController) {
        
        let tripHash: String? = tripModeUseCases.trip.value?.tripHash ?? nil
        let totalPeople = tripModeUseCases.trip.value?.tripProfile.getTotalPeopleCount() ?? 1
        let reservationDay = getReservationDate()
        let reservationHour = getStepTime(placeId: poi.id)
        
        let reservation = Reservation(businessId: businessId, covers: totalPeople, date: reservationDay, time: reservationHour)
        reservation.firstName = user?.firstName ?? ""
        reservation.lastName = user?.lastName ?? ""
        reservation.email = user?.email ?? ""
        reservation.poiId = poi.id
        reservation.poiName = poi.name
         reservation.poiImage = poi.image?.url
        reservation.tripHash = tripHash
        
        let yelpNavigationController = UINavigationController()
        yelpCoordinater = YelpCoordinater(navigationController: yelpNavigationController, reservation: reservation)
        yelpCoordinater!.delegate = self
        yelpCoordinater!.start()
        parentViewController.present(yelpNavigationController, animated: true, completion: nil)
    }
    
    private func getReservationDate() -> String {
        if let tripDay = tripModeUseCases.dailyPlan.value?.date{
            return tripDay
        }
        return Date().localDate().toString(format: "YYYY-MM-dd")
    }
    
    
    private func getStepTime(placeId: String) -> String {
        //Todo: Step hour step den alınacak
        return "16:30"
    }
    
     public func yelpCoordinaterReservationCompleted(_ viewController: UIViewController, reservation: Reservation, business: YelpBusiness?, result: YelpReservation) {
        viewController.dismiss(animated: true)
        EvrAlertView.showAlert(contentText: TRPLanguagesController.shared.getLanguageValue(for: "success"), type: .success)
        var detail: TRPYelpReservationDetail?
        
        if let business = business {
            detail = TRPYelpReservationDetail(businessID: business.id,
                                              covers: reservation.covers,
                                              time: reservation.time,
                                              date: reservation.date,
                                              uniqueID: reservation.uniqueId,
                                              phone: reservation.phone,
                                              holdID: reservation.holdId,
                                              firstName: reservation.firstName,
                                              lastName: reservation.lastName,
                                              email: reservation.email)
            
        }
        
        let yelp = TRPYelp(confirmURL: result.confirmationUrl,
                           reservationID: result.reservationId,
                           restaurantImage: reservation.poiImage,
                           restaurantName:reservation.poiName,
                           reservationDetail: detail)
        
        reservationUseCases.executeAddReservation(key: "YELP", provider: "YELP", tripHash: reservation.tripHash, poiId: reservation.poiId, values: yelp.getParams()) { result in
            switch result {
            case .success(let reservation):
                print("Reservasyon Sonucu: \(reservation)")
            case .failure(let error):
                print("Reservasyon Hatası: \(error.localizedDescription)")
            }
        }
        
        //TODO: SUNUCUYA RESERVASYON BİLGİLERİ GÖNDERİLECEK.
        
    }
    
    
    
     func setupNavigationBar(_ navigationBar: UINavigationBar, barTintColor: UIColor = trpTheme.color.extraBG) {
        navigationBar.barTintColor = barTintColor
        navigationBar.isTranslucent = false
        navigationBar.setBackgroundImage(UIImage(), for:.default)
        navigationBar.shadowImage = UIImage()
        navigationBar.layoutIfNeeded()
    }
}


//MARK: - OFFERS
extension TRPTripModeCoordinater: MyOffersVCDelegate {
    
    
     func makeMyOffersViewController() -> UIViewController? {
        let viewModel = MyOffersViewModel()
        viewModel.fetchOptInOfferUseCase = offerUseCases
        viewModel.observeOptInOfferUseCase = offerUseCases
        viewModel.deleteOptInOfferUseCase = offerUseCases
        
        let viewController = UIStoryboard.makeMyOffersViewController()
        viewController.viewModel = viewModel
        
        viewController.delegate = self
        viewModel.delegate = viewController
        
        return viewController
    }
    
     public func myOffersVCOpenPlaceDetail(viewController: UIViewController, poi: TRPPoi) {
        let createdPlaceDetail = makePoiDetail(poi: poi, closeParent: viewController)
        viewController.present(createdPlaceDetail, animated: true, completion: nil)
        
    }
}




