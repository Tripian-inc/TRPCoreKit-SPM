//
//  PoiDetailViewModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 22.10.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPDataLayer
import TRPUIKit
import TRPRestKit
import TRPProvider
import TRPFoundationKit
import CoreLocation
import MapKit

enum PoiDetailCellType {
    case titleAndAction,
         openCloseHour,
         description,
         web,
         phone,
         address,
         features,
         makeAReservation,
         cuisines,
         map,
         mustTries,
         tag,
         actions,
         galleryTitle,
         gygTours,
         safety,
         yelp,
         openTable,
         offer
}

struct PoiDetailBasicCellModel {
    var icon: String
    var content: String
}

struct PoiDetailCellContent {
    var data: Any?
    var type: PoiDetailCellType
}

struct PoiDetailActions {
    var addRemoveButtonStatus: AddRemovePoiStatus
    var canNavigation: Bool
    var isFavorite: Bool
}

struct PoiImageWithTitleModel {
    var gallery: [PagingImage]
    var title: String
    var sdkModeType: SdkModeType
    var globalRating: Bool
    var starCount: Int
    var reviewCount: Int
    var price: Int
    var explainText: NSAttributedString?
}


protocol PoiDetailViewModelDelegate: ViewModelDelegate {
    func viewModel(favoriteUpdated: Bool, isFavorite:Bool)
    func openSelectDateForOffer(start: Date, end: Date, offerId: Int)
}


final class PoiDetailViewModel: TableViewViewModelProtocol {
    
    
    typealias T = PoiDetailCellContent
    
    private var userLocationController: TRPUserLocationController
    private var parentStep: TRPStep?
    private(set) var userLocation: TRPLocation? = nil
    private(set) var userInCity: TRPUserLocationController.UserStatus = .inCity
    public var place: TRPPoi
    public weak var delegate: PoiDetailViewModelDelegate?
    public var numberOfCells: Int { return cellViewModels.count }
    public var cellViewModels: [PoiDetailCellContent] = [] {
        didSet {
            delegate?.viewModel(dataLoaded: true)
        }
    }
    private var isFavorite: Bool = false {
        didSet {
            updateActionCell()
        }
    }
    private var isAddOnPlane: Bool = false {
        didSet {
            updateActionCell()
        }
    }
    private var userReservations  = [TRPReservation]() {
        didSet {
            updateYelpCell()
        }
    }
    
    public var destinationId: Int
    public var cityEngName: String
    
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
    
    public var addOptInOfferUseCase: AddOptInOfferUseCase?
    public var deleteOptInOfferUseCase: DeleteOptInOfferUseCase?
    public var observeOptInOfferUseCase: ObserveOptInOfferUseCase?
    public var fetchOptInOfferUseCase: FetchOptInOfferUseCase?
    
    public init(place: TRPPoi,
                parentStep: TRPStep? = nil,
                userLocationController: TRPUserLocationController = .shared,
                destinationId: Int,
                cityEngName: String
    ) {
        self.userLocationController = userLocationController
        self.parentStep = parentStep
        self.place = place
        self.destinationId = destinationId
        self.cityEngName = cityEngName
    }
    
    public func start() {
        TRPUserLocationController.shared.isUserInCity { [weak self] (_, status, userLocation) in
            guard let strongSelf = self else {return}
            strongSelf.userInCity = status
            strongSelf.userLocation = userLocation
        }
        addObservers()
        createCellData()
    }
    
    func getCellViewModel(at indexPath: IndexPath) -> PoiDetailCellContent {
        return cellViewModels[indexPath.row]
    }
    
    public func getImageGallery() -> [PagingImage] {
        return place.gallery.compactMap { image -> PagingImage? in
            guard let converted = self.getPlaceImage(url: image.url) else {return nil}
            return PagingImage(imageUrl: converted, picOwner: image.imageOwner)
        }
    }
    
    public func getPlaceImage(url: String) -> String? {
        return TRPImageResizer.generate(withUrl: url, standart: .placeDetail)
        
    }
    
    public func getSharedPoiUrl() -> URL? {
        let url = URL(string: TRPAppearanceSettings.PoiDetail.sharedPoiUrl + "\(place.id)")
        return url
    }
    
    public func getBookingModel(withId id: Int) -> TRPBooking? {
        guard let booking = place.bookings else {return nil}
        return booking.first(where: {$0.providerId == id})
    }
    
    public func getOpenTableUrl() -> URL? {
        let booking = getBooking(providerId: 5)
        if let openTable = booking.first, let url = openTable.url {
            return URL(string: url)
        }
        return nil
    }
    
    private func updateViews() {
        createCellData()
    }
    
    private func updateActionCell() {
        let actions = PoiDetailActions(addRemoveButtonStatus: getAddRemoveButtonStatus(),
                                       canNavigation: false,
                                       isFavorite: isFavorite)
        let actionModel = PoiDetailCellContent(data: actions, type: .actions)
        
        if let index = cellViewModels.firstIndex(where: {$0.type == .actions}) {
            cellViewModels[index] = actionModel
        }
    }
    
    private func updateYelpCell() {
        let yelp = getBooking(providerId: 2)
        if !yelp.isEmpty {
            let isReserved = isAvaliableInReservation()
            let explaineText = isReserved ? TRPLanguagesController.shared.getLanguageValue(for: "cancel_reservation") : TRPLanguagesController.shared.getLanguageValue(for: "make_reservation")
            let cellModel = PoiDetailCellContent(data: explaineText, type: .yelp)
            
            if let index = cellViewModels.firstIndex(where: {$0.type == .yelp}) {
                cellViewModels[index] = cellModel
            }
        }
    }
    
    private func getMustTryText() -> String?{
        guard place.mustTries.count > 0 else {return nil}
        guard let cityName = tripModelUseCases?.trip.value?.city.name else {return nil}
        return "\(TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.itinerary.step.poi.mustTry.message")) \(place.mustTries.compactMap({$0.name}).toString(", ")) in \(cityName)"
    }
    
    public func checkUserIsInCity() -> TRPUserLocationController.UserStatus {
        return userInCity
    }
    
    public func isParentAvailabile() -> Bool {
        return parentStep != nil
    }
    
}


//MARK: - ACTIONS
extension PoiDetailViewModel {
    
    public func addRemoveButtonPressed() {
        if let parent = parentStep {
            replaceWithAlternativeUseCase?.execureEditStep(id: parent.id, poiId: place.id, completion: nil)
            return
        }
        
        delegate?.viewModel(showPreloader: true)
        
        if isAddOnPlane {
            deleteStepUseCase?.executeDeletePoi(id: self.place.id, completion: {[weak self] (result) in
                if case .failure(let error) = result {
                    self?.delegate?.viewModel(showPreloader: false)
                    self?.delegate?.viewModel(error: error)
                }
            })
        }else {
            addStepUseCase?.executeAddStep(poiId: self.place.id, completion: {[weak self] (result) in
                if case .failure(let error) = result {
                    self?.delegate?.viewModel(showPreloader: false)
                    self?.delegate?.viewModel(error: error)
                }
            })
        }
    }
    
    public func favoriteButtonPressed() {
        delegate?.viewModel(showPreloader: true)
        if isFavorite {
            deleteFavoriteUseCase?.executeDeleteFavorite(place.id, completion: { [weak self] result in
                self?.delegate?.viewModel(showPreloader: false)
                switch result {
                case .success(_):
                    self?.delegate?.viewModel(favoriteUpdated: true, isFavorite: false)
                case .failure(let error):
                    self?.delegate?.viewModel(error: error)
                }
                
            })
        }else {
            addFavoriteUseCase?.executeAddFavorite(place.id, completion: { [weak self] result in
                self?.delegate?.viewModel(showPreloader: false)
                switch result {
                case .success(_):
                    self?.delegate?.viewModel(favoriteUpdated: true, isFavorite: true)
                case .failure(let error):
                    self?.delegate?.viewModel(error: error)
                }
                
            })
            
        }
    }
    
    public func navigateToPoi() {
        
        
        if UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!){
            let url = "comgooglemaps://?daddr=\(place.coordinate.lat),\(place.coordinate.lon)&directionsmode=driving&zoom=14&views=traffic"
            if let mapsUrl = URL(string: url) {
                UIApplication.shared.open(mapsUrl, options: [:])
            }
        } else {
            let latitude: CLLocationDegrees = place.coordinate.lat
            let longitude: CLLocationDegrees = place.coordinate.lon
            let regionDistance:CLLocationDistance = 10000
            let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
            let regionSpan = MKCoordinateRegion(center: coordinates, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
            let options = [
                MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
                MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
            ]
            let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = place.name
            mapItem.openInMaps(launchOptions: options)
        }
    }
    
}

//MARK: - PREPARE DATA
extension PoiDetailViewModel {
    
    private func createCellData() {
        
        var tempCells = [PoiDetailCellContent]()
        
        let gallery = place.gallery.map({PagingImage(imageUrl: $0.url, picOwner: $0.imageOwner)})
        
        //Title
        let titleCell = PoiImageWithTitleModel(gallery: gallery,
                                               title: place.name,
                                               sdkModeType: .Trip,
                                               globalRating: showRating(),
                                               starCount: starCount(),
                                               reviewCount: place.ratingCount ?? 0,
                                               price: place.price ?? 0,
                                               explainText: dayAndMatchExplainText)
        
        let titleCellModel = PoiDetailCellContent(data: titleCell, type: .galleryTitle)
        tempCells.append(titleCellModel)
        
        let actions = PoiDetailActions(addRemoveButtonStatus: getAddRemoveButtonStatus(),
                                       canNavigation: false,
                                       isFavorite: isFavorite)
        let actionModel = PoiDetailCellContent(data: actions, type: .actions)
        tempCells.append(actionModel)
        
        if !place.safety.isEmpty {
            let safetyText = place.safety.map({$0.capitalized})
            let data = PoiDetailBasicCellModel(icon: "icon_mask", content: safetyText.toString("\n"))
            let cellModel = PoiDetailCellContent(data: data, type: .safety)
            tempCells.append(cellModel)
        }
        
        if let des = place.description {
            let data = PoiDetailBasicCellModel(icon: "icon_attraction", content: des)
            let cellModel = PoiDetailCellContent(data: data, type: .description)
            tempCells.append(cellModel)
        }
        
        if let mustTry = getMustTryText() {
            let data = PoiDetailBasicCellModel(icon: "icon_kitchen", content: mustTry)
            let cellModel = PoiDetailCellContent(data: data, type: .mustTries)
            tempCells.append(cellModel)
        }
        
        if let cuisines = place.cuisines, !cuisines.isEmpty {
            let data = PoiDetailBasicCellModel(icon: "icon_kitchen", content: cuisines)
            let cellModel = PoiDetailCellContent(data: data, type: .tag)
            tempCells.append(cellModel)
        }
        
        if let hours = place.hours, !hours.isEmpty {
            let data = PoiDetailBasicCellModel(icon: "icon_clock", content: hours)
            let cellModel = PoiDetailCellContent(data: data, type: .openCloseHour)
            tempCells.append(cellModel)
        }
        
        if !place.tags.isEmpty {
            let data = PoiDetailBasicCellModel(icon: "icon_tag", content: place.tags.toString(", "))
            let cellModel = PoiDetailCellContent(data: data, type: .tag)
            tempCells.append(cellModel)
        }
        
        if let web = place.webUrl {
            let data = PoiDetailBasicCellModel(icon: "icon_web", content: web)
            let cellModel = PoiDetailCellContent(data: data, type: .web)
            tempCells.append(cellModel)
        }
        
        if let phone = place.phone {
            let data = PoiDetailBasicCellModel(icon: "icon_phone", content: phone)
            let cellModel = PoiDetailCellContent(data: data, type: .phone)
            tempCells.append(cellModel)
        }
        
        if let address = place.address {
            let data = PoiDetailBasicCellModel(icon: "icon_location", content: address)
            let cellModel = PoiDetailCellContent(data: data, type: .address)
            tempCells.append(cellModel)
        }
        
        ///Offer cells
        if !place.offers.isEmpty {
            place.offers.forEach { poiOffer in
                let data = PoiOfferCellModel(offer: poiOffer)
                let cellModel = PoiDetailCellContent(data: data, type: .offer)
                tempCells.append(cellModel)
            }
        }
        
        let yelp = getBooking(providerId: 2) //Yelp
        if !yelp.isEmpty {
            let isReserved = isAvaliableInReservation()
            let explaineText = isReserved ? TRPLanguagesController.shared.getLanguageValue(for: "cancel_reservation") : TRPLanguagesController.shared.getLanguageValue(for: "make_reservation")
            let cellModel = PoiDetailCellContent(data: explaineText, type: .yelp)
            tempCells.append(cellModel)
        }
        
        //TODO: - RESTAURANTLAR İÇİN EKLENDİ. SİLİNECEK
        
//        if place.categories.contains(where: {$0.id == 3}) {
//            let isReserved = isAvaliableInReservation()
//            let explaineText = isReserved ? "Cancel Your Reservation" : "Make a Reservation"
//            let cellModel = PoiDetailCellContent(data: explaineText, type: .yelp)
//            tempCells.append(cellModel)
//        }
        
        let openTable = getBooking(providerId: 5) // opentable
        if yelp.isEmpty && !openTable.isEmpty {
            let explaineText = TRPLanguagesController.shared.getLanguageValue(for: "make_reservation")
            let cellModel = PoiDetailCellContent(data: explaineText, type: .openTable)
            tempCells.append(cellModel)
        }
        
        let mapModel = PoiDetailCellContent(data: place.coordinate, type: .map)
        tempCells.append(mapModel)
        
//        let gyg = getBooking(providerId: 4)
//        if  !gyg.isEmpty {
//            let cellModel = PoiDetailCellContent(data: gyg, type: .gygTours)
//            tempCells.append(cellModel)
//        }
        
        let juniper = getBooking(providerId: 7)
        if  !juniper.isEmpty {
            let cellModel = PoiDetailCellContent(data: juniper, type: .gygTours)
            tempCells.append(cellModel)
        }
        
        
        cellViewModels = tempCells
    }
    
    
    private func getBooking(providerId id: Int) -> [TRPBookingProduct]{
        guard let bookings = place.bookings else {return []}
        let data = bookings.filter{$0.providerId == id}
        return data.first?.products ?? []
    }
    
    
    private func getAddRemoveButtonStatus() -> AddRemovePoiStatus {
        if parentStep != nil {
            return .alternative
        }else if isAddOnPlane {
            return .remove
        }else{
            return .add
        }
    }
}

extension PoiDetailViewModel {
    
    private func showRating() -> Bool {
        
        let raitingIsShow = TRPAppearanceSettings.ShowRating.type.contains { (category) -> Bool in
            guard let placeCategoty = place.categories.first else {return false}
            if category.getId() == placeCategoty.id {
                return true
            }
            return false
        }
        return raitingIsShow && place.ratingCount != 0
    }
    
    private func starCount() -> Int {
        guard let rating = place.rating else {return 0}
        return Int(rating.rounded())
    }
    
    private var dayAndMatchExplainText: NSMutableAttributedString {
        guard let trip = tripModelUseCases?.trip.value else { return NSMutableAttributedString() }
        let partOfDay = trip.getPartOfDay(placeId: place.id)
        let matchValue = trip.getPoiScore(poiId: place.id)
        let match: Int? = matchValue != nil ? Int(matchValue!) : nil
        return PartOfDayMatch.createExplaineText(partOfDay: partOfDay, matchRate: match)
    }
}

//MARK: - RESERVATION LOGIC
extension PoiDetailViewModel {
    
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
    
    @objc func applicationWillEnterForeground(_ notification: NSNotification) {
        if !isAvaliableInReservation() {return}
        if let reservation = getReservation() {
            checkMyBookigStatus(bookingId: reservation.id)
        }
    }
    
}

//MARK: - Observers
extension PoiDetailViewModel: ObserverProtocol {
    
    func addObservers() {
        
        tripModelUseCases?.dailyPlan.addObserver(self, observer: { [weak self] plan in
            let isExistInPlan = plan.steps.contains(where: {$0.poi.id == self?.place.id})
            self?.isAddOnPlane = isExistInPlan
            self?.updateViews()
            self?.delegate?.viewModel(showPreloader: false)
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
        
        observeOptInOfferUseCase?.values.addObserver(self, observer: { [weak self] optInOffers in
            let optInOfferIds = optInOffers.map { $0.id}
            self?.place.offers.indices.forEach {
                if let offer = self?.place.offers[$0] {
                    self?.place.offers[$0].optIn = optInOfferIds.contains(offer.id)
                }
            }
            self?.updateViews()
        })
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    func removeObservers() {
        tripModelUseCases?.dailyPlan.removeObserver(self)
        observeFavoriteUseCase?.values.removeObserver(self)
        observeReservationUseCase?.reservations.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }
    
}

//MARK: - Offers
extension PoiDetailViewModel {
    public func offerToggle(_ model: PoiOfferCellModel) {
        if !model.optIn {
            offerAccept(model)
        } else {
            deleteMyOffer(offerId: model.offerId)
        }
    }
    
    private func offerAccept(_ model: PoiOfferCellModel) {
        guard !model.optIn else {return}
        
        if let startDate = model.startDate, let endDate = model.endDate {
            let diff = Calendar.current.dateComponents([.day], from: startDate, to: endDate)
            if diff.day == 0 {
                let stringDate = startDate.toStringWithoutTimeZone(format: "yyyy-MM-dd", dateStyle: nil, timeStyle: nil)
                addMyOffer(offerId: model.offerId, date: stringDate)
            }else {
                delegate?.openSelectDateForOffer(start: startDate, end: endDate, offerId: model.offerId)
            }
        }

    }
    
    func addMyOffer(offerId: Int, date: String) {
        delegate?.viewModel(showPreloader: true)
        addOptInOfferUseCase?.executeAddOptInOffer(id: offerId, claimDate: date) { [weak self] result in
            switch result {
            case .success(_):
                self?.fetchOptInOffers()
            case .failure(let error):
                self?.delegate?.viewModel(showPreloader: false)
                self?.delegate?.viewModel(error: error)
            }
        }
    }
    
    private func deleteMyOffer(offerId: Int) {
        delegate?.viewModel(showPreloader: true)
        deleteOptInOfferUseCase?.executeDeleteOptInOffer(id: offerId) { [weak self] result in
            switch result {
            case .success(_):
                self?.fetchOptInOffers()
            case .failure(let error):
                self?.delegate?.viewModel(showPreloader: false)
                self?.delegate?.viewModel(error: error)
            }
        }
    }
    
    private func fetchOptInOffers() {
        delegate?.viewModel(showPreloader: true)
        fetchOptInOfferUseCase?.executeOptInOffers(dateFrom: nil, dateTo: nil) { [weak self] result in
            self?.delegate?.viewModel(showPreloader: false)
            if case .failure(let error) = result {
                self?.delegate?.viewModel(error: error)
            }
        }
    }
}
