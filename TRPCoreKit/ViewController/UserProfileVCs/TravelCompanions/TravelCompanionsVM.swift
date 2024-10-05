//
//  TravelCompanionsVM.swift
//  TRPCoreKit
//
//  Created by Rozeri Dağtekin on 6/25/19.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation




protocol TravelCompanionVMDelegate:AnyObject{
    func travelCompanionVM(showPreloader:Bool)
    func travelCompanionVM(error:Error)
    func travelCompanionVM(dataLoaded:Bool)
    func companionRemoved(indexPath: IndexPath)
    
}

public class TravelCompanionsVM {
    var travelCompanions: [TRPCompanion] = []
    weak var delegate: TravelCompanionVMDelegate?
    
    public var fetchCompanionUseCase: FetchCompanionUseCase?
    public var deleteCompanionUseCase: DeleteCompanionUseCase?
    public var observeCompanionUseCase: ObserveCompanionUseCase?
    
    
    init() {}
    
    public func start() {
        addObservers()
        fetchCompanionUseCase?.executeFetchCompanion(completion: nil)
    }
    
    func getDataCount() -> Int {
        return travelCompanions.count
    }
    
    func getItem(indexPath: IndexPath) -> TRPCompanion {
        return travelCompanions[indexPath.row]
    }
    
    func removeCompanion(companionId: Int, indexPath: IndexPath) -> Void {
        delegate?.travelCompanionVM(showPreloader: true)
        deleteCompanionUseCase?.executeDeleteCompanion(id: companionId, completion: { [weak self] result in
            guard let strongSelf = self else {return}
            strongSelf.delegate?.travelCompanionVM(showPreloader: false)
            switch result {
            case .success(_): ()
            case .failure(let error):
                strongSelf.delegate?.travelCompanionVM(error: error)
            }
        })
    }

    deinit {
        removeObservers()
    }
    
}

extension TravelCompanionsVM: ObserverProtocol {
    func addObservers() {
        observeCompanionUseCase?.values.addObserver(self, observer: { [weak self] companions in
            self?.travelCompanions = companions
            self?.delegate?.travelCompanionVM(dataLoaded: true)
        })
    }
    
    func removeObservers() {
        observeCompanionUseCase?.values.removeObserver(self)
    }
    
}
