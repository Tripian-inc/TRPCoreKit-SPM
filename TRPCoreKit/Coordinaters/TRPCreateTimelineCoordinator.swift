////
////  TRPCreateTripCoordinater.swift
////  TRPCoreKit
////
////  Created by Evren Yaşar on 6.10.2020.
////  Copyright © 2020 Tripian Inc. All rights reserved.
////
//import Foundation
//import TRPRestKit
//import TRPFoundationKit
//import UIKit
//
//
//protocol TRPCreateTimelineCoordinatorDelegate: TRPBaseCoordinatorProtocol {
//    func trpCreateCoordinatorOpenMyTimeline(hash: String, city: TRPCity)
//    func trpCreateCoordinatorCleanCreateTimeline()
//}
//
//final class TRPCreateTimelineCoordinator: CoordinatorProtocol {
//    var navigationController: UINavigationController?
//    
//    var childCoordinators: [any CoordinatorProtocol] = []
//    
//    public enum ViewState {
//        case selectCity, dateAndPeopleCount, tripQuestions, createOrEditTrip
//    }
//    
//    enum CoordinaterType {
//        case create, edit
//    }
//    
//    private(set) var createTripNavIndex = [TRPBaseUIViewController]()
//    public weak var delegate: TRPCreateTimelineCoordinatorDelegate?
//    private var coordinaterType: CoordinaterType = .create
//    private var userProfileAnswers: [Int] = []
//    private var containerViewModel: CreateTimelineContainerViewModel?
//    
//    private var loadedCity: TRPCity? {
//        didSet {
//            if let city = loadedCity {
//                timelineProfile?.cityId = city.id
//            }
//        }
//    }
//    private var createTimelineContainerNavigation: UINavigationController?
//    
//    private var timelineProfile: TRPTimelineProfile?
//    private var editTimelineProfile: TRPCreateEditTimelineProfile?
//    private var editTimelineSegmentProfile: TRPCreateEditTimelineSegmentProfile?
//    
//    private var oldTimelineProfile: TRPTimelineProfile?
//    
//    // USE CASES
//    public var cityUseCases: FetchCityUseCase?
//    public var questionUseCases: TRPQuestionsUseCases?
//    public var userAnswersUseCases: UserAnswersUseCase?
//    public var updateUserInfo: UpdateUserInfoUseCase?
//    public var fetchUserInfo: FetchUserInfoUseCase?
//    public var fetchUserTripUseCase: FetchUserUpcomingTripUseCase?
//    
//    
//    private(set) lazy var timelineRepository: TRPTimelineRepository = {
//        return TRPTimelineRepository()
//    }()
//    
//    private(set) lazy var timelineModelRepository: TRPTimelineModelRepository = {
//        return TRPTimelineModelRepository()
//    }()
//    
//    private lazy var createTimelineUseCase: TRPCreateTimelineUseCase = {
//        return TRPCreateTimelineUseCase(repository: self.timelineRepository)
//    }()
//    
//    private lazy var editTimelineUseCases: TRPEditTimelineUseCases? = {
//        guard let profile = self.oldTimelineProfile else {return nil}
//        return TRPEditTimelineUseCases(repository: self.timelineRepository)
//    }()
//    
//    private lazy var fetchTimelineAllSegments: TRPTimelineCheckAllPlanUseCases? = {
//        return TRPTimelineCheckAllPlanUseCases(timelineRepository: timelineRepository, timelineModelRepository: timelineModelRepository)
//    }()
//    
//    public init(navigationController: UINavigationController?) {
//        self.navigationController = navigationController
//    }
//    
//    //Create a trip
//    func start() {
//        self.coordinaterType = .create
//        createTimelineProperties(cityId: -1)
//        self.openCreateTimelineContainer()
//    }
//    
//    func start(activityModel: TRPCreateTimelineFromActivityModel) {
//        self.coordinaterType = .create
//        self.openCreateTimelineContainer(with: activityModel)
//    }
//    
//    /// Edit Trip
//    /// - Parameters:
//    ///   - tripHash: Trip hash
//    ///   - tripProfile: Trip profile that contaion information about trip
//    ///   - city: City of Trip
//    func start(tripHash: String,
//               timelineProfile: TRPTimelineProfile,
//               city: TRPCity) {
//        self.coordinaterType = .edit
//        self.createEditTripProperties(cityId: city.id,
//                                      tripHash: tripHash)
//        self.oldTimelineProfile = timelineProfile
//        createTimelineProperties(cityId: -1)
//        self.loadedCity = city
//        self.openCreateTimelineContainer()
//    }
//    
//    func cleanNavigationItems() {
//        createTripNavIndex = []
//    }
//    
//    private func activeProfile() -> TRPTimelineProfile {
//        var profile: TRPTimelineProfile?
//        if let editProfile = editTimelineProfile {
//            profile = editProfile
//        } else if let createTripProfile = timelineProfile {
//            profile = createTripProfile
//        }
//        return profile ?? TRPTimelineProfile(cityId: loadedCity?.id ?? -1)
//    }
//}
//
////MARK: - Prepare Data
//extension TRPCreateTimelineCoordinator {
//    
//    private func setUserInfo() {
//        fetchUserInfo?.executeFetchUserInfo(completion: { [weak self] result in
//            switch result {
//            case .success(let user):
//                if let answers = user.answers {
//                    self?.userProfileAnswers = answers
//                }
//                if user.dateOfBirth == nil {
////                    self?.askUserAge = true
//                }
////                self?.dateOfBirth = user.dateOfBirth
//            case .failure(_): ()
//            }
//        })
//    }
//    
//}
//
////MARK: - Prepare TripProperties
//extension TRPCreateTimelineCoordinator {
//    
//    private func createTimelineProperties(cityId: Int) {
//        timelineProfile = TRPTimelineProfile(cityId: cityId)
//        timelineProfile?.userAnswerIds = userProfileAnswers
//    }
//    
//    private func createEditTripProperties(cityId: Int, tripHash hash: String) {
//        editTimelineProfile = TRPCreateEditTimelineProfile(cityId: cityId, tripHash: hash)
//        editTimelineProfile?.userAnswerIds = userProfileAnswers
//    }
//    
//}
//
////MARK: - CREATE TIMELINE CONTAINER
//extension TRPCreateTimelineCoordinator: CreateTimelineContainerViewModelCoordinatorDelegate {
//    func trpCreateCoordinatorCreateSegment(index: Int) {
//        timelineProfile = containerViewModel?.timelineProfile
//        let vc = makeSegmentInformation(segmentIndex: index)
//        vc.viewModel?.containerDelegate = containerViewModel
//        containerViewModel?.addViewControllerInPagination(vc)
//    }
//    
//    
//    fileprivate func openCreateTimelineContainer(with activityModel: TRPCreateTimelineFromActivityModel? = nil) {
//        let viewController = getTimelineContainer(with: activityModel)
//        
//        
//        let navigation = UINavigationController(rootViewController: viewController)
//        navigation.modalPresentationStyle = .fullScreen
//        createTimelineContainerNavigation = navigation
//        navigationController?.present(navigation, animated: true, completion: nil)
//    }
//    
//    private func getTimelineContainer(with activityModel: TRPCreateTimelineFromActivityModel? = nil) -> CreateTimelineContainerVC {
//        let viewController = UIStoryboard.makeCreateTimelineContainerViewController() as CreateTimelineContainerVC
//        
//        let viewModel = CreateTimelineContainerViewModel()
//        viewModel.delegate = viewController
//        viewModel.isEditing = coordinaterType == .edit
//        viewModel.coordinatorDelegate = self
//        viewModel.timelineProfile = timelineProfile
//        viewModel.editTimelineProfile = editTimelineProfile
//        viewModel.observeTimelineAllPlan = fetchTimelineAllSegments
//        viewModel.fetchTimelineAllPlan = fetchTimelineAllSegments
//        viewModel.createTimelineUseCase = createTimelineUseCase
//        viewModel.activityModel = activityModel
//        viewController.viewModel = viewModel
//        
//        let globalInformation = makeGlobalInformation()
//        globalInformation.viewModel?.containerDelegate = viewModel
//        viewModel.addViewControllerInPagination(globalInformation)
//        containerViewModel = viewModel
//        
//        return viewController
//    }
//    
//    func trpCreateCoordinatorOpenMyTimeline(hash: String, city: TRPCity) {
//        createTimelineContainerNavigation?.removeFromParent()
//        delegate?.trpCreateCoordinatorOpenMyTimeline(hash: hash, city: city)
//    }
//}
//
////MARK: Global Settings
//extension TRPCreateTimelineCoordinator: CreateTimelineGlobalSettingsVCDelegate {
//        
//    private func makeGlobalInformation() -> CreateTimelineGlobalSettingsVC {
//        
//        let viewModel = CreateTimelineGlobalSettingsViewModel(timelineProfile: activeProfile(),
//                                                              oldTimelineProfile: oldTimelineProfile,
//                                                              loadedCity: loadedCity)
//        
//        let vc = UIStoryboard.makeCreateTimelineGlobalSettingsVC()
//        vc.viewModel = viewModel
//        viewModel.delegate = vc
//        viewModel.containerDelegate = containerViewModel
//        viewModel.fetchProfileQuestionsUseCase = questionUseCases
//        vc.delegate = self
//        return vc
//    }
//    
//    func globalSettingsSelectDateRange(_ viewController: UIViewController, with preselected: (Date, Date)?) {
//        delegate?.showDateRangeSelection(preselected: preselected, maxDays: 30, viewController: viewController)
//    }
//    
//    func globalSettingsSelectTravelers(_ viewController: UIViewController, with preselected: (adults: Int, children: Int, pets: Int)) {
//        self.showSelectTravelerVC(viewController, preselected: preselected)
//    }
//    
//    
//    func globalSettingsSelectCity(_ viewController: UIViewController) {
//        delegate?.showCityDestinationSelection(viewController: viewController)
//    }
//    
//    func globalSettingsCitySelected(_ city: TRPCity) {
//        self.loadedCity = city
//    }
//
//}
//
////MARK: Segment Settings
//extension TRPCreateTimelineCoordinator: CreateTimelineSegmentSettingsVCDelegate {
//    func makeSegmentSettingsForAdd(_ viewController: UIViewController, segmentIndex: Int, city: TRPCity) -> CreateTimelineSegmentSettingsVC {
//        loadedCity = city
//        let vc = makeSegmentInformation(segmentIndex: segmentIndex, forAddUpdate: true)
//        vc.addUpdateDelegate = viewController as? CreateTimelineSegmentSettingsAddUpdateDelegate
//        return vc
//    }
//    
//    func makeSegmentSettingsForUpdate(_ viewController: UIViewController, segmentProfile: TRPCreateEditTimelineSegmentProfile, city: TRPCity) -> CreateTimelineSegmentSettingsVC {
//        loadedCity = city
//        let vc = makeSegmentInformationForUpdate(segmentProfile: segmentProfile)
//        vc.addUpdateDelegate = viewController as? CreateTimelineSegmentSettingsAddUpdateDelegate
//        return vc
//    }
//    
//    private func makeSegmentInformation(segmentIndex: Int, forAddUpdate: Bool = false) -> CreateTimelineSegmentSettingsVC {
//        
//        guard let loadedCity else {return CreateTimelineSegmentSettingsVC()}
//        
//        let viewModel = CreateTimelineSegmentSettingsViewModel(timelineProfile: activeProfile(),
//                                                               oldTimelineProfile: oldTimelineProfile,
//                                                               segmentIndex: segmentIndex,
//                                                               loadedCity: loadedCity,
//                                                               forAddUpdate: forAddUpdate)
//        
//        let vc = UIStoryboard.makeCreateTimelineSegmentSettingsVC()
//        vc.viewModel = viewModel
//        viewModel.delegate = vc
//        viewModel.containerDelegate = containerViewModel
//        viewModel.fetchProfileQuestionsUseCase = questionUseCases
//        vc.delegate = self
//        vc.coordinatorDelegate = delegate
//        return vc
//    }
//    
//    private func makeSegmentInformationForUpdate(segmentProfile: TRPCreateEditTimelineSegmentProfile) -> CreateTimelineSegmentSettingsVC {
//        
//        guard let loadedCity else {return CreateTimelineSegmentSettingsVC()}
//        
//        let viewModel = CreateTimelineSegmentSettingsViewModel(timelineProfile: activeProfile(), oldTimelineSegmentProfile: segmentProfile, loadedCity: loadedCity)
//        
//        let vc = UIStoryboard.makeCreateTimelineSegmentSettingsVC()
//        vc.viewModel = viewModel
//        viewModel.delegate = vc
//        viewModel.containerDelegate = containerViewModel
//        viewModel.fetchProfileQuestionsUseCase = questionUseCases
//        vc.delegate = self
//        vc.coordinatorDelegate = delegate
//        return vc
//    }
//    
//    func segmentSettingsSelectCity(_ viewController: UIViewController) {
//        delegate?.showCityDestinationSelection(viewController: viewController)
//    }
//    
//    func segmentSettingsSelectLocation(_ viewController: UIViewController, city: TRPCity) {
//        delegate?.showSelectAddressVC(viewController, city: city)
//    }
//    
//    func segmentSettingsSelectTravelers(_ viewController: UIViewController, with preselected: (adults: Int, children: Int, pets: Int)) {
//        showSelectTravelerVC(viewController, preselected: preselected)
//    }
//    
//    func segmentSettingsSelectTime(_ viewController: UIViewController, isArrival: Bool, selectedHour: String?, minimumHour: String?) {
//        openSelectTimeVC(_viewController: viewController, isArrival: isArrival, selectedHour: selectedHour, minimumHour: minimumHour)
//    }
//    
//}
//
////MARK: - Travelers Count
//extension TRPCreateTimelineCoordinator {
//    
//    private func showSelectTravelerVC(_ viewController: UIViewController, preselected: (adults: Int, children: Int, pets: Int)) {
//        let vc = UIStoryboard.makeCreateTimelineSelectTravelerVC()
//        let vm = CreateTimelineSelectTravelerViewModel(adultsCountValue: preselected.adults,
//                                                       childrenCountValue: preselected.children,
//                                                       petsCountValue: preselected.pets,
//                                                       delegate: vc)
//        vc.delegate = viewController as? CreateTimelineSelectTravelerVCDelegate
//        vc.viewModel = vm
//        viewController.showPageSheet(destination: vc)
//    }
//}
//
////MARK: - SelectTime
//extension TRPCreateTimelineCoordinator {
//    
//    private func openSelectTimeVC(_viewController: UIViewController, isArrival: Bool, selectedHour: String?, minimumHour: String?) {
//        let selectHourVC = UIStoryboard.makeSelectTimeViewController() as SelectTimeVC
//        let viewModel = SelectTimeViewModel()
//        viewModel.isArrival = isArrival
//        viewModel.selectedHour = selectedHour
//        viewModel.minimumHour = minimumHour
//        viewModel.start()
//        selectHourVC.viewModel = viewModel
//        selectHourVC.delegate = _viewController as? SelectTimeVCDelegate
//        _viewController.showPageSheet(destination: selectHourVC)
//    }
//}
//
//
////MARK: - Create Trip
//extension TRPCreateTimelineCoordinator {
//    
//    private func fetchUpcomingTrip() {
//        fetchUserTripUseCase?.executeUpcomingTrip(completion: nil)
//    }
//}
