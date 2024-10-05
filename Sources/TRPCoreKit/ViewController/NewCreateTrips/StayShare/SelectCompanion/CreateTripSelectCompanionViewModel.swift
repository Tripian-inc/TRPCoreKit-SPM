//
//  CreateTripSelectCompanionVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 10.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation
import TRPDataLayer

protocol CreateTripSelectCompanionViewModelDelegate: ViewModelDelegate {
    func selectedItemsChanged(isEmpty: Bool)
}
class CreateTripSelectCompanionViewModel {
    
    public var selectedItems: [TRPCompanion] = [] {
        didSet {
            self.delegate?.selectedItemsChanged(isEmpty: selectedItems.isEmpty)
        }
    }
    public weak var delegate: CreateTripSelectCompanionViewModelDelegate?
    var travelCompanions: [TRPCompanion] = [] {
        didSet {
            self.delegate?.viewModel(dataLoaded: true)
        }
    }
    
    public var fetchCompanionsUseCase: FetchCompanionUseCase?
    public var observeCompanionUseCase: ObserveCompanionUseCase?
    
    public init() {}
    
    public func start() {
        
        addObservers()
        
        fetchCompanionsUseCase?.executeFetchCompanion(completion: nil)
    }
    
    func getDataCount() -> Int {
        return travelCompanions.count
    }
    
    func getItem(indexPath: IndexPath) -> TRPCompanion {
        return travelCompanions[indexPath.row]
    }
    
    func itemSelectionToggled(_ model: TRPCompanion) {
        if isItemSelected(model) {
            selectedItems.remove(element: model)
        } else {
            selectedItems.append(model)
        }
    }
    
    func isItemSelected(_ model: TRPCompanion) -> Bool {
        return selectedItems.contains(model)
    }
    
    deinit {
        removeObservers()
    }
    
}

extension CreateTripSelectCompanionViewModel: ObserverProtocol {
    
    func addObservers() {
        observeCompanionUseCase?.values.addObserver(self, observer: { [weak self] companions in
            self?.travelCompanions = companions
        })
        
    }
    
    func removeObservers() {
        observeCompanionUseCase?.values.removeObserver(self)
    }
    
}
