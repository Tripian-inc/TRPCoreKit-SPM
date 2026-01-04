//
//  FavoritesViewModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 3.10.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit




public protocol FavoritesVMDelegate: ViewModelDelegate {
    
}

public class FavoritesViewModel: TableViewViewModelProtocol {
    
    public typealias T = TRPPoi
    
    public var cellViewModels: [TRPPoi] = [] {
        didSet {
            DispatchQueue.main.async {
                self.delegate?.viewModel(dataLoaded: true)
            }
        }
    }
    
    public var numberOfCells: Int {
        return cellViewModels.count
    }
    
    weak var delegate: FavoritesVMDelegate?
    
    private var cityId: Int
    private var isFetched: Bool = false
    
    //USE CASE
    public var observeFavoriteUseCase: ObserveFavoritesUseCase?
    public var fetchPoiWithIdUseCase: FetchPoiUseCase?
    
    
    
    init(cityId: Int) {
        self.cityId = cityId
    }
    
    public func start() {
        addObservers()
    }
    
    private func fetchPoi(ids: [String]) {
        fetchPoiWithIdUseCase?.executeFetchPoi(ids: ids, completion: { [weak self] result, pagination in
            guard let strongSelf = self else {return}
            switch result {
            case .success(let pois):
                strongSelf.cellViewModels = strongSelf.filterPoisStatus(pois)
            case .failure(let error):
                strongSelf.delegate?.viewModel(error: error)
            }
        })
    }
    
    private func filterPoisStatus(_ pois: [TRPPoi]) -> [TRPPoi] {
        return pois.filter({$0.status == true})
    }
    
    public func getCellViewModel(at indexPath: IndexPath) -> TRPPoi {
        return cellViewModels[indexPath.row]
    }
    
    public func getImageUrl(at indexPath: IndexPath, width: Int, height: Int) -> URL? {
        guard let link = TRPImageResizer.generate(withUrl: getCellViewModel(at: indexPath).image?.url, standart: .small), let url = URL(string: link) else {
            return nil
        }
        return url
    }
    
    
    deinit {
        removeObservers()
    }
    
}

extension FavoritesViewModel: ObserverProtocol {
    
    func addObservers() {
        observeFavoriteUseCase?.values.addObserver(self, observer: { [weak self] favorites in
            guard let strongSelf = self else {return}
            let poiIds = favorites.map{$0.poiId}
            strongSelf.fetchPoi(ids: poiIds)
        })
    }
    
    func removeObservers() {
        observeFavoriteUseCase?.values.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }
    
}
