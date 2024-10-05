//
//  OverviewViewModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2020-11-02.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit
import TRPDataLayer
import TRPUIKit


protocol OverviewViewModelDelegate: ViewModelDelegate {
    
}

final class OverviewViewModel {
    
    public var dayData: OverViewSection? {
        didSet {
            delegate?.viewModel(dataLoaded: true)
        }
    }
    weak var delegate: OverviewViewModelDelegate?
    
    public init(dayData: OverViewSection) {
        self.dayData = dayData
    }
    
    func start() {
        //delegate?.viewModel(showPreloader: true)
//        dataIsLoaded = false
//        addObservers()
    }
    
    func getStepCount() -> Int {
        guard let data = dayData else { return 0 }
        return data.steps.count
    }
    
    public func getStep(indexPath: IndexPath) -> TRPStep {
        return dayData!.steps[indexPath.row]
    }
    
    func getSinglerCategory(id: Int) -> String? {
        guard let type = TRPPoiCategory.idToType(id) else {
            return nil
        }
        return type.getSingler()
    }
    
    func getCellModel(indexPath:IndexPath) -> OverviewVCTableViewCellModel {
        let model = getStep(indexPath: indexPath)
        let poi = model.poi
        
        let title = poi.name
        let image = getPlaceImage(poi: poi)
        let score = getMatchScore(model: model)
        let category = getCategoryName(poi: poi)
        return OverviewVCTableViewCellModel( title: title, placeImage: image, matchPercent: score, placeType: category)
    }
    
    private func getCategoryName(poi: TRPPoi) -> String {
        guard let category = poi.categories.first, let categoryName = getSinglerCategory(id: category.id) else { return "" }
        return categoryName
        
    }
    
    private func getPlaceImage(poi: TRPPoi) -> URL? {
        let mUrl = poi.image.url
        guard let link = TRPImageResizer.generate(withUrl: mUrl, standart: .small) else {
            return nil
        }
        if let url = URL(string: link) {
            return url
        }
        return nil
    }
    
    private func getMatchScore(model: TRPStep) -> String {
        guard let score = model.score else { return "" }
        return "\(Int(score))% match"
    }
}
