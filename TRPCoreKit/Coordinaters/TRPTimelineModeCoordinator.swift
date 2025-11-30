////
////  TRPTripModeCoordinater.swift
////  TRPCoreKit
////
////  Created by Evren Yaşar on 13.07.2020.
////  Copyright © 2020 Tripian Inc. All rights reserved.
////
//
//import Foundation
//import TRPFoundationKit
//import TRPRestKit
//import UIKit
//
//protocol TRPTimelineModeCoordinatorDelegate: TRPBaseCoordinatorProtocol {
//    func timelineCoordinatorCreateNewSegment(_ viewController: UIViewController, city: TRPCity)
//    func timelineCoordinatorEditSegment(_ viewController: UIViewController, city: TRPCity, segmentProfile: TRPCreateEditTimelineSegmentProfile)
//    func timelineCoordinatorUpdatePlanName(_ viewController: UIViewController, currentName: String, planId: String)
//}
//
//public class TRPTimelineModeCoordinator: CoordinatorProtocol {
//    var navigationController: UINavigationController?
//    
//    var childCoordinators: [any CoordinatorProtocol] = []
//    
//    private var timelineModeViewController: TRPTimelineModeVC?
//    private var userProfileAnswers = [Int]()
//    public var user: TRPUser?
//    private var yelpCoordinater: YelpCoordinater?
//    private var experiencesCoordinater: TRPExperiencesCoordinater?
//    private var selectedCity: TRPCity?
//    private var addPlaceNavigation: UINavigationController?
//    private var mustTryNavigation: UINavigationController?
//    private var toursBetweenTripDate: [GYGTour] = []
//    
//    // USE CASES
//    private(set) var timelineRepository: TRPTimelineRepository
//    private(set) var timelineModelRepository: TimelineModelRepository
//    public var fetchUserInfoUseCase: FetchUserInfoUseCase?
//    public var fetchCityUseCase: FetchCityUseCase?
//    
//    weak var delegate: TRPTimelineModeCoordinatorDelegate?
//    
//    private lazy var favoriteUseCases: TRPFavoriteUseCases = {
//        return TRPFavoriteUseCases()
//    }()
//    
//    private var poiRepository: PoiRepository = {
//        return TRPPoiRepository()
//    }()
//    
//    private lazy var timelineModeUseCases: TRPTimelineModeUseCases = {
//        return TRPTimelineModeUseCases(timelineRepository: self.timelineRepository,
//                                       timelineModelRepository: self.timelineModelRepository,
//                                       poiRepository: self.poiRepository)
//    }()
//    
//    private lazy var poiUseCases: TRPPoiUseCases = {
//        return TRPPoiUseCases(repository: self.poiRepository)
//    }()
//    
//    private lazy var lastSearchUseCases: TRPLastSearchUseCases = {
//        return TRPLastSearchUseCases()
//    }()
//    
//    private lazy var reservationUseCases: TRPReservationUseCases = {
//        return TRPReservationUseCases()
//    }()
//    
//    private var reactionUseCases: TRPUserReactionUseCases = {
//        return TRPUserReactionUseCases()
//    }()
//    
//    private lazy var mapRouteUseCases: MapRouteUseCases = {
//        return MapRouteUseCases()
//    }()
//    
//    private lazy var createTimelineSegmentUseCase: TRPCreateTimelineSegmentUseCase = {
//        return TRPCreateTimelineSegmentUseCase(repository: self.timelineRepository)
//    }()
//    
//    private lazy var editTimelineSegmentUseCase: TRPEditTimelineUseCases = {
//        return TRPEditTimelineUseCases(repository: self.timelineRepository)
//    }()
//    
//    private lazy var deleteTimelineSegmentUseCase: TRPDeleteTimelineSegmentUseCase = {
//        return TRPDeleteTimelineSegmentUseCase(repository: self.timelineRepository)
//    }()
//    
//    private lazy var fetchTimelineAllSegments: TRPTimelineCheckAllPlanUseCases? = {
//        return TRPTimelineCheckAllPlanUseCases(timelineRepository: timelineRepository,
//                                               timelineModelRepository: timelineModelRepository)
//    }()
//    
//    public init(navigationController: UINavigationController?,
//                timelineRepository: TRPTimelineRepository? = nil,
//                timelineModelRepository: TimelineModelRepository? = nil) {
//        
//        self.navigationController = navigationController
//        self.timelineRepository = timelineRepository ?? TRPTimelineRepository()
//        self.timelineModelRepository = timelineModelRepository ?? TRPTimelineModelRepository()
//    }
//    
//    private lazy var fetchTripAllDay: TRPTimelineCheckAllPlanUseCases? = {
//        return TRPTimelineCheckAllPlanUseCases(timelineRepository: timelineRepository, timelineModelRepository: timelineModelRepository)
//    }()
//    
//    public func start() {
//        
//    }
//    
//    
//}
//
//extension TRPTimelineModeCoordinator {
//    
//    public func openTripModeVC(hash:String, city: TRPCity, startDay: Int = 0) {
//
//        prepareDataControllers(hash: hash, city: city, startDay: startDay)
//        //openOverView(tripHash: hash)
//        
//        let viewModel = TRPTimelineModeViewModel(tripHash: hash, city: city)
//        viewModel.fetchTimelineUseCases = timelineModeUseCases
//        viewModel.timelineModelObserverUseCase = timelineModeUseCases
//        viewModel.changeDayUseCase = timelineModeUseCases
//        viewModel.addStepUseCase = timelineModeUseCases
//        viewModel.removeStepUseCase = timelineModeUseCases
//        viewModel.editStepUseCase = timelineModeUseCases
//        viewModel.editPlanUseCase = timelineModeUseCases
//        viewModel.fetchStepAlternative = timelineModeUseCases
//        viewModel.fetchPlanAlternative = timelineModeUseCases
////        viewModel.reOrderStepUseCase = tripModeUseCases
//        viewModel.searchThisAreaUseCase = poiUseCases
//        viewModel.fetchPoiUseCase = poiUseCases
//        viewModel.tripObserverUseCase = timelineModeUseCases
//        viewModel.deleteTimelineSegmentUseCase = deleteTimelineSegmentUseCase
//        viewModel.createTimelineSegmentUseCase = createTimelineSegmentUseCase
//        viewModel.editTimelineUseCase = editTimelineSegmentUseCase
//        viewModel.fetchTimelineAllPlan = fetchTimelineAllSegments
//        viewModel.observeTimelineAllPlan = fetchTimelineAllSegments
//        viewModel.fetchCityUseCase = fetchCityUseCase
//        
//        viewModel.fetchReactionUseCase = reactionUseCases
//        viewModel.addReactionUseCase = reactionUseCases
//        viewModel.updateReactionUseCase = reactionUseCases
//        viewModel.deleteReactionUseCase = reactionUseCases
//        viewModel.observeUserReaction = reactionUseCases
//        viewModel.mapRouteUseCases = mapRouteUseCases
//        
//        viewModel.addFavoriteUseCase = favoriteUseCases
//        viewModel.deleteFavoriteUseCase = favoriteUseCases
//        viewModel.observeFavoriteUseCase = favoriteUseCases
//        
//        viewModel.exportItineraryUseCase = timelineModeUseCases
//        
//        timelineModeViewController = UIStoryboard.makeTimelineMode()
//        timelineModeViewController!.viewModel = viewModel
//        viewModel.delegate = timelineModeViewController!
//        timelineModeViewController!.delegate = self
//        
//        let navigation = UINavigationController(rootViewController: timelineModeViewController!)
//        navigation.modalPresentationStyle = .fullScreen
//        navigationController?.present(navigation, animated: true, completion: nil)
//        
//    }
//}
//
////MARK: - TRPTripMode Delegate
//extension TRPTimelineModeCoordinator: TRPTimelineModeVCDelegate {
//    public func trpTimelineModeVCAddSegment(_ viewController: UIViewController, city: TRPCity) {
//        delegate?.timelineCoordinatorCreateNewSegment(viewController, city: city)
//    }
//    public func trpTimelineModeVCEditSegment(_ viewController: UIViewController, city: TRPCity, segmentProfile: TRPCreateEditTimelineSegmentProfile) {
//        delegate?.timelineCoordinatorEditSegment(viewController, city: city, segmentProfile: segmentProfile)
//    }
//    
//    public func trpTimelineModeVCUpdatePlanName(_ viewController: UIViewController, currentName: String, planId: String) {
//        delegate?.timelineCoordinatorUpdatePlanName(viewController, currentName: currentName, planId: planId)
//    }
//    
//    public func trpTripModeViewControllerOpenCateogrySelect(_ viewController: UIViewController) {
//        
//        let viewModel = PoiCategoryViewModel(selectedCategories: [])
//        let poiVC = UIStoryboard.makePoiCategoryViewController()
//        poiVC.viewModel = viewModel
//        poiVC.delegate = viewController as? any PoiCategoryVCDelegate
//        viewModel.poiCategoriesUseCase = poiUseCases
//        viewModel.delegate = poiVC
//        viewController.present(poiVC, animated: true, completion: nil)
//    }
//    
//    public func trpTripModeViewControllerSetTours(tours: [GYGTour]) {
//        self.toursBetweenTripDate = tours
//    }
//    
//    
//    public func trpTripModeViewControllerOpenPlaces(_ viewController: UIViewController) {
//        let placesContainer = makeAddPlacesContainer()
//        let navigation = UINavigationController(rootViewController: placesContainer)
//        navigation.modalPresentationStyle = .fullScreen
//        navigation.navigationBar.prefersLargeTitles = false
//        navigation.navigationItem.largeTitleDisplayMode = .always
//        addPlaceNavigation = navigation
//        
//        setNavigationStyleFor(addPlaceNavigation!)
//        viewController.present(addPlaceNavigation!, animated: true, completion: nil)
//    }
//    
//    public func trpTripModeViewControllerOpenFavorites(_ viewController: UIViewController) {
//        
//        guard let favoriteViewController = makeFavoriteViewController() else {return }
//        let navigation = UINavigationController(rootViewController: favoriteViewController)
//        navigation.modalPresentationStyle = .fullScreen
//        
//        setupNavigationBar(navigation.navigationBar)
//        viewController.present(navigation, animated: true, completion: nil)
//    }
//    
//    public func trpTripModeViewControllerOpenExperience(_ viewController: UIViewController) {
//        let navigation = UINavigationController()
//        navigation.modalPresentationStyle = .fullScreen
//        openExperienceCoordinater(nav: navigation)
//        viewController.present(navigation, animated: true, completion: nil)
//        setupNavigationBar(navigation.navigationBar)
//    }
//    
//    public func trpTripModeViewControllerOpenBooking(_ viewController: UIViewController) {
//        let bookingViewController = makeBookingViewController()
//        let navigation = UINavigationController(rootViewController: bookingViewController)
//        navigation.modalPresentationStyle = .fullScreen
//        setNavigationStyleFor(navigation)
//        setupNavigationBar(navigation.navigationBar)
//        viewController.present(navigation, animated: true, completion: nil)
//    }
//    
//    public func trpTripModeViewControllerPoiDetail(_ viewController: UIViewController, poi: TRPPoi, parentStep: TRPTimelineStep?) {
//        let poidetailVC = makePoiDetail(poi: poi, parentStep: parentStep)
//        viewController.present(poidetailVC, animated: true)
//    }
//    
//    public func trpTripModeViewControllerClearAndEditTrip(_ completionHandler: (Bool) -> Void) {
//        var startIndex: Int?
//        var endIndex: Int?
//        guard let navigationController else { return}
//        for (index, vc) in navigationController.viewControllers.enumerated() {
//            if vc.isKind(of: MyTripVC.self) {
//                startIndex = index + 1
//            }else if vc.isKind(of: TRPTripModeVC.self) {
//                endIndex = index
//            }
//        }
//        if let start = startIndex, let end = endIndex {
//            navigationController.viewControllers.removeSubrange(start..<end)
//        }
//    }
//    
//    public func trpTripModeViewControllerIsMovingFrom() {
//        timelineModeViewController = nil
//    }
//    
//    public func trpTripModeViewControllerOpenMyOffers(_ viewController: UIViewController) {
//        
//        guard let myOffersViewController = makeMyOffersViewController() else {return }
//        let navigation = UINavigationController(rootViewController: myOffersViewController)
//        navigation.modalPresentationStyle = .fullScreen
//        
//        setupNavigationBar(navigation.navigationBar)
//        viewController.present(navigation, animated: true, completion: nil)
//    }
//    
//    public func trpTimelineModeVCSelectLocation(_ viewController: UIViewController, city: TRPCity) {
//        delegate?.showSelectAddressVC(viewController, city: city)
//    }
//    
//    
//    /// To set NavigationBar style.
//    /// - Parameter nav: Target Naivgatation controller
//    private func setNavigationStyleFor(_ nav: UINavigationController) {
//        nav.navigationBar.barTintColor = trpTheme.color.extraBG
//        nav.navigationBar.isTranslucent = false
//        nav.navigationBar.setBackgroundImage(UIImage(), for:.default)
//        nav.navigationBar.shadowImage = UIImage()
//        nav.navigationBar.layoutIfNeeded()
//    }
//    
//}
//
////MARK: - PrepareDatas
//extension TRPTimelineModeCoordinator {
//    
//    private func prepareDataControllers(hash:String, city: TRPCity, startDay: Int = 0) {
//        selectedCity = city
//        poiUseCases.cityId = city.id
//        favoriteUseCases.executeFetchFavorites(cityId: city.id, completion: nil)
//        
////        let currentDay = Date().toString(format: "yyyy-MM-dd", dateStyle: nil, timeStyle: nil)
//        let beforeDay = Date().addDay(-1)!.toString(format: "yyyy-MM-dd", dateStyle: nil, timeStyle: nil)
//    
//        reservationUseCases.executefetchReservation(cityId: city.id, from: beforeDay, to: nil, completion: nil)
//        
//        fetchUserInfoUseCase?.executeFetchUserInfo(completion: { [weak self] result in
//            if case .success(let userProfile) = result {
//                self?.user = userProfile
//            }
//        })
//        
//        TRPUserLocationController.shared.start(city: city)
//    }
//    
//}
//
//extension TRPTimelineModeCoordinator {
//    func itineraryViewControllerPoiDetail(_ viewController: ItineraryViewController, poi: TRPDataLayer.TRPPoi, parentStep: TRPDataLayer.TRPStep?) {
//        
//    }
//    
//    public func trpTimelineModeVCChangeStepHour(_ viewController: UIViewController, step: TRPTimelineStep?) {
//        let selectHourVC = getChangeHourVC(viewController)
//        selectHourVC.viewModel.timelineStep = step
//        viewController.showPageSheet(destination: selectHourVC)
//    }
//    
//    public func trpTimelineModeVCChangeCustomStepHour(_ viewController: UIViewController, location: TRPLocation?, address: String?, accommodation: TRPAccommodation?) {
//        let addCustomStep = UIStoryboard.makeAddSegmentStepVC() as TRPAddSegmentStepVC
//        let viewModel = TRPAddSegmentStepViewModel()
//        viewModel.location = location
//        viewModel.address = address
//        viewModel.accommodation = accommodation
//        addCustomStep.viewModel = viewModel
//        addCustomStep.delegate = viewController as? TRPAddSegmentStepVCDelegate
//        addCustomStep.coordinatorDelegate = delegate
//        viewController.showPageSheet(destination: addCustomStep, onlyLarge: true, backgroundColor: .white)
//    }
//    
//    private func getChangeHourVC(_ viewController: UIViewController) -> ItineraryChangeTimeVC {
//        let selectHourVC = UIStoryboard.makeItineraryChangeTimeViewController() as ItineraryChangeTimeVC
//        let viewModel = ItineraryChangeTimeViewModel()
//        viewModel.delegate = viewController as? ItineraryChangeTimeViewModelDelegate
//        selectHourVC.viewModel = viewModel
//        return selectHourVC
//    }
//    
//    
//    func itineraryViewControllerPoiDetail(_ viewController: ItineraryViewController, poi: TRPPoi, parentStep: TRPTimelineStep?) {
//        let createdPlaceDetail = makePoiDetail(poi: poi, parentStep: parentStep, closeParent: viewController)
//        viewController.present(createdPlaceDetail, animated: true, completion: nil)
//    }
//    
//}
//
//extension TRPTimelineModeCoordinator {
//    
//}
//
////MARK: - ADD PLACES
//extension TRPTimelineModeCoordinator: AddPlacesContainerViewControllerDelegate, AddPoiTableViewVCDelegate {
//    
//    
//    /// AddPlaceContainer ViewController'ı oluşturur
//    /// - Returns: ViewController
//    private func makeAddPlacesContainer() -> UIViewController {
//        let viewModel = AddPlacesContainerViewModel()
//        
//        let viewController = UIStoryboard.makeAddPlacesContainer()
//        viewController.viewModel = viewModel
////        viewModel.tripModelObserverUseCase = timelineModeUseCases
//        viewModel.fetchCategoryPoiUseCase = poiUseCases
//        viewModel.fetchNearByPoiUseCase = poiUseCases
//        viewModel.searchPoiUseCase = poiUseCases
//        viewModel.nextUrlPoiUseCase = poiUseCases
////        viewModel.tripModelUseCase = timelineModeUseCases
//        viewModel.fetchAlternativeUseCase = timelineModeUseCases
//        
//        viewModel.delegate = viewController
//        viewController.delegate = self
//        
//        return viewController
//    }
//    
//    
//    /// AddPlace için child ViewController'ı AddPlaceType a göre oluşturur.
//    /// - Parameter type: Restaurant, cafe etc için AddPlacesTypes
//    /// - Returns: ViewController
//    private func makeAddPlacesListView(type: AddPlaceTypes) -> UIViewController {
//        
//        let viewModel = AddPoisTableViewViewModel(placeType: type, contentMode: AddPlaceListContentType.recommendation)
//        
//        let viewController = UIStoryboard.makeAddPlaceViewController()
//        viewController.viewModel = viewModel
////        viewModel.tripModelObserverUseCase = timelineModeUseCases
//        viewModel.fetchCategoryPoiUseCase = poiUseCases
//        viewModel.fetchNearByPoiUseCase = poiUseCases
//        viewModel.searchPoiUseCase = poiUseCases
//        viewModel.nextUrlPoiUseCase = poiUseCases
////        viewModel.tripModelUseCase = timelineModeUseCases
//        viewModel.fetchAlternativeUseCase = timelineModeUseCases
//        
//        viewModel.delegate = viewController
//        viewController.delegate = self
//        
//        return viewController
//    }
//    
//    
//    public func addPlaceContainerViewControllerOpenSearchView(_ navigationController: UINavigationController, viewController: UIViewController, selectedType: AddPlaceTypes?) {
//        
//        guard let city = selectedCity else {return}
//        
//        let vc = makePoiSearchViewController(city: city, categoryType: selectedType)
//        navigationController.pushViewController(vc, animated: true)
//    }
//    
//    
//    public func addPlaceOpenPlace(_ viewController: UIViewController, poi: TRPPoi) {
//        let createdPlaceDetail = makePoiDetail(poi: poi, closeParent: viewController)
//        viewController.present(createdPlaceDetail, animated: true, completion: nil)
//    }
//    
//    
//    public func addPlaceTableViewViewControllerOpenPlace(_ viewController: UIViewController, poi: TRPPoi) {
//        let createdPlaceDetail = makePoiDetail(poi: poi, closeParent: viewController)
//        viewController.present(createdPlaceDetail, animated: true, completion: nil)
//    }
//    
//    public func addPlaceSelectCategory(_ navigationController: UINavigationController, viewController: UIViewController, selectedCategories: [TRPPoiCategory]?) {
//        
//        let viewModel = PoiCategoryViewModel(selectedCategories: selectedCategories ?? [])
//        let poiVC = UIStoryboard.makePoiCategoryViewController()
//        poiVC.viewModel = viewModel
//        poiVC.delegate = viewController as? any PoiCategoryVCDelegate
//        viewModel.poiCategoriesUseCase = poiUseCases
//        viewModel.delegate = poiVC
//        viewController.showPageSheet(destination: poiVC)
//        
//    }
//    
//}
//
////MARK: - Search Poi
//extension TRPTimelineModeCoordinator: PoiSearchVCDelegate {
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
//
////MARK: - Must Try
//extension TRPTimelineModeCoordinator: MustTryTableViewViewControllerDelegate {
//    
//    
//    private func makeMustTryTableView(tastes: [TRPTaste]) -> UIViewController {
//        let viewModel = MustTryTableViewViewModel(tastes: tastes)
//        let viewController = UIStoryboard.makeMustTryContainer()// MustTryTableViewViewController(viewModel: viewModel)
//        viewController.viewModel = viewModel
//        viewController.delegate = self
//        return viewController
//    }
//    
//    public func mustTryTableViewVCOpenTasteDetail(_ navigationController: UINavigationController?,
//                                                  viewController: UIViewController,
//                                                  taste: TRPTaste) {
//        let _viewController = makeMustTryDetail(taste: taste)
////        let nav = UINavigationController(rootViewController: _viewController)
////        nav.modalPresentationStyle = .fullScreen
////        nav.navigationBar.prefersLargeTitles = true
////        setNavigationStyleFor(nav)
////        mustTryNavigation = nav
//        viewController.present(_viewController, animated: true, completion: nil)
//    }
//   
//}
//
////MARK: - Must Try
//extension TRPTimelineModeCoordinator: MustTryDetailVCDelegate {
//    
//    
//    private func makeMustTryDetail(taste: TRPTaste) -> UIViewController {
//        
//        let viewModel = MustTryDetailViewModel(taste: taste)
//        
//        let viewController = MustTryDetailViewController(viewModel: viewModel)
//        viewController.delegate = self
//        
//        viewModel.fetchTastePoisUseCase = poiUseCases
////        viewModel.tripModelUseCase = tripModeUseCases
//        
//        viewModel.delegate = viewController
//        
//        let navigation = UINavigationController()
//        navigation.pushViewController(viewController, animated: false)
//        navigation.modalPresentationStyle = .fullScreen
//        return navigation
//    }
//    
//    public func mustTryDetailVCDelegateOpenPlaceDetail(_ viewController: UIViewController, poi: TRPPoi) {
//        let createdPlaceDetail = makePoiDetail(poi: poi, closeParent: viewController)
//        viewController.present(createdPlaceDetail, animated: true, completion: nil)
//    }
//    
//}
//
////MARK: - Favorite
//extension TRPTimelineModeCoordinator: FavoritesVCDelegate {
//    
//    func makeFavoriteViewController() -> UIViewController? {
//        guard let city = selectedCity else {return nil}
//        
//        let viewModel = FavoritesViewModel(cityId: city.id)
//        viewModel.fetchPoiWithIdUseCase = poiUseCases
//        viewModel.observeFavoriteUseCase = favoriteUseCases
//        
//        let viewController = UIStoryboard.makeFavoriteViewController()
//        viewController.viewModel = viewModel
//        
//        viewController.delegate = self
//        viewModel.delegate = viewController
//        
//        
//        return viewController
//    }
//    
//    public func favoriteVCOpenPlaceDetail(viewController: UIViewController, poi: TRPPoi) {
//        let createdPlaceDetail = makePoiDetail(poi: poi, closeParent: viewController)
//        viewController.present(createdPlaceDetail, animated: true, completion: nil)
//    }
//}
//
//
////MARK: - Booking
//extension TRPTimelineModeCoordinator {
//    
//    private func makeBookingViewController() -> UIViewController {
//        let viewModel = BookingListViewModel()
//        viewModel.observerReservationUseCase = reservationUseCases
//        viewModel.deleteReservartionUseCase = reservationUseCases
//        viewModel.updateReservationUseCase = reservationUseCases
//        
//        let viewController = BookingListViewController(viewModel: viewModel)
//        viewModel.delegate = viewController
//        viewModel.start()
//        return viewController
//    }
//    
//}
//
//extension TRPTimelineModeCoordinator: PoiDetailViewControllerDelegate {
//    
//    func poiDetailCloseParentViewController(_ viewController: UIViewController, parentViewController: UIViewController?) {
//        parentViewController?.dismiss(animated: true, completion: nil)
//        if addPlaceNavigation != nil {
//            addPlaceNavigation?.dismiss(animated: true, completion: nil)
//        }
//        if mustTryNavigation != nil {
//            mustTryNavigation?.dismiss(animated: true, completion: nil)
//        }
//    }
//    
//    func poiDetailOpenMakeAReservation(_ viewController: UIViewController, booking: TRPBooking?, poi: TRPPoi) {
//        if let businessId = booking?.products?.first?.id {
//            openYelpCoordinater(businessId: businessId, poi: poi, parentViewController: viewController)
//        }
//    }
//    
//    
//    func poiDetailVCOpenTourDetail(_ navigationController: UINavigationController?,
//                                   viewController: UIViewController,
//                                   bookingProduct: TRPBookingProduct) {
//        
//        guard let tourId = Int(bookingProduct.id) else {return}
//        
//        let navigation = UINavigationController()
//        navigation.modalPresentationStyle = .fullScreen
//        openExperienceCoordinater(nav: navigation, tourId: tourId)
//        viewController.present(navigation, animated: true, completion: nil)
//        setupNavigationBar(navigation.navigationBar)
//    }
//    
//    fileprivate func makePoiDetail(poi: TRPPoi,
//                                   parentStep: TRPTimelineStep? = nil,
//                                   closeParent: UIViewController? = nil) -> UINavigationController {
//        
//        let viewModel = PoiDetailViewModel(place: poi, parentTimelineStep: parentStep)
//        
//        viewModel.addFavoriteUseCase = favoriteUseCases
//        viewModel.deleteFavoriteUseCase = favoriteUseCases
//        viewModel.observeFavoriteUseCase = favoriteUseCases
////        viewModel.addStepUseCase = timelineModeUseCases
//        viewModel.deleteTimelineStepUseCase = timelineModeUseCases
////        viewModel.replaceWithAlternativeUseCase = timelineModeUseCases
//        viewModel.observeReservationUseCase = reservationUseCases
//        viewModel.deleteReservationUseCase = reservationUseCases
////        viewModel.tripModelUseCases = timelineModeUseCases
//        
//        viewModel.addOptInOfferUseCase = offerUseCases
//        viewModel.deleteOptInOfferUseCase = offerUseCases
//        viewModel.observeOptInOfferUseCase = offerUseCases
//        viewModel.fetchOptInOfferUseCase = offerUseCases
//        
//        viewModel.availableTours = toursBetweenTripDate
//        
//        let viewController = UIStoryboard.makePoiDetailViewController()
//        viewController.viewModel = viewModel
////        let viewController = PoiDetailViewController(viewModel: viewModel)
//        viewController.delegate = self
//        viewController.closeParent = closeParent
//        viewModel.delegate = viewController
//        
//        let navigation = UINavigationController()
//        navigation.pushViewController(viewController, animated: false)
//        navigation.modalPresentationStyle = .fullScreen
//        
//        return navigation
//    }
//    
//}
//
////MARK: - LOCAL EXPERIENCE
//extension TRPTimelineModeCoordinator {
//    
//    private func openExperienceCoordinater(nav: UINavigationController, tourId: Int? = nil) {
//        guard let cityName = selectedCity?.name else {return}
//        experiencesCoordinater = TRPExperiencesCoordinater(navigationController: nav, cityName: cityName, tourId: tourId)
////        experiencesCoordinater?.tripModeUseCases = timelineModeUseCases
//        experiencesCoordinater?.reservationUseCases = reservationUseCases
//        experiencesCoordinater?.start()
//    }
//    
//}
//
//
//
////MARK: - YELP COORDINATOR
//extension TRPTimelineModeCoordinator: YelpCoordinaterDelegate {
//    
//    private func openYelpCoordinater(businessId: String, poi: TRPPoi, parentViewController: UIViewController) {
//        
//        let tripHash: String? = timelineModeUseCases.timeline.value?.tripHash ?? nil
//        let totalPeople = timelineModeUseCases.timeline.value?.tripProfile?.getTotalPeopleCount() ?? 1
//        let reservationDay = getReservationDate()
//        let reservationHour = getStepTime(placeId: poi.id)
//        
//        let reservation = Reservation(businessId: businessId, covers: totalPeople, date: reservationDay, time: reservationHour)
//        reservation.firstName = user?.firstName ?? ""
//        reservation.lastName = user?.lastName ?? ""
//        reservation.email = user?.email ?? ""
//        reservation.poiId = poi.id
//        reservation.poiName = poi.name
//        reservation.poiImage = poi.image?.url
//        reservation.tripHash = tripHash
//        
//        let yelpNavigationController = UINavigationController()
//        yelpCoordinater = YelpCoordinater(navigationController: yelpNavigationController, reservation: reservation)
//        yelpCoordinater!.delegate = self
//        yelpCoordinater!.start()
//        parentViewController.present(yelpNavigationController, animated: true, completion: nil)
//    }
//    
//    private func getReservationDate() -> String {
//        if let tripDay = timelineModeUseCases.currentPlan.value?.startDate{
//            return tripDay
//        }
//        return Date().toString(format: "YYYY-MM-dd")
//    }
//    
//    
//    private func getStepTime(placeId: String) -> String {
//        //Todo: Step hour step den alınacak
//        return "16:30"
//    }
//    
//    public func yelpCoordinaterReservationCompleted(_ viewController: UIViewController, reservation: Reservation, business: YelpBusiness?, result: YelpReservation) {
//        viewController.dismiss(animated: true)
//        EvrAlertView.showAlert(contentText: "Reservation successfully created.".toLocalized(), type: .success)
//        var detail: TRPYelpReservationDetail?
//        
//        if let business = business {
//            detail = TRPYelpReservationDetail(businessID: business.id,
//                                              covers: reservation.covers,
//                                              time: reservation.time,
//                                              date: reservation.date,
//                                              uniqueID: reservation.uniqueId,
//                                              phone: reservation.phone,
//                                              holdID: reservation.holdId,
//                                              firstName: reservation.firstName,
//                                              lastName: reservation.lastName,
//                                              email: reservation.email)
//            
//        }
//        
//        let yelp = TRPYelp(confirmURL: result.confirmationUrl,
//                           reservationID: result.reservationId,
//                           restaurantImage: reservation.poiImage,
//                           restaurantName:reservation.poiName,
//                           reservationDetail: detail)
//        
//        reservationUseCases.executeAddReservation(key: "YELP", provider: "YELP", tripHash: reservation.tripHash, poiId: reservation.poiId, values: yelp.getParams()) { result in
//            switch result {
//            case .success(let reservation):
//                print("Reservasyon Sonucu: \(reservation)")
//            case .failure(let error):
//                print("Reservasyon Hatası: \(error.localizedDescription)")
//            }
//        }
//        
//        
//    }
//    
//    
//    
//     func setupNavigationBar(_ navigationBar: UINavigationBar, barTintColor: UIColor = trpTheme.color.extraBG) {
//        navigationBar.barTintColor = barTintColor
//        navigationBar.isTranslucent = false
//        navigationBar.setBackgroundImage(UIImage(), for:.default)
//        navigationBar.shadowImage = UIImage()
//        navigationBar.layoutIfNeeded()
//    }
//}
//
//
////MARK: - OFFERS
//extension TRPTimelineModeCoordinator: MyOffersVCDelegate {
//    
//    
//    func makeMyOffersViewController() -> UIViewController? {
//        let viewModel = MyOffersViewModel()
//        viewModel.fetchOptInOfferUseCase = offerUseCases
//        viewModel.observeOptInOfferUseCase = offerUseCases
//        viewModel.deleteOptInOfferUseCase = offerUseCases
//        
//        let viewController = UIStoryboard.makeMyOffersViewController()
//        viewController.viewModel = viewModel
//        
//        viewController.delegate = self
//        viewModel.delegate = viewController
//        
//        return viewController
//    }
//    
//    public func myOffersVCOpenPlaceDetail(viewController: UIViewController, poi: TRPPoi) {
//        let createdPlaceDetail = makePoiDetail(poi: poi, closeParent: viewController)
//        viewController.present(createdPlaceDetail, animated: true, completion: nil)
//        
//    }
//}
//
//
//
//
