//
//  TravelCompanionsVM.swift
//  TRPCoreKit
//
//  Created by Rozeri Dağtekin on 6/25/19.
//  Copyright © 2019 Evren Yaşar. All rights reserved.
//

import Foundation
import TRPRestKit

protocol TravelCompanionVMDelegate: ViewModelDelegate{
    func companionRemoved(indexPath: IndexPath)
}

public class TravelCompanionsVM {
    var travelCompanions: [TRPCompanionModel] = []
    weak var delegate: TravelCompanionVMDelegate?
    
    //TODO: Rozeri Localization
    init() {
    }
    
    func getDataCount() -> Int {
        return travelCompanions.count
    }
    
    func getItem(indexPath: IndexPath) -> TRPCompanionModel {
        return travelCompanions[indexPath.row]
    }
    
    func refreshData() {
        getUsersCompanions()
    }
    
    private func getUsersCompanions() -> Void {
        self.delegate?.viewModel(showPreloader: true)
        TRPRestKit().getUsersCompanions() { [weak self] (result, error) in
            guard let strongSelf = self else {return}
            strongSelf.delegate?.viewModel(showPreloader: false)
            if let error = error {
                strongSelf.delegate?.viewModel(error: error)
                return
            }
            if let r = result as? [TRPCompanionModel] {
                strongSelf.travelCompanions = r
                strongSelf.delegate?.viewModel(dataLoaded: true)
            }
        }
    }
    
    func removeCompanion(companionId: Int, indexPath: IndexPath, completed: @escaping (Bool)->Void) -> Void {
        self.delegate?.viewModel(showPreloader: true)
        TRPRestKit().removeCompanion(companionId: companionId , completion: { [weak self] (result, error) in
            guard let strongSelf = self else {return}
            strongSelf.delegate?.viewModel(showPreloader: false)
            if let error = error {
                completed(false)
                strongSelf.delegate?.viewModel(error: error)
                return
            }
            if let _ = result as? TRPParentJsonModel{
                strongSelf.removeCompanion(withCompanionId: companionId)
                strongSelf.delegate?.companionRemoved(indexPath: indexPath)
            }
            completed(true)
        })
    }
    
    func removeCompanion(withCompanionId companionId: Int) {
        self.travelCompanions = travelCompanions.filter() { $0.id != companionId}
    }
}
