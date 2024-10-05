//
//  PoiSearchVM.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 15.02.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation

import CoreLocation



struct PoiWithLocation {
    var poi: TRPPoi
    var distance: Double?
}


class PoiSearchVM {
    
    private let city: TRPCity
    private var pois: [PoiWithLocation] = [] {
        didSet {
            DispatchQueue.main.async {
                self.delegate?.viewModel(dataLoaded: true)
            }
        }
    }
    private var lastSearch : [PoiLastSearchModel] = []
    private var nextPageLink: String = ""
    
    public weak var delegate: ViewModelDelegate?
    public var isUserInCity: Bool = false
    public var userLocation: TRPLocation?
    public var showLastSearch: Bool = true {
        didSet {
            DispatchQueue.main.async {
                self.delegate?.viewModel(dataLoaded: true)
            }
        }
    }
    
    public var categoryType: AddPlaceTypes?
    // UseCase
    public var searchPoiUseCases: SearchPoiUseCase?
    public var fetchLastSearchUseCase: FetchLastSearchUseCase?
    public var addLastSearchUseCase: AddLastSearchUseCase?
    public var deleteLastSearchUseCase: DeleteLastSearchUseCase?
    public var observeLastSearchUseCase: ObserveLastSearchUseCase?
    
    
    init(city: TRPCity) {
        self.city = city
        TRPUserLocationController.shared.isUserInCity { [weak self] (cityId, status, location) in
            guard let strongSelf = self else {return}
            if status == .inCity {
                strongSelf.isUserInCity = true
            }else {
                strongSelf.isUserInCity = false
            }
            strongSelf.userLocation = location
        }
        
    }
     
    
    public func start() {
        addObservers()
        fetchLastSearchUseCase?.executeFetchSearch(completion: nil)
    }
    
    
    public func search(text: String, scope: ScopeButton) {
        
        addLastSearchUseCase?.executeAddSearch(text: text)
        
        guard let ne = city.boundaryNorthEast, let sw = city.boundarySouthWest else {return}
    
        var poiCategories = [Int]()
        
        if let type = categoryType {
            poiCategories.append(type.id)
            poiCategories.append(contentsOf: type.subTypes)
        }
        
        
        if scope == .nearBy {
            if let userLocation = userLocation, isUserInCity {
                delegate?.viewModel(showPreloader: true)
                searchPoiUseCases?.executeSearchPoi(text: text,
                                                    categoies: poiCategories,
                                                    userLocation: userLocation,
                                                    completion: poiSearchUseCaseResult(result:pagination:))
            }else {
                
                print("SEN BU ŞEHİRDE DEĞİLSİN")
            }
        }else if scope == .recommended {
            delegate?.viewModel(showPreloader: true)
            
            searchPoiUseCases?.executeSearchPoi(text: text,
                                                categoies: poiCategories,
                                                boundaryNorthEast: ne,
                                                boundarySouthWest: sw,
                                                completion: poiSearchUseCaseResult(result:pagination:))
        }
  
    }
    
    private func poiSearchUseCaseResult(result: Result<[TRPPoi], Error>, pagination: TRPPagination?) {
        self.delegate?.viewModel(showPreloader: false)
        
        if let pagination = pagination, case .continues(let link) = pagination {
            self.nextPageLink = link
        }
        
        switch result {
        case .success(let models):
            self.pois = models.map({ (place) -> PoiWithLocation in
                return self.placeToLocationModel(place)
            })
        case .failure(let error):
            self.delegate?.viewModel(error: error)
        }
    }
    
    func placeToLocationModel(_ place: TRPPoi) -> PoiWithLocation {
        guard let userLocation = userLocation else  {
            return PoiWithLocation(poi: place, distance: nil)
        }
        if isUserInCity {
            let distance = CLLocation(latitude: place.coordinate.lat, longitude: place.coordinate.lon).distance(from: CLLocation(latitude: userLocation.lat, longitude: userLocation.lon))
            return PoiWithLocation(poi: place, distance: distance)
        }
        return PoiWithLocation(poi: place, distance: nil)
    }
    
    public var numberOfCells: Int {
        return showLastSearch ? lastSearch.count : pois.count
    }
    
    public func getPoi(indexPath: IndexPath) -> PoiWithLocation? {
        if pois.count > indexPath.row {
            return pois[indexPath.row]
        }
        return nil
    }
    
    public func getLastSearch(indexPath: IndexPath) -> PoiLastSearchModel? {
        return lastSearch[indexPath.row]
    }
    
    public func loadNextPage() {
        if nextPageLink.count < 5 {return}
        preLoader(show: true)
    }
    
    fileprivate func preLoader(show:Bool) {
        DispatchQueue.main.async {
            self.delegate?.viewModel(showPreloader: false)
        }
    }
    
    public func clearResult() {
        pois.removeAll()
    }
    
    deinit {
        removeObservers()
    }
    
}

extension PoiSearchVM: ObserverProtocol {
    
    func addObservers() {
        observeLastSearchUseCase?.values.addObserver(self, observer: { [weak self] result in
            self?.lastSearch = result.map({PoiLastSearchModel(title: $0, image: "search_black")}).reversed()
        })
    }
    
    func removeObservers() {
        observeLastSearchUseCase?.values.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }
    
}
