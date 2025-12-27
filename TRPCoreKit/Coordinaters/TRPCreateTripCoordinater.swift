//
//  TRPCreateTripCoordinater.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 6.10.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//
import Foundation
import UIKit
import TRPFoundationKit

public protocol TRPCreateTripCoordinaterDelegate: AnyObject {
    func trpTripCreateCoordinaterOpenMyTrip(hash: String, city: TRPCity)
    func trpTripCreateCoordinaterCleanCreateTrip()
}

final public class TRPCreateTripCoordinater {
    
    public enum ViewState {
        case selectCity, dateAndPeopleCount, tripQuestions, createOrEditTrip
    }
    
    enum CoordinaterType {
        case create, edit
    }
    
    private let navigationController: UINavigationController
    private(set) var createTripNavIndex = [TRPBaseUIViewController]()
    public weak var delegate: TRPCreateTripCoordinaterDelegate?
    private var coordinaterType: CoordinaterType = .create
    private var userProfileAnswers: [Int] = []
    private var dateOfBirth: String?
    private var laoderVC: TRPLoaderVC = TRPLoaderVC()
    private var loadedCity: TRPCity? {
        didSet {
            if let city = loadedCity {
                tripInformationVM?.setSelectedCity(city: city)
            }
        }
    }
    private var askUserAge = false
    private var isCityAutoSelected = false
    //NEW -- VIEW MODELS
    private var dateAndTrallerVM: DateAndTravellerCountViewModel?
    private var tripInformationVM: CreateTripTripInformationViewModel?
    private var stayShareVM: CreateTripStayShareViewModel?
    private var pickedInformationVM: CreateTripPickedInformationViewModel?
    private var personalizeTripVM: CreateTripPersonalizeTripViewModel?
    private var createTripContainerNavigation: UINavigationController?
    
    private var tripProfile: TRPTripProfile?
    private var editTripProfile: TRPEditTripProfile?
    
    private var oldTripProfile: TRPTripProfile?
    
    public var nexusTripStartDate: String? = nil
    public var nexusTripEndDate: String? = nil
    public var nexusTripMeetingPoint: String? = nil
    public var nexusDestinationId: Int? = nil
    public var nexusNumberOfAdults: Int? = nil
    public var nexusNumberOfChildren: Int? = nil
    
    public var selectedCompanion: [TRPCompanion] = [] {
        didSet {
            stayShareVM?.addTravellerCompanions(selectedCompanion)
            dateAndTrallerVM?.addTravellerCompanions(selectedCompanion)
        }
    }
    
    private(set) var stayAddress: TRPAccommodation? {
        didSet {
            stayShareVM?.setStayAddress(stayAddress)
            dateAndTrallerVM?.addStayAddress(stayAddress)
        }
    }
    
    public var currentViewState: ViewState = .selectCity {
        didSet {
            self.applyViewState(self.currentViewState)
        }
    }
    
    // USE CASES
    public var cityUseCases: TRPCityUseCases?
    public var questionUseCases: TRPQuestionsUseCases?
    public var userAnswersUseCases: UserAnswersUseCase?
    public var updateUserInfo: UpdateUserInfoUseCase?
    public var fetchUserInfo: FetchUserInfoUseCase?
    public var companionUseCases: TRPCompanionUseCases?
    public var fetchUserTripUseCase: FetchUserUpcomingTripUseCase?
    
    
    private(set) lazy var tripRepository: TRPTripRepository = {
        return TRPTripRepository()
    }()
    
    private(set) lazy var tripModelRepository: TripModelRepository = {
        return TRPTripModelRepository()
    }()
    
    private lazy var createTripUseCase: TRPCreateTripUseCase = {
        return TRPCreateTripUseCase(repository: self.tripRepository)
    }()
    
    private lazy var editTripUseCase: TRPEditTripUseCases? = {
        guard let profile = self.oldTripProfile else {return nil}
        return TRPEditTripUseCases(repository: self.tripRepository, oldTripProfile: profile)
    }()
    
    private lazy var fetchTripAllDay: TRPTripCheckAllPlanUseCases? = {
        return TRPTripCheckAllPlanUseCases(tripRepository: tripRepository, tripModelRepository: tripModelRepository)
    }()
    
    public init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    //Create a trip
    func start() {
        self.coordinaterType = .create
        self.prepareData()
        self.openCreateTripContainer()
    }
    //Create a trip with city
    func start(city: TRPCity?) {
        self.coordinaterType = .create
        self.loadedCity = city
        self.prepareData()
        self.openCreateTripContainer()
    }
    
    public func startTravelCompanion(fromSDK: Bool = false, fromProfile: Bool = false) {
        self.prepareData()
        openSelectTravelCompanionVC(UIViewController(), fromSDK: fromSDK, fromProfile: fromProfile)
    }
    
    /// Edit Trip
    /// - Parameters:
    ///   - tripHash: Trip hash
    ///   - tripProfile: Trip profile that contaion information about trip
    ///   - city: City of Trip
    func start(tripHash: String,
               tripProfile: TRPTripProfile,
               city: TRPCity) {
        self.coordinaterType = .edit
        self.createEditTripProperties(cityId: city.id,
                                      tripHash: tripHash)
        self.oldTripProfile = tripProfile
        self.loadedCity = city
        self.prepareData()
        self.openCreateTripContainer()
//        self.currentViewState = .dateAndPeopleCount
    }
    
    public func cleanNavigationItems() {
        createTripNavIndex = []
    }
    
    
    /// Manages transitions between views. Assigns the view based on the current state
    /// - Parameter state: ViewState
    private func applyViewState(_ state: ViewState) {
        switch currentViewState {
        case .selectCity:
            openCreateTripContainer()
        case .dateAndPeopleCount:
            openDateAndTravellerVC()
        case .tripQuestions:
            openTripQuestion()
        case .createOrEditTrip:
            break
        }
    }
    
    
    /// Adds a new view to the NavigationController
    /// - Parameter viewController: The view to be displayed on the screen
    private func pushViewInNavigationController(_ viewController: TRPBaseUIViewController) {
        navigationController.pushViewController(viewController, animated: true)
        createTripNavIndex.append(viewController)
    }
    
    private func activeProfile() -> TRPTripProfile? {
        var profile: TRPTripProfile?
        if let editProfile = editTripProfile {
            profile = editProfile
        }else if let createTripProfile = tripProfile {
            profile = createTripProfile
        }
        return profile
    }
    
    deinit {
        removeObservers()
    }
}

//MARK: - Prepare Data
extension TRPCreateTripCoordinater {
    
    private func prepareData() {
        travelCompanion()
        hotelAddress()
    }
    
    private func travelCompanion() {
        companionUseCases?.values.addObserver(self, observer: { [weak self] companions in
            if let profile = self?.oldTripProfile {
                var selectedCompanions = [TRPCompanion]()
                for id in profile.companionIds {
                    if let companion = companions.first(where: {$0.id == id}) {
                        selectedCompanions.append(companion)
                    }
                }
                DispatchQueue.main.async {
                    self?.selectedCompanion = selectedCompanions
                }
            }
        })
        companionUseCases?.executeFetchCompanion(completion: nil)
    }
    
    private func hotelAddress() {
        let profile = oldTripProfile != nil ? oldTripProfile : tripProfile
        
        guard  let accommondation = profile?.accommodation  else {return}
        
        let coordinate = TRPLocation(lat: accommondation.coordinate.lat,
                                     lon: accommondation.coordinate.lon)
        
        stayAddress = TRPAccommodation(name: accommondation.name,
                                       referanceId: accommondation.referanceId,
                                       address: accommondation.address,
                                       coordinate: coordinate)
        
        
    }
    
    private func setUserInfo() {
        fetchUserInfo?.executeFetchUserInfo(completion: { [weak self] result in
            switch result {
            case .success(let user):
                if let answers = user.answers {
                    self?.userProfileAnswers = answers
                }
                if user.dateOfBirth == nil {
                    self?.askUserAge = true
                }
                self?.dateOfBirth = user.dateOfBirth
            case .failure(_): ()
            }
        })
    }
    
}

//MARK: - Prepare TripProperties
extension TRPCreateTripCoordinater {
    
    private func createTripProperties(cityId: Int) {
        tripProfile = TRPTripProfile(cityId: cityId)
        tripProfile?.profileAnswers = userProfileAnswers
    }
    
    private func createEditTripProperties(cityId: Int, tripHash hash: String) {
        editTripProfile = TRPEditTripProfile(cityId: cityId, tripHash: hash)
        editTripProfile?.profileAnswers = userProfileAnswers
    }
    
}

//MARK: - CREATE TRIP CONTAINER
extension TRPCreateTripCoordinater {
    fileprivate func openCreateTripContainer() {
        let viewController = UIStoryboard.makeCreateTripViewController() as CreateTripContainerVC
        tripProfile = TRPTripProfile(cityId: 0)
        viewController.addViewControllerInPagination(makeTripInformation())
        viewController.addViewControllerInPagination(makeStayShare())
        viewController.addViewControllerInPagination(makePickedInformationVC())
        viewController.addViewControllerInPagination(makePersonalizeTripVC())
        
        let viewModel = CreateTripContainerViewModel()
        viewModel.delegate = viewController
        viewModel.isEditing = coordinaterType == .edit
        viewModel.editTripUseCase = editTripUseCase
        viewModel.observeTripAllDay = fetchTripAllDay
        viewModel.fetchTripAllDay = fetchTripAllDay
        viewModel.createTripUseCase = createTripUseCase
        viewModel.fetchUserTripUseCase = fetchUserTripUseCase
        viewModel.nexusDestinationId = nexusDestinationId
        viewController.viewModel = viewModel
        viewController.delegate = self
        let navigation = UINavigationController(rootViewController: viewController)
        navigation.modalPresentationStyle = .fullScreen
        createTripContainerNavigation = navigation
        navigationController.present(navigation, animated: true, completion: nil)
        
        TRPTimelineMockCoordinator.quickTest(from: navigation)
    }
}

extension TRPCreateTripCoordinater: CreateTripContainerVCDelegate {
    public func cancelledEditTrip() {
        delegate?.trpTripCreateCoordinaterCleanCreateTrip()
    }
    
    public func tripGenerated(hash: String) {
        guard let city = loadedCity else {return}
        navigationController.removeFromParent()
        delegate?.trpTripCreateCoordinaterOpenMyTrip(hash: hash, city: city)
    }
    
    public func getProfileForCreateOrEditTrip() -> TRPTripProfile? {
        if coordinaterType == .create {
            return tripProfile
        } else {
            return editTripProfile
        }
    }
    
    public func canContinue(currentStep: CreateTripSteps) -> Bool {
        switch currentStep {
        case .tripInformation:
            guard let canContinue = self.tripInformationVM?.canContinue() else {
                return false
            }
            return canContinue
        case .stayShare:
            guard let canContinue = self.stayShareVM?.canContinue() else {
                return false
            }
            return canContinue
        case .pickedInformation:
            self.pickedInformationVM?.setTripProperties()
            self.personalizeTripVM?.selectedItems = self.pickedInformationVM?.selectedItems ?? []
            return true
        case .personalize:
            self.personalizeTripVM?.setTripProperties()
            return true
        }
    }
    
}

//MARK: Trip Information
extension TRPCreateTripCoordinater: CreateTripTripInformationVCDelegate {
    private func makeTripInformation() -> CreateTripTripInformationVC {
        
        guard let wrappedProfile = activeProfile() else {return CreateTripTripInformationVC()}
        
        let createTripTripInformationViewModel = CreateTripTripInformationViewModel(tripProfile: wrappedProfile,
                                                                                    oldTripProfile: oldTripProfile,
                                                                                    maxTripDays: loadedCity?.maxTripDays ?? 13,
                                                                                    loadedCity: loadedCity)
        
        let createTripTripInformationVC = UIStoryboard.makeCreateTripTripInformationViewController() as CreateTripTripInformationVC
        createTripTripInformationVC.viewModel = createTripTripInformationViewModel
        createTripTripInformationVC.delegate = self
        createTripTripInformationViewModel.delegate = createTripTripInformationVC
        if let nexusTripStartDate = nexusTripStartDate, let nexusTripEndDate = nexusTripEndDate, let city = loadedCity {
            createTripTripInformationViewModel.setNexusTripInformation(startDate: nexusTripStartDate, endDate: nexusTripEndDate, city: city)
        }
        tripInformationVM = createTripTripInformationViewModel
        return createTripTripInformationVC
    }
    
    public func createTripTripInformationVCOpenSelectCity(_ viewController: UIViewController) {
        let selectCity = getSelectCityVC()
        viewController.presentVCWithModal(selectCity, onlyLarge: true)
    }
    
    public func createTripTripInformationVCOpenDate(_ viewController: UIViewController, isArrival: Bool, arrivalDate: CreateTripDateModel?, departureDate: CreateTripDateModel?) {
//        let selectDateVC = UIStoryboard.makeCreateTripSelectDateViewController() as CreateTripSelectDateVC
//        selectDateVC.modalPresentationStyle = .pageSheet
//        if #available(iOS 15.0, *) {
//            if let sheet = selectDateVC.sheetPresentationController {
//                sheet.detents = [.medium()]
//            }
//        }
//        let viewModel = CreateTripSelectDateViewModel()
//        viewModel.isArrival = isArrival
//        if isArrival {
//            viewModel.dateModel = arrivalDate
//        } else {
//            viewModel.dateModel = departureDate
//        }
//        selectDateVC.viewModel = viewModel
//        selectDateVC.delegate = self
//        viewController.present(selectDateVC, animated: true)
        TRPTimelineMockCoordinator.quickTest(from: viewController)
//        let calendarVC = TRPCalendarViewController(
//            allowsMultipleSelection: false,  // Enable range selection
//            minimumDate: Date().addDay(-5000),           // Optional minimum date
//            maximumDate: Date().addDay(5000),               // Optional maximum date
//            preselectedDate: nil,
//            selectableStartDate: Date(),
//            selectableEndDate: Date().addDay(5)
//            
//        )
//
////        calendarVC.delegate = self
////        calendarVC.show()
//        viewController.present(calendarVC, animated: true)
    }
    
    public func createTripTripInformationVCOpenHour(_ viewController: UIViewController, isArrival: Bool, selectedHour: String?, minimumHour: String?) {
//        let selectHourVC = UIStoryboard.makeCreateTripSelectTimeViewController() as CreateTripSelectTimeVC
//        selectHourVC.modalPresentationStyle = .pageSheet
//        if #available(iOS 15.0, *) {
//            if let sheet = selectHourVC.sheetPresentationController {
//                sheet.detents = [.medium()]
//            }
//        }
//        let viewModel = CreateTripSelectTimeViewModel()
//        viewModel.isArrival = isArrival
//        viewModel.selectedHour = selectedHour
//        viewModel.minimumHour = minimumHour
//        viewModel.start()
//        selectHourVC.delegate = self
//        selectHourVC.viewModel = viewModel
//        viewController.present(selectHourVC, animated: true)
        let timeRangeVC = TRPTimeRangeSelectionViewController()
//                timeRangeVC.delegate = self
                timeRangeVC.setInitialTimes(from: "11:00 AM", to: "12:00 PM")
                timeRangeVC.show(from: viewController)
//        viewController.present(timeRangeVC, animated: true)
    }
}

extension TRPCreateTripCoordinater: CreateTripSelectDateVCDelegate {
    func createTripSelectDateVCArrivalSelected(date: String) {
        tripInformationVM?.setSelectedArrivalDate(date)
    }
    
    func createTripSelectDateVCDepartureSelected(date: String) {
        tripInformationVM?.setSelectedDepartureDate(date)
    }
    
    
}

extension TRPCreateTripCoordinater: CreateTripSelectTimeVCDelegate {
    func createTripSelectTimeVCArrivalSelected(hour: String) {
        tripInformationVM?.setSelectedArrivalHour(hour)
    }
    
    func createTripSelectTimeVCDepartureSelected(hour: String) {
        tripInformationVM?.setSelectedDepartureHour(hour)
    }
    
    
}

//MARK: Stay & Share
extension TRPCreateTripCoordinater: CreateTripStayShareVCDelegate {
    
    private func makeStayShare() -> CreateTripStayShareVC {
        
        guard let wrappedProfile = activeProfile() else {return CreateTripStayShareVC()}
        
        if let nexusNumberOfAdults { wrappedProfile.numberOfAdults = nexusNumberOfAdults }
        if let nexusNumberOfChildren { wrappedProfile.numberOfChildren = nexusNumberOfChildren }
        let viewModel = CreateTripStayShareViewModel(tripProfile: wrappedProfile, oldTripProfile: oldTripProfile)
        let viewController = UIStoryboard.makeCreateTripStayShareViewController() as CreateTripStayShareVC
        viewController.viewModel = viewModel
        viewModel.delegate = viewController
        viewController.delegate = self
        stayShareVM = viewModel
        return viewController
    }
    
    public func createTripStayShareVCOpenSelectHotel(_ viewController: UIViewController) {
        let selectCity = getSelectAddressVC()
        viewController.presentVCWithModal(selectCity, onlyLarge: true)
    }
    
    public func createTripStayShareVCOpenSelectCompanion(_ viewController: UIViewController, selectedCompanions: [TRPCompanion]) {
        let addCompanion = getSelectTravelCompanionVC(viewController, selectedCompanios: selectedCompanions)
        viewController.presentVCWithModal(addCompanion)

    }
    
    public func createTripStayShareVCOpenCreateCompanion(_ viewController: UIViewController) {
        let addCompanion = getAddTravelCompanionVC()
        viewController.presentVCWithModal(addCompanion, onlyLarge: true)

    }
    public func createTripStayShareVCCompanionRemoved(_ companion: TRPCompanion) {
        self.selectedCompanion.remove(element: companion)
    }
}

//MARK: PickedInformation
extension TRPCreateTripCoordinater: CreateTripPickedInformationVCDelegate {
    
    private func makePickedInformationVC() -> CreateTripPickedInformationVC{
        
        guard let wrappedProfile = activeProfile() else {return CreateTripPickedInformationVC()}
        
        pickedInformationVM = CreateTripPickedInformationViewModel(tripProfile: wrappedProfile, oldTripProfile: oldTripProfile)
        let pickedInformationVC = UIStoryboard.makeCreateTripPickedInformationViewController() as CreateTripPickedInformationVC
        pickedInformationVC.viewModel = pickedInformationVM
        pickedInformationVM?.tripQuestionUseCase = questionUseCases
        pickedInformationVM?.delegate = pickedInformationVC
        pickedInformationVC.delegate = self
        return pickedInformationVC
        
    }
    
    
    func createTripPickedInformationVCDelegateOpenSelectAnswer(_ viewController: UIViewController, question: SelectableQuestionModelNew) {

        let selectRestaurantPreferVC = UIStoryboard.makeCreateTripSelectRestaurantPreferViewController() as CreateTripSelectRestaurantPreferVC
        let viewModel = CreateTripSelectRestaurantPreferViewModel()
        viewModel.selectableQuestion = question
        selectRestaurantPreferVC.delegate = self
        selectRestaurantPreferVC.viewModel = viewModel
        viewController.presentVCWithModal(selectRestaurantPreferVC)
    }
    
}

extension TRPCreateTripCoordinater: CreateTripSelectRestaurantPreferVCDelegate {
    func createTripSelectRestaurantPreferVCSetSelectedAnswer(_ answer: SelectableAnswer, question: SelectableQuestionModelNew) {
        pickedInformationVM?.insertSelectedRestaurantAnswer(question: question, answer: answer)
    }
}

//MARK: Personalize Trip
extension TRPCreateTripCoordinater {
    
    private func makePersonalizeTripVC() -> CreateTripPersonalizeTripVC{
        
        guard let wrappedProfile = activeProfile() else {return CreateTripPersonalizeTripVC()}
        
        personalizeTripVM = CreateTripPersonalizeTripViewModel(tripProfile: wrappedProfile, oldTripProfile: oldTripProfile)
        let pickedInformationVC = UIStoryboard.makeCreateTripPersonalizeTripViewController() as CreateTripPersonalizeTripVC
        pickedInformationVC.viewModel = personalizeTripVM
        personalizeTripVM?.tripQuestionUseCase = questionUseCases
        personalizeTripVM?.delegate = pickedInformationVC
        pickedInformationVC.delegate = self
        return pickedInformationVC
        
    }
    
}




// MARK: - Select City
extension TRPCreateTripCoordinater: SelectCityVCDelegate {
    fileprivate func getSelectCityVC() -> SelectCityVC {
        let viewModel = SelectCityViewModel()
        viewModel.fetchCityUseCase = cityUseCases
        
        let viewController = UIStoryboard.makeSelectCityViewController() as SelectCityVC
        viewController.viewModel = viewModel
        viewController.delegate = self
        viewModel.delegate = viewController
        return viewController
    }
    
    fileprivate func openSelectCityVC() {
        let viewModel = SelectCityViewModel()
        viewModel.fetchCityUseCase = cityUseCases
        
        let viewController = UIStoryboard.makeSelectCityViewController() as SelectCityVC
        viewController.viewModel = viewModel
        viewController.delegate = self
        viewModel.delegate = viewController
        
        pushViewInNavigationController(viewController)
    }
    
    public func selectedCity(cityId: Int, city: TRPCity) {
        loadedCity = city
        let profile = activeProfile()
        profile?.cityId = cityId
        tripInformationVM?.setSelectedCity(city: city)
    }
    
}

//MARK: - Date And TravellerVC
extension TRPCreateTripCoordinater: DateAndTravellerCountVCDelegate {
    
    private func openDateAndTravellerVC() {
        
        guard let wrappedProfile = activeProfile() else {return}
        
        let dateAndTravellerViewModel = DateAndTravellerCountViewModel(tripProfile: wrappedProfile,
                                                                       oldTripProfile: oldTripProfile,
                                                                       askUserAge: askUserAge,
                                                                       maxTripDays: loadedCity?.maxTripDays ?? 3)
        dateAndTravellerViewModel.fetchCompanionUseCase = companionUseCases
        dateAndTravellerViewModel.observeCompanionUseCases = companionUseCases
        
        let dataAndTravellerViewController = UIStoryboard.makeSelectDateViewController() as DateAndTravellerCountVC
        dataAndTravellerViewController.viewModel = dateAndTravellerViewModel
        dateAndTravellerViewModel.delegate = dataAndTravellerViewController
        dataAndTravellerViewController.delegate = self
        pushViewInNavigationController(dataAndTravellerViewController)
        self.dateAndTrallerVM = dateAndTravellerViewModel
    }
    
    public func dateAndTravellerCountVCOpenTravelers(_ viewController: UIViewController, adultCount: Int, childrenCount: Int) {
        openSelectTravelerCountVC(viewController, adultCount: adultCount, childCount: childrenCount)
    }
    
    public func dateAndTravellerCountVCOpenCompanion(_ viewController: UIViewController) {
        openSelectTravelCompanionVC(viewController)
    }
    
    public func dateAndTravellerCountVCOpenStayAddress(_ viewController: UIViewController) {
        openStayAddress(viewController)
    }
    
    public func dateAndTravellerCountVCCompleted() {
        currentViewState = .tripQuestions
    }
    
    public func dateAndTravellerCountVCUpdateUserDateOfBirth(_ dateOfBirth: String) {
        updateUserInfo?.executeUpdateUserInfo( dateOfBirth: dateOfBirth, completion: nil)
    }
}

//MARK: - Trip Questions
extension TRPCreateTripCoordinater: TripQuestionsVCDelegate {
    
    private func openTripQuestion() {
        guard let wrappedProfile = activeProfile() else {return}
        
        let tripQuestionViewModel = TripQuestionViewModel(tripProfile: wrappedProfile, oldTripProfile: oldTripProfile)
        let tripQuestionVC = UIStoryboard.makeTripQuestionsViewController() as TripQuestionsViewController
        tripQuestionVC.viewModel = tripQuestionViewModel
        tripQuestionViewModel.tripQuestionUseCase = questionUseCases
        tripQuestionViewModel.delegate = tripQuestionVC
        tripQuestionVC.delegate = self
        pushViewInNavigationController(tripQuestionVC)
        
    }
    
    func tripQuestionsVCCompleted() {
        currentViewState = .createOrEditTrip
    }
}

//MARK: - Select Travalers Count
extension TRPCreateTripCoordinater: SelectTravalerCountVCDelegate {
    
    private func openSelectTravelerCountVC(_ parentVC: UIViewController, adultCount: Int, childCount: Int) {
        
        let selectTravelerCountVM = SelectTravelerCountVM()
        selectTravelerCountVM.adultCount = adultCount
        selectTravelerCountVM.childrenCount = childCount
        let vc = UIStoryboard.makeSelectTravalerCountViewController() as SelectTravalerCountVC
        vc.viewModel = selectTravelerCountVM
        selectTravelerCountVM.delegate = vc
        vc.delegate = self
        
        parentVC.present(vc, animated: false, completion: nil)
    }
    
    public func travelersConfirmed(adultCount: Int, childrenCount: Int) {
        dateAndTrallerVM?.setTravelersCount(adult: adultCount, child: childrenCount)
    }
    
}

//MARK: - Select Travel Companion Create trip
extension TRPCreateTripCoordinater: CreateTripSelectCompanionVCDelegate {
    
    private func getSelectTravelCompanionVC(_ viewController: UIViewController, selectedCompanios: [TRPCompanion]) -> CreateTripSelectCompanionVC {
        
        let selectCompanionVM = CreateTripSelectCompanionViewModel()
        selectCompanionVM.fetchCompanionsUseCase = companionUseCases
        selectCompanionVM.observeCompanionUseCase = companionUseCases
        
        let vc = UIStoryboard.makeCreateTripSelectCompanionViewController() as CreateTripSelectCompanionVC
        vc.viewModel = selectCompanionVM
        selectCompanionVM.delegate = vc
        selectCompanionVM.selectedItems = selectedCompanios
        vc.delegate = self
        
        return vc
    }
    
    func createTripSelectCompanionSelected(companions: [TRPCompanion]) {
        self.selectedCompanion = companions
    }
    
    func createTripSelectCompanionCreateNew() {
        createTripStayShareVCOpenCreateCompanion(navigationController)
    }
    
    
}

//MARK: - Select Travel Companion
extension TRPCreateTripCoordinater: SelectCompanionVCDelegate {
    
    
    private func openSelectTravelCompanionVC(_ viewController: UIViewController, fromSDK: Bool = false , fromProfile: Bool = false) {
        
        let selectCompanionVM = SelectCompanionVM()
        selectCompanionVM.fetchCompanionsUseCase = companionUseCases
        selectCompanionVM.observeCompanionUseCase = companionUseCases
        selectCompanionVM.deleteCompaninoUseCase = companionUseCases
        selectCompanionVM.fromSDK = fromSDK
        selectCompanionVM.fromProfile = fromProfile
        
        let vc = UIStoryboard.makeSelectCompanionViewController() as SelectCompanionVC
        vc.viewModel = selectCompanionVM
        selectCompanionVM.delegate = vc
        selectCompanionVM.selectedItem = selectedCompanion
        vc.delegate = self
        
        pushViewInNavigationController(vc)
    }
    
    public func companionsSelected(_ vc: SelectCompanionVC, selectedCompanion: [TRPCompanion]) {
        self.selectedCompanion = selectedCompanion
    }
    
    public func openAddCompanion(_ navigationController: UINavigationController?, viewController: UIViewController) {
        openAddTravelCompanionVC(navigationController, parentVC: viewController)
    }
    
    public func openEditCompanion(_ navigationController: UINavigationController?, viewController: UIViewController, companion: TRPCompanion) {
        openAddTravelCompanionVC(navigationController, parentVC: viewController, companion: companion)
    }
}

//MARK: - Add Travel Companion
extension TRPCreateTripCoordinater: CompanionDetailVCDelegate {
    
    public func companionDetailVCAdded(_ companion: TRPCompanion) {
        var tmpSelectedCompanions = selectedCompanion
        tmpSelectedCompanions.append(companion)
        selectedCompanion = tmpSelectedCompanions
    }
    
    public func companionDetailVCUpdated() {
    }
    
    private func getAddTravelCompanionVC(companion: TRPCompanion? = nil) -> CompanionDetailVC {
        let viewModel = CompanionDetailVM()
        viewModel.addCompanionUseCase = companionUseCases
        viewModel.updateCompanionUseCase = companionUseCases
        if questionUseCases == nil {
            questionUseCases = TRPQuestionsUseCases()
        }
        viewModel.fetchCompanionQuestionUseCase = questionUseCases
        
        let viewController = UIStoryboard.makeCompanionDetailViewController() as CompanionDetailVC
        
        viewController.viewModel = viewModel
        viewModel.detailType = .addCompanion
        if let companion = companion {
            viewModel.detailType = .updateCompanion
            viewModel.currentCompanion = companion
        }
        viewModel.delegate = viewController
        viewController.delegate = self
        viewModel.start()
        return viewController
    }
    
    private func openAddTravelCompanionVC(_ navigationController: UINavigationController?, parentVC: UIViewController, companion: TRPCompanion? = nil) {
        let viewModel = CompanionDetailVM()
        viewModel.addCompanionUseCase = companionUseCases
        viewModel.updateCompanionUseCase = companionUseCases
        if questionUseCases == nil {
            questionUseCases = TRPQuestionsUseCases()
        }
        viewModel.fetchCompanionQuestionUseCase = questionUseCases
        
        let viewController = UIStoryboard.makeCompanionDetailViewController() as CompanionDetailVC
        
        viewController.viewModel = viewModel
        viewModel.detailType = .addCompanion
        if let companion = companion {
            viewModel.detailType = .updateCompanion
            viewModel.currentCompanion = companion
        }
        viewModel.delegate = viewController
        viewController.delegate = self

        viewModel.start()

        parentVC.presentVCWithModal(viewController, onlyLarge: true)
    }
}

//MARK: - StayAddress
extension TRPCreateTripCoordinater: StayAddressVCDelegate{
    
    fileprivate func getSelectAddressVC() -> StayAddressVC {
        let viewModel = StayAddressViewModel(boundarySW: loadedCity?.boundarySouthWest,
                                             boundaryNE: loadedCity?.boundaryNorthEast,
                                             accommondation: stayAddress,
                                             meetingPoint: nexusTripMeetingPoint)
        let viewController = UIStoryboard.makeSelectStayAddressViewController() as StayAddressVC
        viewController.viewModel = viewModel
        viewModel.delegate = viewController
        viewController.delegate = self
        return viewController
    }
    
    private func openStayAddress(_ parentVC: UIViewController) {
        let viewModel = StayAddressViewModel(boundarySW: loadedCity?.boundarySouthWest,
                                             boundaryNE: loadedCity?.boundaryNorthEast,
                                             accommondation: stayAddress,
                                             meetingPoint: nexusTripMeetingPoint)
        let viewController = UIStoryboard.makeSelectStayAddressViewController() as StayAddressVC
        viewController.viewModel = viewModel
        viewModel.delegate = viewController
        viewController.delegate = self
        
        pushViewInNavigationController(viewController)
    }
    
    public func stayAddressContinuePressed(mustClean: Bool) {
        self.stayAddress = nil
    }
    
    public func stayAddressSelectedPlace(stayAddress: TRPAccommodation) {
        self.stayAddress = stayAddress
    }
    
}

extension TRPCreateTripCoordinater: ObserverProtocol {
    
    func addObservers() {}
    
    func removeObservers() {
        companionUseCases?.values.removeObserver(self)
        fetchTripAllDay?.firstTripGenerated.removeObserver(self)
    }
    
}
