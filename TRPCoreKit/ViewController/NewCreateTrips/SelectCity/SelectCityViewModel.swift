//
//  SelectCityViewModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 19.10.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation



public class CitycontinentModel {
    public var continentName: String = ""
    public var continentSlug: String = ""
    public var cities: [SelectCityCellModel]  = []
}

public struct SelectCityCellModel {
    public var cityId: Int
    public var name: String
    public var city: TRPCity
}

public class SelectCityViewModel {
    
    private var isFiltering: Bool = false
    private var filteredDatas = [CitycontinentModel]()
    private var cities = [TRPCity]()
    private var datas = [CitycontinentModel]() {
        didSet {
            DispatchQueue.main.async {
                 self.delegate?.viewModel(dataLoaded: true)
            }
        }
    }
    
    public var fetchCityUseCase: FetchCitiesUseCase?
    
    weak var delegate: ViewModelDelegate?
    
    public func getMainTitle() -> String {
        return TRPLanguagesController.shared.getLanguageValue(for: "select_destination_city")
    }
    
    public func getCurrentStep() -> String {
        return "1"
    }
    
    public init() {}
    
    public func start() {
        delegate?.viewModel(showPreloader: true)
        fetchCityUseCase?.executeFetchCities(completion: { [weak self] result in
            self?.delegate?.viewModel(showPreloader: false)
            switch(result) {
            case .success(let cities):
                let cityWithContinent = self?.createContinientArray(cities: cities)
                self?.datas = cityWithContinent ?? []
                self?.cities = cities
            case .failure(let error):
                self?.delegate?.viewModel(error: error)
            }
        })
    }
    
    public func getCityCount(inSection at: Int) -> Int {
        if datas.isEmpty {
            return 0
        }
        if isFiltering {
            return filteredDatas[at].cities.count
        }
        return datas[at].cities.count
    }
    
    public func getSectionCount() -> Int {
        if isFiltering {
            return filteredDatas.count
        }
        return datas.count
    }
    
    func getFilteredSection(_ searchText: String, scope: String = "All") -> [CitycontinentModel] {
        return filteredDatas
    }
    
    public func getSectionTitle(index: Int) -> String {
        if isFiltering {
            return filteredDatas[index].continentName
        }
        return datas[index].continentName
    }
    
    public func getSectionSlug(index: Int) -> String {
        if isFiltering {
            return filteredDatas[index].continentSlug
        }
        return datas[index].continentSlug
    }
    
    public func getCity(indexPath: IndexPath) -> SelectCityCellModel{
        if isFiltering {
            return filteredDatas[indexPath.section].cities[indexPath.row]
        }
        return datas[indexPath.section].cities[indexPath.row]
    }
    
    public func getCityName(indexPath: IndexPath) -> String {
        let city = getCity(indexPath: indexPath)
//        var cityName = city.name
//        let parentCity = city.city.parentLocations.first?.name
//        if !(parentCity?.isEmpty ?? true) {
//            cityName += " (in \(parentCity))"
//        }
        return city.name
    }
    
    public func getData() -> [CitycontinentModel]{
        return datas
    }
    
    public func isOnlyOneCity() -> Bool {
        return datas.count == 1 && datas[0].cities.count == 1
    }

    
    /// Sehir verileri ile kıta verilerini eşleştirir. Sehirleri kıtalara göre ayırır.
    /// - Parameter cities: TRPCity array
    /// - Returns: Continent ve city birleştirilmiş hali.
    private func createContinientArray(cities: [TRPCity]) -> [CitycontinentModel] {
        
        var cityWithContinent = [CitycontinentModel]()
        let sortedCities = cities.sorted(by: {$0.name < $1.name})
        for city in sortedCities {
            
            let cellModel = SelectCityCellModel(cityId: city.id, name: city.name, city: city)
            if let continentOfCity = city.continent {
                if let continent = cityWithContinent.first(where: {$0.continentSlug == continentOfCity.slug}) {
                    continent.cities.append(cellModel)
                } else {
                    let section = CitycontinentModel()
                    section.continentName = continentOfCity.name ?? ""
                    section.continentSlug = continentOfCity.slug ?? ""
                    section.cities.append(cellModel)
                    cityWithContinent.append(section)
                }
            }
            
        }
        return cityWithContinent
    }
    
}

extension SelectCityViewModel {
    
    
    public func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredDatas = []
        isFiltering = !searchText.isEmpty
        guard isFiltering else {
            self.delegate?.viewModel(dataLoaded: true)
            return
        }
        let filteredCities = cities.filter {$0.name.lowercased().contains(searchText.lowercased())}
        filteredDatas = createContinientArray(cities: filteredCities)
//        filteredDatas = getData().filter { $0.cities.contains(where: { $0.name.lowercased().contains(searchText.lowercased()) }) }
        self.delegate?.viewModel(dataLoaded: true)
    }
}

