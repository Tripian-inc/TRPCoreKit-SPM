//
//  TRPCreateTripCoordinater.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 6.10.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//
import Foundation
import TRPRestKit
import TRPFoundationKit
import TRPUIKit
import TRPDataLayer
import TRPProvider

public protocol TRPCreateTripCoordinaterDelegate: AnyObject {
    func trpTripCreateCoordinaterOpenMyTrip(hash: String, city: TRPCity, destinationId: String)
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
    private(set) var createTripNavIndex = [UIViewController]()
    public weak var delegate: TRPCreateTripCoordinaterDelegate?
    private var coordinaterType: CoordinaterType = .create
    private var userProfileAnswers: [Int] = []
    private var dateOfBirth: String?
    private var loader: TRPLoaderView?
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
    public var nexusDestinationId: String? = nil
    
    private var isLoaderShowing = false
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
//        self.currentViewState = .selectCity
    }
    //Create a trip with city
    func start(city: TRPCity?) {
        self.coordinaterType = .create
        self.loadedCity = city
        self.prepareData()
        self.openCreateTripContainer()
//        self.currentViewState = .selectCity
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
    
    
    /// Viewler arası geçişi ayarlar. State e göre view ataması yapar
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
            createAOrEdiTrip()
        }
    }
    
    
    /// NavigationController' a yeni bir view ekler
    /// - Parameter viewController: Ekranda gösterilecek view
    private func pushViewInNavigationController(_ viewController: UIViewController) {
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
        Log.deInitialize()
    }
    
//    private func setNavigationStyleFor(_ nav: UINavigationController) {
//        nav.navigationBar.barStyle = .blackTranslucent
//        nav.navigationBar.barTintColor = TRPAppearanceSettings.Common.navigationBarTintColor
//        nav.navigationBar.tintColor = TRPAppearanceSettings.Common.navigationTintColor
//        nav.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: TRPAppearanceSettings.Common.navigationTitleTextColor]
//    }
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
        viewController.viewModel = viewModel
        viewController.delegate = self
        let navigation = UINavigationController(rootViewController: viewController)
        navigation.modalPresentationStyle = .fullScreen
        createTripContainerNavigation = navigation
        navigationController.present(navigation, animated: true, completion: nil)
    }
}

extension TRPCreateTripCoordinater: CreateTripContainerVCDelegate {
    public func createOrEditTrip() {
        createAOrEdiTrip()
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
        selectCity.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = selectCity.sheetPresentationController {
                sheet.detents = [.large()]
            }
        }
        viewController.present(selectCity, animated: true)
    }
    
    public func createTripTripInformationVCOpenDate(_ viewController: UIViewController, isArrival: Bool, arrivalDate: CreateTripDateModel?, departureDate: CreateTripDateModel?) {
        let selectDateVC = UIStoryboard.makeCreateTripSelectDateViewController() as CreateTripSelectDateVC
        selectDateVC.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = selectDateVC.sheetPresentationController {
                sheet.detents = [.medium()]
            }
        }
        let viewModel = CreateTripSelectDateViewModel()
        viewModel.isArrival = isArrival
        if isArrival {
            viewModel.dateModel = arrivalDate
        } else {
            viewModel.dateModel = departureDate
        }
        selectDateVC.viewModel = viewModel
        selectDateVC.delegate = self
        viewController.present(selectDateVC, animated: true)
    }
    
    public func createTripTripInformationVCOpenHour(_ viewController: UIViewController, isArrival: Bool, selectedHour: String?, minimumHour: String?) {
        let selectHourVC = UIStoryboard.makeCreateTripSelectTimeViewController() as CreateTripSelectTimeVC
        selectHourVC.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = selectHourVC.sheetPresentationController {
                sheet.detents = [.medium()]
            }
        }
        let viewModel = CreateTripSelectTimeViewModel()
        viewModel.isArrival = isArrival
        viewModel.selectedHour = selectedHour
        viewModel.minimumHour = minimumHour
        viewModel.start()
        selectHourVC.delegate = self
        selectHourVC.viewModel = viewModel
        viewController.present(selectHourVC, animated: true)
    }
}

extension TRPCreateTripCoordinater: CreateTripSelectDateVCDelegate {
    func createTripSelectDateVCArrivalSelected(date: Date) {
        tripInformationVM?.setSelectedArrivalDate(date)
    }
    
    func createTripSelectDateVCDepartureSelected(date: Date) {
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
        selectCity.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = selectCity.sheetPresentationController {
                sheet.detents = [.large()]
            }
        }
        viewController.present(selectCity, animated: true)
    }
    
    public func createTripStayShareVCOpenSelectCompanion(_ viewController: UIViewController, selectedCompanions: [TRPCompanion]) {
        let addCompanion = getSelectTravelCompanionVC(viewController, selectedCompanios: selectedCompanions)
        addCompanion.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = addCompanion.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
            }
        }
        viewController.present(addCompanion, animated: true)
        
    }
    
    public func createTripStayShareVCOpenCreateCompanion(_ viewController: UIViewController) {
        let addCompanion = getAddTravelCompanionVC()
        addCompanion.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = addCompanion.sheetPresentationController {
                sheet.detents = [.large()]
            }
        }
        viewController.present(addCompanion, animated: true)
        
    }
    public func createTripStayShareVCCompanionRemoved(_ companion: TRPDataLayer.TRPCompanion) {
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
        //tripQuestionViewModel.addPaceQuesions()
        pickedInformationVC.delegate = self
        return pickedInformationVC
        
    }
    
    
    func createTripPickedInformationVCDelegateOpenSelectAnswer(_ viewController: UIViewController, question: SelectableQuestionModelNew) {
        
        let selectRestaurantPreferVC = UIStoryboard.makeCreateTripSelectRestaurantPreferViewController() as CreateTripSelectRestaurantPreferVC
        selectRestaurantPreferVC.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = selectRestaurantPreferVC.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
            }
        }
        let viewModel = CreateTripSelectRestaurantPreferViewModel()
        viewModel.selectableQuestion = question
        selectRestaurantPreferVC.delegate = self
        selectRestaurantPreferVC.viewModel = viewModel
        viewController.present(selectRestaurantPreferVC, animated: true)
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
        //tripQuestionViewModel.addPaceQuesions()
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
//        createTripProperties(cityId: city.id)
//        currentViewState = .dateAndPeopleCount
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
    
//    public func dateAndTravellerCountVCUpdateUserage(_ age: Int) {
//        updateUserInfo?.executeUpdateUserInfo( age: age, completion: nil)
//    }
    
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
        //tripQuestionViewModel.addPaceQuesions()
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
//        pushViewInNavigationController(vc)
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
        EvrAlertView.showAlert(contentText: "Successfully added.".toLocalized(), type: .success)
        var tmpSelectedCompanions = selectedCompanion
        tmpSelectedCompanions.append(companion)
        selectedCompanion = tmpSelectedCompanions
    }
    
    public func companionDetailVCUpdated() {
        EvrAlertView.showAlert(contentText: "Successfully edited!".toLocalized(), type: .success)
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
        
//        parentVC.present(viewController, animated: false, completion: nil)
        viewModel.start()
        
        viewController.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = viewController.sheetPresentationController {
                sheet.detents = [.large()]
            }
        }
        parentVC.present(viewController, animated: true)
    }
}

//MARK: - StayAddress
extension TRPCreateTripCoordinater: StayAddressVCDelegate{
    
    fileprivate func getSelectAddressVC() -> StayAddressVC {
        let viewModel = StayAddressViewModel(boundaryNW: loadedCity?.boundarySouthWest,
                                             boundaryES: loadedCity?.boundaryNorthEast,
                                             accommondation: stayAddress, 
                                             meetingPoint: nexusTripMeetingPoint)
        let viewController = UIStoryboard.makeSelectStayAddressViewController() as StayAddressVC
        viewController.viewModel = viewModel
        viewModel.delegate = viewController
        viewController.delegate = self
        return viewController
    }
    
    private func openStayAddress(_ parentVC: UIViewController) {
        //[39.60829, 40.24261, 32.43424, 33.27918]
        
        let viewModel = StayAddressViewModel(boundaryNW: loadedCity?.boundarySouthWest,
                                             boundaryES: loadedCity?.boundaryNorthEast,
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


//MARK: - Create Trip
extension TRPCreateTripCoordinater {
    
    private func createAOrEdiTrip() {
        if coordinaterType == .create {
            if let profile = tripProfile {
                if profile.additionalData == nil {
                    getJuniperDestinationId(cityId: profile.cityId)
                    return
                }
                createTrip(profile: profile)
            }
        }else {
            
            guard let editProfile = editTripProfile else {return}
            
            let doNotGenerate = editTripUseCase?.doNotGenerate(newProfile: editProfile)
            
            if doNotGenerate  == false{
                let alert = UIAlertController(title: "Your trip is going to be updated.".toLocalized(), message: "".toLocalized(), preferredStyle: .alert)
                let cancelBtn = UIAlertAction(title: "Cancel".toLocalized(), style: .cancel, handler: { (action) in
                    self.delegate?.trpTripCreateCoordinaterCleanCreateTrip()
                })
                let continueBtn = UIAlertAction(title: "Continue".toLocalized(), style: .destructive, handler: {[weak self ] (action) in
                    self?.editTrip(profile: editProfile)
                })
                continueBtn.setValue(TRPAppearanceSettings.Common.continueButtonColor, forKey: "titleTextColor")
                alert.addAction(cancelBtn)
                alert.addAction(continueBtn)
                if let lastView = createTripNavIndex.last {
                    lastView.present(alert, animated: true, completion: nil)
                }else {
                    editTrip(profile: editProfile)
                }
            }else {
                editTrip(profile: editProfile)
            }
        }
    }
    
    private func createTrip(profile: TRPTripProfile) {
        showPreloaderWithCreateOrEditTrip(show: true)
        createTripUseCase.executeCreateTrip(profile: profile) { [weak self] result in
            guard let strongSelf = self else { return }
            
            switch result {
            case .success(let trip):
                strongSelf.fetchUpcomingTrip()
                strongSelf.checkTripIsGenerated(tripHash: trip.tripHash)
            case .failure(let error):
                strongSelf.showPreloaderWithCreateOrEditTrip(show: false)
                strongSelf.showErrorWithCreateOrEditTrip(error)
            }
        }
    }
    
    private func getJuniperDestinationId(cityId: Int) {
        showPreloaderWithCreateOrEditTrip(show: true)
        TripianCommonApi().getDestinationIdFromCity(cityId) { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let id):
                strongSelf.nexusDestinationId = "\(id)"
                strongSelf.tripProfile?.additionalData = "\(id)"
            case .failure(let failure):
                print(failure)
            }
            strongSelf.createOrEditTrip()
        }
    }
    
    private func editTrip(profile: TRPEditTripProfile) {
        
        showPreloaderWithCreateOrEditTrip(show: true)
        
        editTripUseCase?.executeEditTrip(profile: profile) { [weak self] result in
            self?.showPreloaderWithCreateOrEditTrip(show: false)
            switch result {
            case .success(let trip):
                self?.fetchUpcomingTrip()
                self?.delegate?.trpTripCreateCoordinaterOpenMyTrip(hash: trip.tripHash, city: trip.city, destinationId: trip.tripProfile.additionalData ?? "")
            case .failure(let error):
                print("[Error] \(error.localizedDescription)")
                self?.showErrorWithCreateOrEditTrip(error)
            }
        }
        
    }
    
    private func showErrorWithCreateOrEditTrip(_ error: Error) {
        EvrAlertView.showAlert(contentText: error.localizedDescription, type: .error, parentViewController: createTripContainerNavigation)
    }
    
    private func showPreloaderWithCreateOrEditTrip(show: Bool) {
        
        DispatchQueue.main.async {
            if show {
                if self.isLoaderShowing == false {
                    self.isLoaderShowing = true
                    self.laoderVC.modalPresentationStyle = .overCurrentContext
                    self.createTripContainerNavigation?.present(self.laoderVC, animated: false, completion: nil)
                    self.laoderVC.show()
                }
            }else {
                self.isLoaderShowing = false
                self.laoderVC.dismiss(animated: false, completion: nil)
            }
        }
    }
    
    private func fetchUpcomingTrip() {
        fetchUserTripUseCase?.executeUpcomingTrip(completion: nil)
    }
}

//MARK: - CHECK TRIP IS GENERETED
extension TRPCreateTripCoordinater {
    
    func checkTripIsGenerated(tripHash hash: String) {
        
        fetchTripAllDay?.firstTripGenerated.addObserver(self, observer: { [weak self] status in
            if !status {return}
            self?.showPreloaderWithCreateOrEditTrip(show: false)
//            self?.openOverView(tripHash: hash)
            
            guard let city = self?.loadedCity else {return}
            if self?.isLoaderShowing == true {
                self?.isLoaderShowing = false
                self?.laoderVC.dismiss(animated: false, completion: nil)
            }
            self?.navigationController.removeFromParent()
            self?.delegate?.trpTripCreateCoordinaterOpenMyTrip(hash: hash, city: city, destinationId: self?.nexusDestinationId ?? "")
//            self?.navigationController.dismiss(animated: true)
        })
        
        fetchTripAllDay?.executeFetchTripCheckAllPlanGenerate(tripHash: hash, completion: nil)
    }
}

extension TRPCreateTripCoordinater: OverviewContainerVCDelegate {
    
    
    private func openOverView(tripHash: String) {
        createTripContainerNavigation?.dismiss(animated: true)
        let viewModel = OverviewContainerViewModel(tripHash: tripHash)
        let viewController = UIStoryboard.makeOverviewContainerViewController()
        viewController.viewModel = viewModel
        viewModel.tripObserverUseCase = fetchTripAllDay
        viewModel.delegate = viewController
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
        fetchTripAllDay?.executeFetchTripCheckAllPlanGenerate(tripHash: tripHash, completion: nil)
    }
    
    func overviewContainerVCDidAppear(_ viewController: UIViewController) {
        clearAllCreateTripVC()
    }
    
    func overviewContainerVCContinuePressed() {
        guard let tripHash = fetchTripAllDay?.trip.value?.tripHash, let city = loadedCity else {return}
        self.delegate?.trpTripCreateCoordinaterOpenMyTrip(hash: tripHash, city: city, destinationId: self.nexusDestinationId ?? "")
    }
    
}

extension TRPCreateTripCoordinater: ObserverProtocol {
    
    func addObservers() {}
    
    func removeObservers() {
        companionUseCases?.values.removeObserver(self)
        fetchTripAllDay?.firstTripGenerated.removeObserver(self)
    }
    
}


//TODO: TRİPMODE A TAŞINACAK.
extension TRPCreateTripCoordinater: ButterFlyContainerVCProtocol, PlaceDetailVCProtocol {
    
    func openButterflyVC(hash: String) {
        let viewModel = ButterflyContainerVM(tripHash: hash)
        viewModel.tripObserverUseCase = fetchTripAllDay
        
        
        let vc = ButterFlyContainerVC(viewModel: viewModel)
        vc.delegate = self
        viewModel.delegate = vc
        navigationController.pushViewController(vc, animated: true)
    }
    
    public func butterflyContainerCompleted(hash: String) {
        if let city = loadedCity {
            self.delegate?.trpTripCreateCoordinaterOpenMyTrip(hash: hash, city: city, destinationId: self.nexusDestinationId ?? "")
        }
    }
    
    public func butterflyContainerOpenPlaceDetail(place: TRPPoi) {
        /*let viewModel = PlaceDetailViewModel(place: place, mode: .Butterfly)
         let viewController = PlaceDetailVC(viewModel: viewModel)
         navigationController.present(viewController, animated: true, completion: nil) */
    }
    
    public func butterflyContainerViewDidAppear(_ vc: UIViewController) {
        clearAllCreateTripVC()
    }
    
    private func clearAllCreateTripVC() {
        var startIndex: Int?
        var endIndex: Int?
        
        for (index, vc) in navigationController.viewControllers.enumerated() {
            if vc.isKind(of: MyTripVC.self) {
                startIndex = index + 1
            }else if vc.isKind(of: OverviewContainerVC.self) {
                endIndex = index
            }
        }
        if let start = startIndex, let end = endIndex {
            navigationController.viewControllers.removeSubrange(start..<end)
        }
    }
    
}
