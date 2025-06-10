//
//  ExperiencesViewModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 15.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation



struct ExperiencesCellModel {
    var code: String
    var title: String
    var image: String
    var price: String
    var categories: [String]
//    var datas: [GYGTour] //Generic yapılabiir
}

protocol ExperiencesViewModelDelegate: ViewModelDelegate {
    func experiencesViewModelShowEmptyWarning()
}


final class ExperiencesViewModel: TableViewViewModelProtocol {
    
    
    typealias T = ExperiencesCellModel
    
    weak var delegate: ExperiencesViewModelDelegate?
    
    private var allText: String = "All"
    
    var filteredCellViewModels: [ExperiencesCellModel] = []
    var cellViewModels: [ExperiencesCellModel] = [] {
        didSet {
            delegate?.viewModel(dataLoaded: true)
        }
    }
    var cityName: String
    var destinationId: Int
    
    private var startDate: String?
    private var endDate: String?
    
    var numberOfCells: Int {
        return filteredCellViewModels.count
    }
    
    private var requestCount = 0
    
    //-----USE CASES
    public var tripModeUseCase: ObserveTripModeUseCase?
    
    
    public init(cityName: String, destinationId: Int, startDate: String? = nil, endDate: String? = nil) {
        self.cityName = cityName
        self.destinationId = destinationId
        self.startDate = startDate
        self.endDate = endDate
    }
    
    public func start() {
        let tourDates = calculateDatesJuniper()
        //fetchTours(startDate: tourDates.startDate, endDate: tourDates.endDate)
        allText = TRPLanguagesController.shared.getLanguageValue(for: "all")
        fetchJuniperTours(startDate: tourDates.startDate, endDate: tourDates.endDate, destinationId: destinationId)
    }
    
    func getCellViewModel(at indexPath: IndexPath) -> ExperiencesCellModel {
        return filteredCellViewModels[indexPath.row]
    }
    
}

extension ExperiencesViewModel {
    
    private func calculateDatesJuniper() -> (startDate: String, endDate: String) {
        
        if let startDate = self.startDate, let endDate = self.endDate {
            return (startDate, endDate)
        }
        
        if let startTime = tripModeUseCase?.trip.value?.getArrivalDate()?.toDate, let endTime = tripModeUseCase?.trip.value?.getDepartureDate()?.toDate  {
            let startDate = startTime.toString(format: "yyyy-MM-dd", dateStyle: nil, timeStyle: nil)
            let endDate = endTime.toString(format: "yyyy-MM-dd", dateStyle: nil, timeStyle: nil)
            print("Start Date \(startDate)")
            print("End Date \(endDate)")
            return (startDate, endDate)
        }
        return (Date().toString(format: "yyyy-MM-dd"), Date().toString(format: "yyyy-MM-dd"))
    }
    
    
    private func fetchJuniperTours(startDate: String, endDate: String, destinationId: Int) {
        delegate?.viewModel(showPreloader: true)
        TripianCommonApi.shared.getProducts(destinationId, startDate: startDate, endDate: endDate) { [weak self] result in
            self?.delegate?.viewModel(showPreloader: false)
            switch result {
            case .success(let tours):
                self?.createJuniperTourModels(tours: tours)
//                self?.seperateWithCategory(tours: tours)
            case .failure(let error):
                self?.delegate?.viewModel(error: error)
            }
        }
    }
    
    private func createJuniperTourModels(tours: [JuniperProduct]) {
        cellViewModels = []
        guard tours.count > 0 else {
            delegate?.experiencesViewModelShowEmptyWarning()
            return
        }
        var tmpTours: [ExperiencesCellModel] = []
        for tour in tours {
            let cellModel = ExperiencesCellModel(code: tour.code, 
                                                 title: tour.serviceInfo?.name ?? "",
                                                 image: tour.getImage(),
                                                 price: tour.getCheapestPrice(),
                                                 categories: tour.tripianCategories ?? [])
            tmpTours.append(cellModel)
        }
        tmpTours.sort(by: {$0.categories.count > $1.categories.count})
        filteredCellViewModels = tmpTours
        cellViewModels = tmpTours
    }
    
    public func getProductUrl(at indexPath: IndexPath) -> URL? {
        let model = getCellViewModel(at: indexPath)
        
        let splittedCode = model.code.split(separator: "¬")
        if splittedCode.count > 1 {
            let encodeCode = "\(splittedCode[1])¥TKT¥\(splittedCode[0])¥\(destinationId)¥\(model.code)"
            let url = "https://www.nexustours.com/en/services/\(destinationId)/\(encodeCode)/"
            return NexusHelper.getCustomPoiUrl(url: url, startDate: self.startDate ?? "")            
        }
        return nil
    }
    
}

extension ExperiencesViewModel {
    
    public func filterContentForSearchText(_ searchText: String) {
        filteredCellViewModels = []
        if searchText.isEmpty {
            filteredCellViewModels = cellViewModels
        } else {
            filteredCellViewModels = cellViewModels.filter {$0.title.isContainsWithoutCase(to: searchText)}
        }
        self.delegate?.viewModel(dataLoaded: true)
    }
    
    public func filterContentForCategory(_ category: String) {
        filteredCellViewModels = []
        if category.isEmpty || category == allText {
            filteredCellViewModels = cellViewModels
        } else {
            filteredCellViewModels = cellViewModels.filter {$0.categories.contains(category)}
        }
        self.delegate?.viewModel(dataLoaded: true)
    }
    
    public func getTourCategories() -> [String] {
        var uniqueArray = [String]()
        cellViewModels.compactMap(\.categories).forEach { uniqueArray = Array(Set($0 + uniqueArray)) }
        uniqueArray = uniqueArray.sorted()
        uniqueArray.insert(allText, at: 0)
        return uniqueArray
    }
}
