//
//  PlaceDetailViewModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 4.09.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation









public protocol PlaceDetailVMDelegate: ViewModelDelegate {
    func viewModel(favoriteUpdated: Bool, isFavorite:Bool)
    func viewModel(changedButtonStatus: AddRemoveNavButtonStatus)
    func viewModel(problemCategory: [TRPProblemCategoriesInfoModel]?)
    func viewModel(favoriteError: String)
    
}

public class PlaceDetailViewModel1 {
    
    weak var delegate: PlaceDetailVMDelegate?
    
    //MARK: Property
    public var place: TRPPoi
    public var userLocationController: TRPUserLocationController
    private var parentStep: TRPStep?
    
    
    //MARK: UI
    public var addRemoveState: AddRemoveNavButtonStatus {
        get {
            if mode == .Butterfly {
                return .none
            }
            if mode == .Localy {
                return .navigation
            }
            if parentStep != nil {
                return .alternative
            }
            if isAddOnPlane == true {
                return .remove
            }else {
                return .add
            }
        }
    }
    
    //UI ile iletişim kurması için yapılmış, silinecek
    public var isFavorite: Bool = false {
        didSet {
            NotificationCenter.default.post(name: .TRPPlaceFavorite,
                                            object: self,
                                            userInfo: ["object": self.isFavorite])
        }
    }
    
    private var isAddOnPlane: Bool = false {
        didSet {
            self.delegate?.viewModel(changedButtonStatus: addRemoveState)
        }
    } //Buton statüsünü ayarlamak için
    private var isAlternative: Bool = false //Buton statüsünü ayarlamak için
    public var alternativeRefPoiId:Int?
    public var mode: SdkModeType
    public var showNavigationButton: Bool = false
    private var userReservations  = [TRPReservation]() {
        didSet {
            delegate?.viewModel(dataLoaded: true)
        }
    }
    
    var isRatingAvaliable : Bool {
        get {
            let raitingIsShow = TRPAppearanceSettings.ShowRating.type.contains { (category) -> Bool in
                guard let placeCategoty = place.categories.first else {return false}
                if category.getId() == placeCategoty.id {
                    return true
                }
                return false
            }
            if raitingIsShow && place.ratingCount != 0 {
                return true
            }
            return false
        }
    }
    
    var starCount: Int {
        guard let rating = place.rating else {return 0}
        return Int(rating.rounded())
    }
    
    public var dayAndMatchExplainText: NSMutableAttributedString {
        guard let trip = tripModelUseCases?.trip.value else { return NSMutableAttributedString() }
        let partOfDay = trip.getPartOfDay(placeId: place.id)
        let matchValue = trip.getPoiScore(poiId: place.id)
        let match: Int? = matchValue != nil ? Int(matchValue!) : nil
        
        return PartOfDayMatch.createExplaineText(partOfDay: partOfDay, matchRate: match)
    }
    
    @PriceIconWrapper
    private var dolarSignIcon = 0
    
    
    // USE CASES
    public var addFavoriteUseCase: AddFavoriteUseCase?
    public var deleteFavoriteUseCase: DeleteFavoriteUseCase?
    public var observeFavoriteUseCase: ObserveFavoritesUseCase?
    
    public var tripModelUseCases: ObserveTripModeUseCase?
    public var addStepUseCase: AddStepUseCase?
    public var deleteStepUseCase: DeleteStepUseCase?
    public var replaceWithAlternativeUseCase: EditStepUseCase?
    public var observeReservationUseCase: ObserveReservationUseCase?
    public var deleteReservationUseCase: DeleteReservationUseCase?
    
    
    
    public init(place: TRPPoi,
                mode: SdkModeType = .Trip,
                parentStep: TRPStep? = nil,
                userLocationController: TRPUserLocationController = .shared
    ) {
        self.userLocationController = userLocationController
        self.parentStep = parentStep
        self.mode = mode
        self.place = place
        print("PlaceId \(place.id)")
    }
    
    func start() {
        checkUserLocation()
        addObservers()
    }
    
    
    func getImageLink(url: String, w: Int, h: Int) -> String? {
        return TRPImageResizer.generate(withUrl: url, standart: .placeDetail)
    }
    
    
    public func getGalleryWithResizered(imageWidth width: Int, imageHeight height: Int) -> [PagingImage] {
        var gallery = [PagingImage]()
        for image in place.gallery{
            let url = getImageLink(url: image.url, w: width, h: height)
            let pagingModel = PagingImage(imageUrl: url, picOwner: image.imageOwner)
            gallery.append(pagingModel)
        }
        return gallery
    }
    
    func getPictureOwner() -> (name:String?, link:String?) {
        guard let name = place.image.imageOwner?.title,
            let link = place.image.imageOwner?.url, name.count > 1 else {
                return (name:nil,link:nil)
        }
        return (name:name, link:link)
    }
    
    func getMustTryText() -> String?{
        guard place.mustTries.count > 0 else {return nil}
        guard let cityName = tripModelUseCases?.trip.value?.city.name else {return nil}
        return "This spot serves one of the best \(place.mustTries.compactMap({$0.name}).toString(", ")) in \(cityName)"
        
    }
    
    func getBookingModel(withId id: Int) -> TRPBooking? {
        guard let booking = place.bookings else {return nil}
        return booking.first(where: {$0.providerId == id})
    }
    
    public func addStep() {
        addStepUseCase?.executeAddStep(poiId: self.place.id, completion: nil)
    }
    
    
    public func deleteStep() {
        deleteStepUseCase?.executeDeletePoi(id: self.place.id, completion: nil)
    }
    
    public func changeWithAlternative() {
        guard let parent = parentStep else {
            print("[Error] Parent step is nil")
            return
        }
        
        replaceWithAlternativeUseCase?.execureEditStep(id: parent.id, poiId: place.id, completion: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        removeObservers()
    }
    
}

//MARK: - Observers
extension PlaceDetailViewModel1: ObserverProtocol {
    
    func addObservers() {
        
        tripModelUseCases?.dailyPlan.addObserver(self, observer: { [weak self] plan in
            let isExistInPlan = plan.steps.contains(where: {$0.poi.id == self?.place.id})
            self?.isAddOnPlane = isExistInPlan
        })
        
        observeFavoriteUseCase?.values.addObserver(self, observer: { [weak self] (favorites) in
            guard let strongSelf = self else {return}
            let placeId = strongSelf.place.id
            let ids = favorites.map{$0.poiId}
            self?.isFavorite = ids.contains(placeId)
        })
        
        observeReservationUseCase?.reservations.addObserver(self, observer: { [weak self] reservations in
            self?.userReservations = reservations
        })
    }
    
    func removeObservers() {
        tripModelUseCases?.dailyPlan.removeObserver(self)
        observeFavoriteUseCase?.values.removeObserver(self)
        observeReservationUseCase?.reservations.removeObserver(self)
    }
    
}

//MARK: - Reservation Logic
extension PlaceDetailViewModel1 {
    
    public func checkMyBookigStatus(bookingId: Int) {
        if let bookingModel = userReservations.first(where: {$0.id == bookingId}), let yelpModel = bookingModel.yelpModel {
            checkBooking(yelpReservationId: yelpModel.reservationID, tripianReservationId: bookingId)
        }
    }
    
    public func isAvaliableInReservation() -> Bool {
        //todo:- Yelp mi yoksa başka servismi diye kontrol edilecek.
        return userReservations.contains(where: {$0.poiID == place.id})
    }
    
    public func reservationCancellUrl() -> URL? {
        if let reservationModel = userReservations.first(where: {$0.poiID == place.id}), let confirmUrl = reservationModel.yelpModel?.confirmURL{
            return URL(string: confirmUrl)
        }
        return nil
    }
    
    public func getReservation() -> TRPReservation?{
        return userReservations.first(where: {$0.poiID == place.id})
    }
    
    private func checkBooking(yelpReservationId id: String, tripianReservationId: Int) {
        YelpApi(isProduct: false).reservationStatus(reservationId: id) { [weak self] (result) in
            switch(result) {
            case .success(let model):
                print("[INFO] CheckBooking \(model)")
            case .failure(let error):
                if let converted = error as? YelpNetworkError, converted == YelpNetworkError.reservationCanceled {
                    self?.deleteBookingInServer(bookingId: tripianReservationId)
                }
                
                print("[Error] CheckBookingError \(error.localizedDescription)")
            }
        }
    }
    
    private func deleteBookingInServer(bookingId id: Int) {
        deleteReservationUseCase?.executeDeleteReservation(id: id, completion: nil)
    }
    
}

//MARK: - Services
extension PlaceDetailViewModel1 {
    
    private func checkUserLocation() {
        userLocationController.isUserInCity {[weak self] (_, isUserInCity, location) in
            guard let strongSelf = self else {return}
            if isUserInCity == .inCity {
                strongSelf.showNavigationButton = true
            }
        }
    }
}

//MARK: Favorite
extension PlaceDetailViewModel1 {
    
    public func setFavorite(_ status: Bool ){
        if status {
            addFavoriteUseCase?.executeAddFavorite(place.id, completion: { [weak self] result in
                if case .success(_) = result {
                    self?.delegate?.viewModel(favoriteUpdated: true, isFavorite: true)
                }
            })
        }else {
            deleteFavoriteUseCase?.executeDeleteFavorite(place.id, completion: { [weak self] result in
                if case .success(_) = result {
                    self?.delegate?.viewModel(favoriteUpdated: true, isFavorite: false)
                }
            })
        }
    }
}

//MARK: Report a problem
extension PlaceDetailViewModel1 {
    
    func fetchProblemCategory() {
        delegate?.viewModel(showPreloader: true)
        ProblemCategoriesHolder.shared.categories {[weak self] (data, error) in
            guard let strongSelf = self else {return}
            strongSelf.delegate?.viewModel(showPreloader: false)
            if let error = error {
                strongSelf.delegate?.viewModel(error: error)
                return
            }
            if let data = data {
                strongSelf.delegate?.viewModel(problemCategory: data)
            }
        }
    }
    
    func reportAProblem(categoryName name: String,
                        message msg:String?,
                        poiId: String,
                        completed: @escaping (_ result: Bool) -> Void) {
        TRPRestKit().reportaProblem(category: name, message: msg, poiId: poiId) {[weak self] (result, error) in
            guard let strongSelf = self else { return }
            if let error = error {
                strongSelf.delegate?.viewModel(error: error)
                return
            }
            
            if let _ = result as? TRPReportAProblemInfoModel {
                completed(true)
            }else {
                completed(false)
            }
        }
    }
}
