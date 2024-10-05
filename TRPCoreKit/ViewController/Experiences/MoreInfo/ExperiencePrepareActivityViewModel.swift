//
//  ExperiencePrepareActivityViewModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2020-11-07.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation


enum ExperiencePrepareType:String {
    case title
    case content
}

struct ExperienceMoreInfoModel {
    var type: ExperiencePrepareType
    var content: String
}
class ExperienceMoreInfoViewModel: TableViewViewModelProtocol {
    
    typealias T = ExperienceMoreInfoModel
    
    var cellViewModels: [ExperienceMoreInfoModel] = [] {
        didSet {
            delegate?.viewModel(dataLoaded: true)
        }
    }
    
    var numberOfCells: Int { return cellViewModels.count}
    
    weak var delegate: ViewModelDelegate?

    
    private(set) var tour: GYGTour
    
    init(tour: GYGTour) {
        self.tour = tour
    }
    
    func start() {
        prepareData()
    }
    
    func getCellViewModel(at indexPath: IndexPath) -> ExperienceMoreInfoModel {
        return cellViewModels[indexPath.row]
    }
    
}

extension ExperienceMoreInfoViewModel {
    
    private func prepareData() {
        var tempCells = [ExperienceMoreInfoModel]()
        if let des = tour.description, !des.isEmpty {
            tempCells.append(.init(type: .title, content: "Full description"))
            tempCells.append(.init(type: .content, content: des))
        }
        
        if let info = tour.additionalInformation, !info.isEmpty {
            tempCells.append(.init(type: .title, content: "Know before you go"))
            tempCells.append(.init(type: .content, content: info))
        }
        cellViewModels = tempCells
    }
}
