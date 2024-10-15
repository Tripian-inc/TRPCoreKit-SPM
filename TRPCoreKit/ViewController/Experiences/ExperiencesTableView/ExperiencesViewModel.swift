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
//    var datas: [GYGTour] //Generic yapılabiir
}

protocol ExperiencesViewModelDelegate: ViewModelDelegate {
    func experiencesViewModelShowEmptyWarning()
}


final class ExperiencesViewModel: TableViewViewModelProtocol {
    
    
    typealias T = ExperiencesCellModel
    
    weak var delegate: ExperiencesViewModelDelegate?
    
    var cellViewModels: [ExperiencesCellModel] = [] {
        didSet {
            delegate?.viewModel(dataLoaded: true)
        }
    }
    var cityName: String
    var destinationId: Int
    
    var numberOfCells: Int {
        return cellViewModels.count
    }
    
    private var requestCount = 0
    
    //-----USE CASES
    public var tripModeUseCase: ObserveTripModeUseCase?
    
    
    //Settings
    public var uniqueToursWithCategory = true
    public var showLimitByCategory = 20
    private let addStarDayToEnd = 7
    
    
    public init(cityName: String, destinationId: Int) {
        self.cityName = cityName
        self.destinationId = destinationId
    }
    
    public func start() {
        let tourDates = calculateDatesJuniper()
        //fetchTours(startDate: tourDates.startDate, endDate: tourDates.endDate)
        fetchJuniperTours(startDate: tourDates.startDate, endDate: tourDates.endDate, destinationId: destinationId)
    }
    
    func getCellViewModel(at indexPath: IndexPath) -> ExperiencesCellModel {
        return cellViewModels[indexPath.row]
    }
    
}

extension ExperiencesViewModel {
    
    private func calculateDates() -> (startDate: String?, endDate: String?) {
        
        if let startTime = tripModeUseCase?.trip.value?.getArrivalDate()?.toDate {
            guard let start = startTime.setHour(0, minutes: 0), let added7day = start.addDay(addStarDayToEnd), let end = added7day.setHour(23, minutes: 59) else {
                print("[Error] Date can not conveted")
                return (nil,nil)
            }
            let startDate = start.toString(format: "yyyy-MM-dd'T'HH:mm:ss", dateStyle: nil, timeStyle: nil)
            let endDate = end.toString(format: "yyyy-MM-dd'T'HH:mm:ss", dateStyle: nil, timeStyle: nil)
            print("Start Date \(startDate)")
            print("End Date \(endDate)")
            return (startDate: startDate, endDate: endDate)
        }
        return (nil,nil)
    }
    
    private func calculateDatesJuniper() -> (startDate: String, endDate: String) {
        
        if let startTime = tripModeUseCase?.trip.value?.getArrivalDate()?.toDate, let endTime = tripModeUseCase?.trip.value?.getDepartureDate()?.toDate  {
            let startDate = startTime.toString(format: "yyyy-MM-dd", dateStyle: nil, timeStyle: nil)
            let endDate = endTime.toString(format: "yyyy-MM-dd", dateStyle: nil, timeStyle: nil)
            print("Start Date \(startDate)")
            print("End Date \(endDate)")
            return (startDate: startDate, endDate: endDate)
        }
        return (Date().toString(format: "yyyy-MM-dd"), Date().toString(format: "yyyy-MM-dd"))
    }
    
    
    private func fetchTours(startDate: String? = nil, endDate: String? = nil, duration: Int = 1440) {
        delegate?.viewModel(showPreloader: true)
        GetYourGuideApi().tours(cityName: cityName, fromDate: startDate, toDate: endDate, limit: 90) { [weak self] result in
            self?.delegate?.viewModel(showPreloader: false)
            switch result {
            case .success(let tours):
                self?.seperateWithCategory(tours: tours)
            case .failure(let error):
                self?.delegate?.viewModel(error: error)
            }
        }
    }
    
    
    private func fetchJuniperTours(startDate: String, endDate: String, destinationId: Int) {
        delegate?.viewModel(showPreloader: true)
        TripianCommonApi().getProducts(destinationId, startDate: startDate, endDate: endDate) { [weak self] result in
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
                                                 price: tour.getCheapestPrice())
            tmpTours.append(cellModel)
        }
        cellViewModels = tmpTours
    }
    
    public func getProductUrl(at indexPath: IndexPath) -> URL? {
        let model = getCellViewModel(at: indexPath)
        
        let splittedCode = model.code.split(separator: "¬")
        if splittedCode.count > 1 {
            let encodeCode = "\(splittedCode[1])¥TKT¥\(splittedCode[0])¥\(destinationId)¥\(model.code)"
            
            let url = "https://www.nexustours.com/en/services/\(cityName)/\(encodeCode)&utm_source=nexusapp&utm_medium=tripian"
            return URL(string: url)
            
        }
        return nil
    }
    
    private func seperateWithCategory(tours: [GYGTour]) {
//        let sorted = sortTours(tours)
//        var mainTour = filterTours(sorted)
//        for category in GYGCatalogCategory.allCases {
//            let categoriestTour = mainTour.filter { (tour) -> Bool in
//                return tour.categories.contains(where: {$0.categoryID == category.id()})
//            }
//            
//            let limitedTours = limitTours(categoriestTour)
//            if uniqueToursWithCategory {
//                createCellModel(tours: limitedTours, category: category)
//                limitedTours.forEach { tour in
//                    mainTour.removeAll(where: {$0.tourID == tour.tourID})
//                }
//            }else {
//                createCellModel(tours: limitedTours, category: category)
//            }
//        }
//        delegate?.experiencesViewModelShowEmptyWarning()
    }
    
    private func createCellModel(tours: [GYGTour], category: GYGCatalogCategory) {
//        guard tours.count > 0 else {return}
//        let cellModel = ExperiencesCellModel(title: category.rawValue, datas: tours)
//        cellViewModels.append(cellModel)
    }
    
    private func sortTours(_ data: [GYGTour]) -> [GYGTour]{
        let sortedTours = data.sorted { (lhs, rhs) -> Bool in
            return lhs.numberOfRatings ?? 0 > rhs.numberOfRatings ?? 0
        }
        return sortedTours
    }
    
    private func limitTours(_ data: [GYGTour]) -> [GYGTour] {
        guard data.count > showLimitByCategory else {
            return data
        }
        return Array(data[0..<showLimitByCategory])
    }
    
    private func filterTours(_ data: [GYGTour]) -> [GYGTour] {
        data.filter { tour -> Bool in
            guard let durations = tour.durations, durations.count < 10 else {return true}
            var show = true
            durations.forEach { duration in
                if let unit = duration.unit, let time = duration.duration, unit == "day", time > 1 {
                    show = false
                }
            }
            return show
        }
    }
    
}
