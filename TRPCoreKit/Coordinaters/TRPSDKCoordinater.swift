//
//  TRPCoordinater.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 6.11.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
import TRPFoundationKit
import TRPRestKit

public protocol TRPSDKCoordinaterDelegate: AnyObject {
    func trpSdkCoordinaterMyTripsButtonPressed(_ coordinate: TRPSDKCoordinater, item: TRPBarButtonItem, navigationController: UINavigationController, vc: UIViewController)
    func trpSdkCoordinaterUserSignOut(_ coordinater: TRPSDKCoordinater)
    func trpSdkCoordinaterUserDelete(_ coordinater: TRPSDKCoordinater)
}
let Log = TRPLogger(prefixText: "Tripian/TRPCoreKit")
public class TRPSDKCoordinater {
    
    public weak var delegate: TRPSDKCoordinaterDelegate?
    private var navigationController: UINavigationController
    private var tripCreateCoordinater: TRPCreateTripCoordinater?
    private var userProfileCoordinater: TRPUserProfileCoordinater?
    private var tripModeCoordinater: TRPTripModeCoordinater?
    private var userProfileAnswers = [Int]()
    
    private var canBackFromMyTrip = true

    // Timeline-related properties
    private var timelineFromItineraryViewModel: TRPTimelineFromItineraryViewModel?
    private var timelineModelRepository: TRPTimelineModelRepository?
    private var timelineRepository: TRPTimelineRepository?

    // Store itinerary data for opening after splash completes
    private var pendingItineraryModel: TRPItineraryWithActivities?
    private var pendingTripHash: String?
    
    private var alertMessage: (title: String?, message: String)? {
        didSet {
            guard let message = alertMessage else {return}
            myTrip.alertMessage = message
        }
    }
    
    
    //--------- USE CASES
    lazy var userTripUseCases: TRPUserTripUseCases = {
        return TRPUserTripUseCases()
    }()
    
    lazy var cityUseCases: TRPCityUseCases = {
        return TRPCityUseCases()
    }()
    
    lazy var languagesUseCases: TRPLanguagesUseCases = {
        return TRPLanguagesUseCases()
    }()
    
    private lazy var questionUseCases: TRPQuestionsUseCases = {
       return TRPQuestionsUseCases()
    }()
    
    private lazy var userInfoUseCases: TRPUserInfoUseCases = {
        return TRPUserInfoUseCases()
    }()
    
    private lazy var companionUseCases: TRPCompanionUseCases = {
        return TRPCompanionUseCases()
    }()
    
    // Timeline use cases
    private lazy var createTimelineUseCase: TRPCreateTimelineUseCase = {
        let repo = timelineRepository ?? TRPTimelineRepository()
        timelineRepository = repo
        return TRPCreateTimelineUseCase(repository: repo)
    }()
    
    private lazy var fetchTimelineCheckAllPlanUseCase: TRPTimelineCheckAllPlanUseCases = {
        let timelineRepo = timelineRepository ?? TRPTimelineRepository()
        let timelineModelRepo = timelineModelRepository ?? TRPTimelineModelRepository()
        timelineRepository = timelineRepo
        timelineModelRepository = timelineModelRepo
        return TRPTimelineCheckAllPlanUseCases(timelineRepository: timelineRepo, timelineModelRepository: timelineModelRepo)
    }()
    
    private lazy var myTrip: MyTripVC = {
        return makeMyTrip()
    }()
    
    public init(navigationController: UINavigationController, canBack: Bool = true) {
        self.navigationController = navigationController
        self.canBackFromMyTrip = canBack
        TRPFonts.registerAll()
    }
    
     private func setupSomeGeneralAppearances() {
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = TRPColor.darkGrey
        navigationController.navigationBar.setNexusBar()
    }
    
    private func startWithSplashVC(uniqueId: String? = nil, email: String? = nil, password: String? = nil) {
        // Fetch cities for coordinate-based city lookup (async, no auth required)
        TRPCityCache.shared.fetchCitiesIfNeeded()

        // Prefetch POI categories for filtering (async, no auth required)
        TRPPoiUseCases.prefetchCategories()

        let vc = SplashViewController()
        vc.delegate = self
        vc.uniqueId = uniqueId
        vc.email = email
        vc.password = password
        vc.start()
        DispatchQueue.main.async {
            self.navigationController.pushViewController(vc, animated: true)
            self.setupSomeGeneralAppearances()
        }
    }
    
    public func startForGuest(uniqueId: String? = nil) {
        startWithSplashVC(uniqueId: uniqueId)
    }
    
    public func startWithEmail(_ email: String) {
        startWithSplashVC(email: email)
    }
    
    public func startWithEmailAndPassword(_ email: String, _ password: String) {
        startWithSplashVC(email: email, password: password)
    }
    
    /// Start with TRPItineraryWithActivities model to create a timeline
    /// Opens splash screen first to handle translations and login, then opens timeline itinerary screen
    /// - Parameters:
    ///   - itineraryModel: TRPItineraryWithActivities model containing timeline data
    ///   - tripHash: Optional trip hash. If provided, fetches existing timeline instead of creating new one
    ///   - uniqueId: Optional unique identifier. If not provided, uses device's identifierForVendor
    public func startWithItinerary(_ itineraryModel: TRPItineraryWithActivities, tripHash: String? = nil, uniqueId: String? = nil) {
        checkAllApiKey()
        userProfile()
        // Fetch cities for coordinate-based city lookup (async, no auth required)
        TRPCityCache.shared.fetchCitiesIfNeeded()

        // Store itinerary data to be used after splash completes
        pendingItineraryModel = itineraryModel
        pendingTripHash = tripHash

        // Determine uniqueId: use provided value, fall back to itinerary's uniqueId, then device ID
        let effectiveUniqueId: String
        if let providedId = uniqueId, !providedId.isEmpty {
            effectiveUniqueId = providedId
        } else if !itineraryModel.uniqueId.isEmpty {
            effectiveUniqueId = itineraryModel.uniqueId
        } else {
            effectiveUniqueId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        }

        // Start with splash screen to handle translations and login
        startWithSplashVC(uniqueId: effectiveUniqueId)
    }

    /// Opens timeline with existing trip hash (fetch existing timeline)
    /// - Parameters:
    ///   - tripHash: The trip hash for the existing timeline
    ///   - itineraryModel: The itinerary model containing additional data like favouriteItems
    private func openTimelineWithTripHash(_ tripHash: String, itineraryModel: TRPItineraryWithActivities) {
        // Show loading
        showTripianLoader(true)

        // Fetch timeline using repository
        let repo = timelineRepository ?? TRPTimelineRepository()
        repo.fetchTimeline(tripHash: tripHash) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                // Hide loading
                self.showTripianLoader(false)

                switch result {
                case .success(let timeline):
                    // Merge itinerary model data with fetched timeline
                    self.openTimelineItineraryViewControllerWithItineraryData(timeline: timeline, itineraryModel: itineraryModel)

                case .failure(let error):
                    // Show error alert
                    let alert = UIAlertController(
                        title: "Error",
                        message: "Failed to load timeline. Please try again.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.navigationController.present(alert, animated: true)
                }
            }
        }
    }

    /// Sets up the timeline creation view model and starts the creation process
    private func setupTimelineCreationViewModel(_ itineraryModel: TRPItineraryWithActivities) {
        // Create view model
        let viewModel = TRPTimelineFromItineraryViewModel(itineraryModel: itineraryModel)
        viewModel.delegate = self

        // Set up use cases
        viewModel.createTimelineUseCase = createTimelineUseCase
        viewModel.observeTimelineAllPlan = fetchTimelineCheckAllPlanUseCase
        viewModel.fetchTimelineAllPlan = fetchTimelineCheckAllPlanUseCase

        // Store reference
        timelineFromItineraryViewModel = viewModel

        // Start timeline creation
        viewModel.createTimeline()
    }
    
    public func start() {
        checkAllApiKey()
        userProfile()
//        getLanguages()
        // Fetch cities for coordinate-based city lookup (async, no auth required)
        TRPCityCache.shared.fetchCitiesIfNeeded()
        // Prefetch POI categories for filtering (async, no auth required)
        TRPPoiUseCases.prefetchCategories()
        startFirstVC()
    }
    
    private func startFirstVC() {
        
        let vc = myTrip
//        myTrip.isNexus = isAppForNexus
        //navigationController.pushViewController(vc, animated: true)
        DispatchQueue.main.async {
            self.navigationController.pushViewController(vc, animated: true)
            self.setupSomeGeneralAppearances()
        }
    }
    
    public func startForNexus(bookingDetailUrl: String, startDate: String?, endDate: String?, meetingPoint: String?, numberOfAdults: Int?, numberOfChildren: Int?) {
        checkAllApiKey()
        userProfile()
        // Fetch cities for coordinate-based city lookup (async, no auth required)
        TRPCityCache.shared.fetchCitiesIfNeeded()
        let vc = myTrip
        vc.bookingDetailUrl = bookingDetailUrl
        //navigationController.pushViewController(vc, animated: true)
        DispatchQueue.main.async {
            self.navigationController.pushViewController(vc, animated: true)
            self.setupSomeGeneralAppearances()
        }
        //navigationController.pushViewController(makePaymetnViewController(), animated: true)
        //navigationController.pushViewController(makeBilling(), animated: true)
    }
    
//     func makeBilling() -> UIViewController {
//        let viewModel = ExperienceBillingViewModel()
//        viewModel.billingUseCases = bookingUseCases
//        viewModel.paymentUseCases = bookingUseCases
//        
//        let viewController = ExperienceBillingViewController(viewModel: viewModel)
//        viewModel.delegate = viewController
//        
//        viewModel.start()
//        return viewController
//    }
    
    public func addAlertMessage(title: String?, message: String) {
        alertMessage = (title: title, message: message)
    }
    
    private func userProfile() {
        userInfoUseCases.executeFetchUserInfo { [weak self] result in
            switch result {
            case .success(let userInfo):
                self?.userProfileAnswers = userInfo.answers ?? []
            case .failure(_): ()
            }
        }
    }
    
    internal var isLoaderOnView = false
    
    
    private var laoderVC: TRPLoaderVC = TRPLoaderVC()
    
     public func showTripianLoader(_ show: Bool) {
        if show {
            if !self.isLoaderOnView {
                self.laoderVC.modalPresentationStyle = .overCurrentContext
                self.navigationController.present(self.laoderVC, animated: false, completion: nil)
                self.laoderVC.show()
            }
        } else {
            self.laoderVC.dismiss(animated: false, completion: nil)
        }
        self.isLoaderOnView.toggle()
    }
    
//    public func getLanguages() {
//        showTripianLoader(true)
//        TRPLanguagesController.shared.getLanguages() { result in
//            self.showTripianLoader(false)
//        }
//    }
    
//     private func makePaymentViewController() -> UIViewController {
//        let viewModel = PaymentViewModel()
//        viewModel.paymentUseCases = bookingUseCases
//        let viewController = PaymentViewController(viewModel: viewModel)
//        viewModel.delegate = viewController
//        return viewController
//    }
    
     public func remove() {
        self.navigationController.dismiss(animated: true)
    }
    
}

extension TRPSDKCoordinater: SplashViewControllerDelegate {
    func datasFetchCompleted() {
        // Check if we have pending itinerary model to open
        if let itineraryModel = pendingItineraryModel {
            // Remove splash from navigation stack (it's the current top VC)
            // Use setViewControllers to replace splash with timeline in one operation
            let viewModel = TRPTimelineItineraryViewModel(itineraryModel: itineraryModel, tripHash: pendingTripHash)
            let viewController = TRPTimelineItineraryVC(viewModel: viewModel)

            // Replace splash with timeline
            navigationController.setViewControllers([viewController], animated: true)

            // Clear pending data
            pendingItineraryModel = nil
            pendingTripHash = nil
        } else {
            // Normal flow: open MyTrips screen
            start()
        }
    }

    func datasFetchFailed() {
        navigationController.dismiss(animated: true)

        // Clear pending data on failure
        pendingItineraryModel = nil
        pendingTripHash = nil
    }

}

//extension TRPSDKCoordinater: ExperienceDetailViewControllerDelegate, ExperienceAvailabilityViewControllerDelegate {
//    
//    func experienceAvailabilityOpenBilling(_ navigationController: UINavigationController?,
//                                           viewController: UIViewController) {
//        
//    }
//    
//    func experienceAvailabilityOpenBooking(_ navigationController: UINavigationController?,
//                                           viewController: UIViewController,
//                                           bookingParameters: [GYGBookingParameter],
//                                           language: GYGCondLanguage?,
//                                           pickUp: String?) {
//        let viewModel = ExperienceRequirementFieldViewModel(bookingParameters: bookingParameters, language: language,pickUp: pickUp)
//        viewModel.postBookingUseCase = bookingUseCases
//        viewModel.bookingParametersUseCase = bookingUseCases
//        let viewController = ExperienceRequirementFieldViewController(viewModel: viewModel)
//        viewModel.delegate = viewController
//        viewController.delegate = self
//        viewModel.start()
//        navigationController?.pushViewController(viewController, animated: true)
//    }
//    
//    public func experienceDetailVCOpenReviews(_ navigationController: UINavigationController?, viewController: UIViewController, tourId: Int) {
//        
//    }
//    
//    public func experienceDetailVCOpenAvailability(_ navigationController: UINavigationController?, viewController: UIViewController, tourId: Int) {
//        let viewModel = ExperienceAvailabilityViewModel(tourId: tourId)
//        viewModel.bookingOptionUseCase = bookingUseCases
//        let viewController = ExperienceAvailabilityViewController(viewModel: viewModel)
//        viewModel.delegate = viewController
//        viewController.delegate = self
//        navigationController?.pushViewController(viewController, animated: true)
//    }
//    
//    public func experienceDetailVCOpenMoreInfo(_ navigationController: UINavigationController?, viewController: UIViewController, tour: GYGTour) {
//        let viewModel = ExperienceMoreInfoViewModel(tour: tour)
//        let viewController = ExperienceMoreInfoViewController(viewModel: viewModel)
//        viewModel.delegate = viewController
//        viewModel.start()
//        navigationController?.pushViewController(viewController, animated: true)
//    }
//    
//    
//    private func testViewController() -> UIViewController{
//        // 61038 Tek istanbul turu
//        // 49897 Birden fazla opsiyonlu tur
//        // 203728 Dil ve gerekli bilgi isteği ----
//        // 18863 group tur lu
//        // 55777
//        // çok saatli 192699
//        let viewModel = ExperienceDetailViewModel(tourId: 192699, isFromTripDetail: true)
//        let viewController = ExperienceDetailViewController(viewModel: viewModel)
//        viewModel.delegate = viewController
//        viewController.delegate = self
//        return viewController
//    }
//}

//extension TRPSDKCoordinater: ExperienceRequirementFieldVCDelegate {
//    func experienceBookingMade(_ booking: GYGBookings?) {
//        
//    }
//    
//    func experienceRequirementFieldOpenBillingVC(_ navigationController: UINavigationController?, viewController: UIViewController) {
//        let vc = makeBilling()
//        navigationController?.pushViewController(vc, animated: true)
//    }
//    
//}



//MARK: - MYTRIP
extension TRPSDKCoordinater {
    
    private func makeMyTrip() -> MyTripVC {
        let viewModel = MyTripViewModel()
        viewModel.fetchCityUseCase = cityUseCases
        let viewController = MyTripVC(viewModel: viewModel)
        viewController.delegate = self
        viewController.canBack = canBackFromMyTrip
        let upcomingTrip = makeUpcomingTrip()
        let pastTrip = makePastTrip()
        viewController.addViewControllerInPagination(upcomingTrip)
        viewController.addViewControllerInPagination(pastTrip)
        viewModel.delegate = viewController
        upcomingTrip.delegate = viewController
        pastTrip.delegate = viewController
        return viewController
    }
    
     private func makeUpcomingTrip() -> MyTripTableViewVC {
        let viewModel = MyTripTableViewViewModel(timeType: .upcomingTrip)
        let viewController = UIStoryboard.makeMyTripTableView()
        viewController.viewModel = viewModel
        viewModel.delegate = viewController
        viewModel.fetchUpcomingTripUseCase = userTripUseCases
        viewModel.deleteTripUseCase = userTripUseCases
        viewModel.observeUpcomingTripUseCase = userTripUseCases
        viewModel.start()
        return viewController
    }
    
     private func makePastTrip() -> MyTripTableViewVC {
        let viewModel = MyTripTableViewViewModel(timeType: .pastTrip)
        let viewController = UIStoryboard.makeMyTripTableView()
        viewController.viewModel = viewModel
        viewModel.delegate = viewController
        viewModel.fetchPastTripUseCase = userTripUseCases
        viewModel.deleteTripUseCase = userTripUseCases
        viewModel.observePastTripUseCase = userTripUseCases
        viewModel.start()
        return viewController
    }
    
}

// MARK: - Create Trip Coordinater
extension TRPSDKCoordinater:  TRPCreateTripCoordinaterDelegate {
    
    private func setupCreteTripCoordinater() {
        tripCreateCoordinater = TRPCreateTripCoordinater(navigationController: navigationController)
        tripCreateCoordinater?.cityUseCases = cityUseCases
        tripCreateCoordinater?.questionUseCases = questionUseCases
        tripCreateCoordinater?.companionUseCases = companionUseCases
        tripCreateCoordinater?.fetchUserTripUseCase = userTripUseCases
        tripCreateCoordinater?.delegate = self
        
    }
    
     public func trpTripCreateCoordinaterOpenMyTrip(hash: String, city: TRPCity) {
        navigationController.dismiss(animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.openTripModeViewController(hash: hash, 
                                            city: city,
                                            tripRepository: self.tripCreateCoordinater?.tripRepository,
                                            tripModelRepository: self.tripCreateCoordinater?.tripModelRepository)
        })
    }
    
     public func trpTripCreateCoordinaterCleanCreateTrip() {
        if tripCreateCoordinater != nil{
            navigationController.viewControllers.removeAll(where: { (vc) -> Bool in
                if vc.isKind(of: MyTripVC.self) || vc.isKind(of: TRPTripModeVC.self) {
                    return false
                }
                else {
                    return true
                }
            })
            tripCreateCoordinater!.cleanNavigationItems()
        }
    }
    
}

// MARK: - MyTripVc Delegate
extension TRPSDKCoordinater:  MyTripVCDelegate {    
    
    public func myTripEditTrip(tripHash: String, profile: TRPTripProfile, city: TRPCity) {
        setupCreteTripCoordinater()
        tripCreateCoordinater?.start(tripHash: tripHash,
                                     tripProfile: profile,
                                     city: city)
    }
    
    
    public func myTripVCOpenUserProfile(nav: UINavigationController?, vc: UIViewController) {
        openUserProfile()
    }
    
    public func myTripOpenTrip(hash: String, city: TRPCity, arrival: String, departure: String) {
        
        let startDay = startTripWithCurentDay(arrival: arrival, departure: departure)
        openTripModeViewController(hash: hash, city: city, startDay: startDay)
    }
    
    public func myTripVCDidAppear() {
        //Memory leak engellenemek için array i boşaltıyorum.
        guard let creater = tripCreateCoordinater else { return }
        creater.cleanNavigationItems()
        tripCreateCoordinater = nil
    }
    
    public func myTripEditTrip(profile: TRPTripProfile) {
        setupCreteTripCoordinater()
    }
    
    public func createNewTripPressed(_ myTrip: MyTripVC, city: TRPCity?, destinationId: Int?) {
        setupCreteTripCoordinater()
        guard let tripCreateCoordinater = tripCreateCoordinater else {
            return
        }
//        tripCreateCoordinater.nexusTripStartDate = self.nexusStartDate
//        tripCreateCoordinater.nexusTripEndDate = self.nexusEndDate
//        tripCreateCoordinater.nexusTripMeetingPoint = self.nexusMeetingPoint
//        tripCreateCoordinater.nexusNumberOfAdults = self.nexusNumberOfAdults
//        tripCreateCoordinater.nexusNumberOfChildren = self.nexusNumberOfChildren
        tripCreateCoordinater.nexusDestinationId = destinationId
        //TRPTimelineMockCoordinator.quickTest(from: navigationController)
        tripCreateCoordinater.start(city: city)
    }
    
    
     public func myTripVCDismissButtonPressed() {
        navigationController.dismiss(animated: true, completion: nil)
    }
    
    public func myTripVCCustomNavigationButtonPressed(_ item: TRPBarButtonItem, vc: UIViewController) {
        delegate?.trpSdkCoordinaterMyTripsButtonPressed(self, item: item, navigationController: navigationController, vc: vc)
    }
    
}

// MARK: - TRPTripMode
extension TRPSDKCoordinater {
    
    private func openTripModeViewController(hash:String,
                                            city: TRPCity,
                                            startDay: Int = 0,
                                            tripRepository: TRPTripRepository? = nil,
                                            tripModelRepository: TripModelRepository? = nil) {
        
        let tripCoordinater = TRPTripModeCoordinater(navigationController: navigationController,
                                                     tripRepository: tripRepository,
                                                     tripModelRepository: tripModelRepository)
        tripCoordinater.fetchUserInfoUseCase = userInfoUseCases
    
        tripCoordinater.openTripModeVC(hash: hash, city: city, startDay: startDay)
        tripModeCoordinater = tripCoordinater
    }
    
    private func startTripWithCurentDay(arrival: String? = nil, departure: String? = nil) -> Int {
        var startDayOrder = 0
        if let ar = arrival,
            let dep = departure,
            let arrivalDate = ar.toDateWithoutUTC(format: "yyyy-MM-dd"),
            let departureDate = dep.toDateWithoutUTC(format: "yyyy-MM-dd") {
            let inDay = tripInDay(current: Date().localDate(), arrival: arrivalDate, departure: departureDate)
            if inDay.inTime && inDay.order != nil{
                startDayOrder = inDay.order ?? 0
            }
        }
        return startDayOrder
    }
    
    private func tripInDay(current: Date, arrival: Date, departure: Date) ->(inTime:Bool, order:Int?) {
        guard let difArrival = Calendar.current.dateComponents([.day], from: arrival, to: current).day,
            let difDeparture = Calendar.current.dateComponents([.day], from: current, to: departure).day else {return (false,nil)}
        if difArrival > -1 && difDeparture > -1 {
            return (true,difArrival)
        }
        return (false,nil)
    }
    
    
}

//MARK: - User Profile
extension TRPSDKCoordinater: TRPUserProfileCoordinaterDelegate {
    
    public func openUserProfile() {
        userProfileCoordinater = TRPUserProfileCoordinater(navigationController)
        userProfileCoordinater!.appInfo = getAppInfo()
        userProfileCoordinater!.questionUseCases = questionUseCases
        userProfileCoordinater!.userInfoUseCases = userInfoUseCases
        userProfileCoordinater!.companionUseCases = companionUseCases
        userProfileCoordinater!.delegate = self
        userProfileCoordinater!.start()
    }
    
    public func trpUserProfileCoordinater(userProfileData: [Int]) {}
    
    public func trpUserProfileSignOut() {
//        navigationController.dismiss(animated: true, completion: nil)
        delegate?.trpSdkCoordinaterUserSignOut(self)
    }
    
    public func trpUserDelete() {
        delegate?.trpSdkCoordinaterUserDelete(self)
    }
    
    public func getAppInfo() -> [String: String]{
        var infos = [String:String]()
        if let info = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            infos["App"] = info
        }
        if let core = CoreKitInfo().version() {
            infos["Core Kit"] = core
        }
        if let restKit = RestKitInfo().version() {
            infos["Rest Kit"] = restKit
        }
        if let core = UIKitInfo().version() {
            infos["UI Kit"] = core
        }
        return infos
    }
}

//MARK: - HELPER
extension TRPSDKCoordinater {
    private func checkAllApiKey() {
        let keys: [TRPApiKeys] = [.trpGooglePlace,.mglMapboxAccessToken]
        let missingApiKey = TRPApiKeyController.checkMissingApiKeys(keys)
        if missingApiKey.count > 0 {
            let missingValus = missingApiKey.toString(", ")
            Log.e("Could not find '\(missingValus)' key in Info.plist")
        }
    }
    
}

// MARK: - Timeline Creation Delegate
extension TRPSDKCoordinater: TRPTimelineFromItineraryViewModelDelegate {

    public func timelineGenerated(timeline: TRPTimeline) {
        DispatchQueue.main.async {
            // Hide loading
            self.showTripianLoader(false)

            // Open timeline itinerary view with generated timeline
            self.openTimelineItineraryViewController(timeline: timeline)
        }
    }

    /// Opens Timeline Itinerary View Controller with the generated timeline (without itinerary data merge)
    private func openTimelineItineraryViewController(timeline: TRPTimeline) {
        // Create view model with timeline
        let viewModel = TRPTimelineItineraryViewModel(timeline: timeline)

        // Create view controller
        let viewController = TRPTimelineItineraryVC(viewModel: viewModel)

        // Push onto navigation stack
        DispatchQueue.main.async {
            self.navigationController.pushViewController(viewController, animated: true)
        }
    }

    /// Opens Timeline Itinerary View Controller with fetched timeline and itinerary model data
    /// - Parameters:
    ///   - timeline: Fetched timeline from server
    ///   - itineraryModel: Itinerary model containing additional data (favouriteItems, tripItems, etc.)
    private func openTimelineItineraryViewControllerWithItineraryData(timeline: TRPTimeline, itineraryModel: TRPItineraryWithActivities) {

        // Add favouriteItems to timeline
        var updatedTimeline = timeline
        updatedTimeline.favouriteItems = itineraryModel.favouriteItems

        // Also add favouriteItems to tripProfile if it exists
        if var tripProfile = updatedTimeline.tripProfile {
            tripProfile.favouriteItems = itineraryModel.favouriteItems
            updatedTimeline.tripProfile = tripProfile
        }

        // Create view model with timeline
        // ViewModel will handle adding missing booked activities via API
        let viewModel = TRPTimelineItineraryViewModel(timeline: updatedTimeline, itineraryModel: itineraryModel)

        // Create view controller
        let viewController = TRPTimelineItineraryVC(viewModel: viewModel)

        // Push onto navigation stack
        DispatchQueue.main.async {
            self.navigationController.pushViewController(viewController, animated: true)
        }
    }
}
