//
//  SelectCompanionVM.swift
//  TRPCoreKit
//
//  Created by Rozeri Dağtekin on 6/28/19.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation



public class SelectCompanionVM {
    //MARK: - Variables
    public var selectedItem = [TRPCompanion]()
    public weak var delegate: ViewModelDelegate?
    var travelCompanions: [TRPCompanion] = [] {
        didSet {
            self.delegate?.viewModel(dataLoaded: true)
        }
    }
    
    public var fetchCompanionsUseCase: FetchCompanionUseCase?
    public var observeCompanionUseCase: ObserveCompanionUseCase?
    public var deleteCompaninoUseCase: DeleteCompanionUseCase?
    
    public var fromSDK: Bool = false
    public var fromProfile: Bool = false
    
    
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
        if selectedItem.contains(model) {
            selectedItem.remove(element: model)
        } else {
            selectedItem.append(model)
        }
    }
    
    func isItemSelected(_ model: TRPCompanion) -> Bool {
        return selectedItem.contains(model)
    }
    
    func deleteCompanion(indexPath: IndexPath) -> Void {
        self.delegate?.viewModel(showPreloader: true)
        let itemId = travelCompanions[indexPath.row].id
        deleteCompaninoUseCase?.executeDeleteCompanion(id: itemId,
                                                 completion: { [weak self] result in
            guard let strongSelf = self else {return}
            strongSelf.delegate?.viewModel(showPreloader: false)
            switch result {
            case .failure(let error):
                strongSelf.delegate?.viewModel(error: error)
                break
            case .success(_):
                break
            }
        })
        
    }
    
    deinit {
        removeObservers()
    }
    
}

extension SelectCompanionVM: ObserverProtocol {
    
    func addObservers() {
        observeCompanionUseCase?.values.addObserver(self, observer: { [weak self] companions in
            self?.travelCompanions = companions
        })
        
    }
    
    func removeObservers() {
        observeCompanionUseCase?.values.removeObserver(self)
    }
    
}
