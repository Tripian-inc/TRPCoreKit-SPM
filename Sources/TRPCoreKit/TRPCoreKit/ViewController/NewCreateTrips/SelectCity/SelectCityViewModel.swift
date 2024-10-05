//
//  SelectCityViewModel.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 19.10.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation
import TRPRestKit
import TRPDataLayer

public class CitycontinentModel {
    public var continentName: String = ""
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
                let cityWithContinent = self?.createContinientArray(cities:cities)
                self?.datas = cityWithContinent ?? []
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
    
    public func getCity(indexPath: IndexPath) -> SelectCityCellModel{
        if isFiltering {
            return filteredDatas[indexPath.section].cities[indexPath.row]
        }
        return datas[indexPath.section].cities[indexPath.row]
    }
    
    public func getCityName(indexPath: IndexPath) -> String {
        let city = getCity(indexPath: indexPath)
        var cityName = city.name
        let parentCity = city.city.parentLocations.first?.name
        if !(parentCity?.isEmpty ?? true) {
            cityName += " (in \(parentCity))"
        }
        return cityName
    }
    
    public func getData() -> [CitycontinentModel]{
        return datas
    }
    
    public func isOnlyOneCity() -> Bool {
        return datas.count == 1 && datas[0].cities.count == 1
    }
    
//    public func getFirstCity() -> SelectCityCellModel {
//        return getCity(indexPath: IndexPath(row: 0, section: 0))
//    }

    
    /// Sehir verileri ile kıta verilerini eşleştirir. Sehirleri kıtalara göre ayırır.
    /// - Parameter cities: TRPCity array
    /// - Returns: Continent ve city birleştirilmiş hali.
    private func createContinientArray(cities: [TRPCity]) -> [CitycontinentModel] {

        var cityWithContinient = [CitycontinentModel]()
        let sortedCities = cities.sorted(by: {$0.name < $1.name})
        for city in sortedCities {
            
            let cellModel = SelectCityCellModel(cityId: city.id, name: city.name, city: city)
            if let continientOfCity = city.countryContinents.first {
                if let continient = cityWithContinient.first(where: {$0.continentName == continientOfCity}) {
                    continient.cities.append(cellModel)
                }else {
                    let section = CitycontinentModel()
                    section.continentName = continientOfCity
                    section.cities.append(cellModel)
                    cityWithContinient.append(section)
                }
            }
            
        }
        return cityWithContinient
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
        for data in getData(){
            var cities = [SelectCityCellModel]()
            for city in data.cities{
                if (city.name.folding(options: .diacriticInsensitive, locale: .current).lowercased().contains(searchText.folding(options: .diacriticInsensitive, locale: .current).lowercased())){
                    cities.append(city)
                }
            }
            if cities.count > 0 {
                let cityContinentModel = CitycontinentModel()
                cityContinentModel.cities = cities
                cityContinentModel.continentName = data.continentName
                filteredDatas.append(cityContinentModel)
            }
        }
        self.delegate?.viewModel(dataLoaded: true)
    }
}

