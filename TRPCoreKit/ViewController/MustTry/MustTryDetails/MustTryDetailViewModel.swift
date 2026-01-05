//
//  MustTryDetailViewModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 9.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import CoreLocation
import TRPFoundationKit
import TRPRestKit

enum MustTryCellType {
    case poi, description, whereToTrys
}

public struct MustTryCellModel {
    var type: MustTryCellType
    var data: Any
}

public protocol MustTryDetailViewModelDelegate:ViewModelDelegate {

}

public final class MustTryDetailViewModel: TableViewViewModelProtocol {
    
    public typealias T = MustTryCellModel
    public weak var delegate: MustTryDetailViewModelDelegate?
    public var cellViewModels: [MustTryCellModel] = [] {
        didSet {
            delegate?.viewModel(dataLoaded: true)
        }
    }
    
    public var numberOfCells: Int { return cellViewModels.count }
    private(set) var taste: TRPTaste
    private(set) var userLocation: TRPLocation? = nil
    private(set) var userInCity: TRPUserLocationController.UserStatus = .inCity
    private(set) var trip: TRPTrip? {
        didSet {
            if trip != nil {
                delegate?.viewModel(dataLoaded: true)
            }
        }
    }
    
    
    // USE CASE
    public var fetchTastePoisUseCase: FetchPoiWithMustTries?
    public var tripModelUseCase: ObserveTripModeUseCase?
    
    public init(taste: TRPTaste) {
        self.taste = taste
    }
    
    
    public func start() {
        
        TRPUserLocationController.shared.isUserInCity { [weak self] (_, status, userLocation) in
            guard let strongSelf = self else {return}
            strongSelf.userInCity = status
            strongSelf.userLocation = userLocation
        }
        
        cellViewModels.append(MustTryCellModel(type: .description, data: taste.description ?? ""))
        addObservers()
        delegate?.viewModel(showPreloader: true)
        fetchTastePoisUseCase?.executeFetchPoiWithMustTries(ids: [taste.id], completion: { [weak self] result, pagination in
            self?.delegate?.viewModel(showPreloader: false)
            switch result {
            case .success(let pois):
                let convertedPoi = pois.map{ MustTryCellModel(type: .poi, data: $0)}
                if !convertedPoi.isEmpty { self?.addWhereToTry()}
                self?.cellViewModels.append(contentsOf: convertedPoi)
            case .failure(let error):
                self?.delegate?.viewModel(error: error)
            }
        })
    }
    
    private func addWhereToTry() {
        cellViewModels.append(MustTryCellModel(type: .whereToTrys, data: "Where to Try"))
    }
    
    public func getCellViewModel(at indexPath: IndexPath) -> MustTryCellModel {
        cellViewModels[indexPath.row]
    }
    
    
    public func getPlaceImage(indexPath:IndexPath) -> URL? {
        
        guard let poi = cellViewModels[indexPath.row].data as? TRPPoi else { return nil }
        
        let mUrl = poi.image?.url
        guard let link = TRPImageResizer.generate(withUrl: mUrl, standart: .small) else {
            return nil
        }
        if let url = URL(string: link) {
            return url
        }
        return nil
    }
    
    public func getHeaderImage() -> URL? {
        
        guard let imageUrl = taste.image?.url,
              let link = TRPImageResizer.generate(withUrl: imageUrl, standart: .placeDetail) else {
            return nil
        }
        return URL(string: link)
    }
    
    public func getDistanceFromUserLocation(toPoiLat lat: Double, toPoiLon lon: Double) -> Double? {
        guard let user = userLocation else {return nil}
        return CLLocation(latitude: user.lat, longitude: user.lon).distance(from: CLLocation(latitude: lat, longitude: lon))
    }
    
    public func getExplainText(placeId: String) -> NSAttributedString? {
        let match = getPoiScore(poiId: placeId)
        let partOfDay = getPartOfDay(placeId: placeId)
        return PartOfDayMatch.createExplaineText(partOfDay: partOfDay, matchRate: match)
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
    
    deinit {
        removeObservers()
    }
}

extension MustTryDetailViewModel: ObserverProtocol {
    
    func addObservers() {
        tripModelUseCase?.trip.addObserver(self, observer: { [weak self] trip in
            self?.trip = trip
        })
    }
    
    func removeObservers() {
        tripModelUseCase?.trip.removeObserver(self)
    }
    
}
