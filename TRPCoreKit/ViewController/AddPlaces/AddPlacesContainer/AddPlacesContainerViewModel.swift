//
//  AddPlacesContainerViewModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 10.08.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation
import CoreLocation
import TRPFoundationKit
import TRPRestKit

public class AddPlacesContainerViewModel {
    
    
    var displayedPoi: [TRPPoi] = [] {
        didSet {
            self.delegate?.viewModel(dataLoaded: true)
        }
    }
    
    weak var delegate: ViewModelDelegate?
    
    
    private(set) var userLocation: TRPLocation? = nil
    private var userInCity: TRPUserLocationController.UserStatus = .inCity
    private var city: TRPCity!
    
    private var isSearching: Bool = false
    
    var isNotFiltered: Bool = false
    
    var selectedCategories: [TRPPoiCategory] = [] {
        didSet {
            if !selectedCategories.isEmpty {
                fetchData()
                editPoiInTrip()
            }
        }
    }
    
    public func getSelectedCategories() -> [TRPPoiCategory] {
        if isNotFiltered {
            return []
        }
        return selectedCategories
    }
    
    private func editPoiInTrip() {
        guard let trip = self.trip else { return }
        let categories: [Int] = selectedCategories.compactMap {$0.id}
        self.poiInTrip = trip.getPoisWith(types: categories)
    }
    
    //NEW
    private(set) var trip: TRPTrip? {
        didSet {
            editPoiInTrip()
        }
    }
    
    private(set) var poiInTrip: [TRPPoi] = [] {
        didSet {
            updateDisplayedPois()
        }
    }
    
    private(set) var poiInAlternative: [TRPPoi] = [] {
        didSet {
            updateDisplayedPois()
        }
    }
    
    private(set) var poiFromServer: [TRPPoi] = [] {
        didSet {
            updateDisplayedPois()
        }
    }
    
    public var isDataFetched = false
    
    public var tripModelObserverUseCase: ObserveTripModeUseCase?
    public var fetchCategoryPoiUseCase: FethCategoryPoisUseCase?
    public var fetchNearByPoiUseCase: FetchNearByPoiUseCase?
    public var searchPoiUseCase: SearchPoiUseCase?
    public var nextUrlPoiUseCase: FetchPoiNextUrlUseCase?
    public var tripModelUseCase: ObserveTripModeUseCase?
    public var fetchAlternativeUseCase: FetchAlternativeWithCategory?
    
    func start() {
        //TODO: - Interacterda location versi var, onu test et ve bunu sil
        TRPUserLocationController.shared.isUserInCity { [weak self] (_, status, userLocation) in
            guard let strongSelf = self else {return}
            strongSelf.userInCity = status
            strongSelf.userLocation = userLocation
        }
        addObservers()
        fetchAlternativePoi()
//        fetchData()
    }
    
    public func searchText(_ text: String) {
        isSearching = !text.isEmpty
        fetchSearchPoi(text: text)
    }
    
    public func cancelSearch() {
        isSearching = false
        fetchData()
    }
    
    public func getExplainText(placeId: String) -> NSAttributedString? {
        let match = getPoiScore(poiId: placeId)
        let partOfDay = getPartOfDay(placeId: placeId)
        return PartOfDayMatch.createExplaineText(partOfDay: partOfDay, matchRate: match)
    }
    
    public func getPlaceCount() -> Int {
        return displayedPoi.count
    }
    
    public func getPlace(index: Int) -> TRPPoi {
        return displayedPoi[index]
    }
    
    public func getTitle(indexPath:IndexPath) -> String {
        return displayedPoi[indexPath.row].name
    }
    
    public func getCity() -> TRPCity? {
        return trip?.city
    }
    
    public func getPartOfDay(placeId: String) -> [Int]? {
        guard let trip = trip else {return nil}
        return trip.getPartOfDay(placeId: placeId)
    }
    
    public func getPoiScore(poiId id: String) -> Int? {
        if let poiScore = trip?.getPoiScore(poiId: id) {
            return Int(poiScore)
        }
        return nil
    }
    
    //50000
    public func getDistanceFromUserLocation(toPoiLat lat: Double, toPoiLon lon: Double) -> Double? {
        guard let user = userLocation else {return nil}
        return CLLocation(latitude: user.lat, longitude: user.lon).distance(from: CLLocation(latitude: lat, longitude: lon))
    }
    
    public func getPlaceImage(indexPath:IndexPath) -> URL? {
        let mUrl = displayedPoi[indexPath.row].image?.url
        guard let link = TRPImageResizer.generate(withUrl: mUrl, standart: .small) else {
            return nil
        }
        if let url = URL(string: link) {
            return url
        }
        return nil
    }
    
    public func isSuggestedByTripian(id: String) -> Bool {
        var status = false
        status = isExistInAlternative(id: id)
        
        guard !status else {return status}
        
        if let score = tripModelObserverUseCase?.trip.value?.getPoiScore(poiId: id), score != 0 {
            status = true
        }
        return status
    }
    
    public func isExistInAlternative(id: String) -> Bool {
        return poiInAlternative.contains(where: {$0.id == id})
    }
    
    private func clearContentData() {
        displayedPoi = []
//        nextPageLink = ""
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        removeObservers()
        Log.deInitialize()
    }
}

//MARK: - Data Manager
extension AddPlacesContainerViewModel {
    
    
    public func fetchData() {
        clearContentData()
        fetchPoiWithCategory();
    }
    
    //Recommendation
    private func fetchPoiWithCategory() {
        delegate?.viewModel(showPreloader: true)
        let typeIds: [Int] = selectedCategories.getIds()
        
        fetchCategoryPoiUseCase?.executeFetchCategoryPois(categoryIds: typeIds, completion: { [weak self] result, pagination in
            self?.delegate?.viewModel(showPreloader: false)
            switch result {
            case .success(let pois):
                self?.poiFromServer = pois
            case .failure(let error):
                self?.delegate?.viewModel(error: error)
            }
        })
    }
    
    //NearBy
    private func fetchPoiNearBy() {
        guard let coordinate = userLocation else {return}
        let typeIds: [Int] = selectedCategories.getIds()
        delegate?.viewModel(showPreloader: true)
        fetchNearByPoiUseCase?.executeFetchNearByPois(location: coordinate,
                                                      categoryIds: typeIds, completion: { [weak self] result, pagination in
                                                        self?.delegate?.viewModel(showPreloader: false)
                                                        
//                                                        if case .continues(let url) = pagination {
//                                                            self?.nextPageLink = url
//                                                        }
                                                        switch result {
                                                        case .success(let pois):
                                                            self?.poiFromServer = pois
                                                        case .failure(let error):
                                                            self?.delegate?.viewModel(error: error)
                                                        }
                                                      })
    }
    
    private func fetchSearchPoi(text: String) {
        
        guard let city = tripModelUseCase?.trip.value?.city else {
            print("[Error] City not found")
            return
        }
        
        let typeIds: [Int] = selectedCategories.getIds()
        
        delegate?.viewModel(showPreloader: true)
        if let userLocation = userLocation, userInCity == .inCity {
            searchPoiUseCase?.executeSearchPoi(text: text,
                                               categoies: typeIds,
                                               userLocation: userLocation,
                                               completion: poiSearchUseCaseResult(result:pagination:))
        } else if let ne = city.boundaryNorthEast, let sw = city.boundarySouthWest {
            searchPoiUseCase?.executeSearchPoi(text: text,
                                               categoies: typeIds,
                                               boundaryNorthEast: ne,
                                               boundarySouthWest: sw,
                                               completion: poiSearchUseCaseResult(result:pagination:))
        }
        
    }
    
    private func poiSearchUseCaseResult(result: Result<[TRPPoi], Error>, pagination: TRPPagination?) {
        self.delegate?.viewModel(showPreloader: false)
        
//        if let pagination = pagination, case .continues(let link) = pagination {
//            self.nextPageLink = link
//        }
        switch result {
        case .success(let pois):
            self.poiFromServer = pois
        case .failure(let error):
            self.delegate?.viewModel(error: error)
        }
    }
    
    private func fetchAlternativePoi() {
        let typeIds: [Int] = selectedCategories.getIds()
        fetchAlternativeUseCase?.executeFetchAlternativeWithCategory(categories: typeIds, completion: {  [weak self] (result, pagination) in
            switch result {
            case .success(let pois):
                self?.poiInAlternative = pois
            case .failure(let error):
                self?.delegate?.viewModel(error: error)
            }
        })
        
    }
    
    private func updateDisplayedPois() {
        if isSearching {
            self.displayedPoi = poiFromServer
            return
        }
        self.displayedPoi = self.mergePoi(self.displayedPoi, self.poiInTrip, poiInAlternative, poiFromServer)
    }
    
    private func mergePoi(_ displayed: [TRPPoi],
                          _ poisInTrip: [TRPPoi],
                          _ alternative: [TRPPoi],
                          _ newPois: [TRPPoi]) -> [TRPPoi] {
        var tempAr = [TRPPoi]()
        tempAr.append(contentsOf: poisInTrip)
        tempAr.append(contentsOf: alternative)
        tempAr.append(contentsOf: newPois)
        return tempAr.unique(by: {$0.id})
    }
    
}


//MARK: - Observers
extension AddPlacesContainerViewModel: ObserverProtocol {
    
    func addObservers() {
        tripModelUseCase?.trip.addObserver(self, observer: { [weak self] trip in
            self?.trip = trip
        })
    }
    
    func removeObservers() {
        tripModelUseCase?.trip.removeObserver(self)
    }
    
}
