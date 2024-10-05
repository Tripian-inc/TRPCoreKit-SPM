//
//  MyOffersViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 13.09.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import TRPRestKit
import TRPDataLayer

public protocol MyOffersVMDelegate: ViewModelDelegate {
    
}

public class MyOffersViewModel: TableViewViewModelProtocol {
    
    public typealias T = PoiOfferCellModel
    
    public var cellViewModels: [PoiOfferCellModel] = [] {
        didSet {
            DispatchQueue.main.async {
                self.delegate?.viewModel(dataLoaded: true)
            }
        }
    }
    
    public var numberOfCells: Int {
        return cellViewModels.count
    }
    
    weak var delegate: MyOffersVMDelegate?
    
    private var optInPois: [TRPPoi] = []
    
    //USE CASE
    public var observeOptInOfferUseCase: ObserveOptInOfferUseCase?
    public var deleteOptInOfferUseCase: DeleteOptInOfferUseCase?
    public var fetchOptInOfferUseCase: FetchOptInOfferUseCase?
      
    
    public func start() {
        addObservers()
    }
    
    public func getCellViewModel(at indexPath: IndexPath) -> PoiOfferCellModel {
        return cellViewModels[indexPath.row]
    }
    
    public func getImageUrl(at indexPath: IndexPath, width: Int, height: Int) -> URL? {
        guard let link = TRPImageResizer.generate(withUrl: getCellViewModel(at: indexPath).imageUrl, standart: .small), let url = URL(string: link) else {
            return nil
        }
        return url
    }
    
    
    deinit {
        removeObservers()
    }
    
}

extension MyOffersViewModel: ObserverProtocol {
    
    func addObservers() {
        
        observeOptInOfferUseCase?.poiValues.addObserver(self, observer: { [weak self] poiOffers in
            guard let strongSelf = self else {return}
            strongSelf.optInPois = poiOffers
        })
        
        observeOptInOfferUseCase?.values.addObserver(self, observer: { [weak self] offers in
            guard let strongSelf = self else {return}
            strongSelf.convertOffersToCellModel(offers: offers)
            
        })
    }
    
    func removeObservers() {
        observeOptInOfferUseCase?.values.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }
    
    private func convertOffersToCellModel(offers: [TRPOffer]) {
        cellViewModels = []
        offers.forEach { offer in
            var model = PoiOfferCellModel(offer: offer)
            let poi = self.optInPois.first(where: {$0.id == offer.poiId})
            model.poi = poi
            model.setClaimDate()
            cellViewModels.append(model)
        }
        delegate?.viewModel(dataLoaded: true)
    }
    
}

extension MyOffersViewModel {
    
    private func fetchOptInOffers() {
        delegate?.viewModel(showPreloader: true)
        fetchOptInOfferUseCase?.executeOptInOffers(dateFrom: nil, dateTo: nil) { [weak self] result in
            self?.delegate?.viewModel(showPreloader: false)
            if case .failure(let error) = result {
                self?.delegate?.viewModel(error: error)
            }
        }
    }
    
    func deleteMyOffer(offerId: Int) {
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
}
