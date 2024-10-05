//
//  TRPCityUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 29.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public final class TRPCityUseCases {
    
    private(set) var repository: CityRepository
    
    public init(cityRepository: CityRepository = TRPCityRepository()) {
        self.repository = cityRepository
    }
    
}

extension TRPCityUseCases: FetchCityUseCase {
    
    public func executeFetchCity(id: Int, completion: ((Result<TRPCity, Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
//        if let city = repository.results.first(where: { $0.id == id }) {
//            onComplete(.success(city))
//        }else {
            if ReachabilityUseCases.shared.isOnline {
                repository.fetchCity(id: id) { [weak self] result in
                    switch(result) {
                    case .success(let city):
                        print("[Info] completed")
//                        self?.repository.results = [city]
                        onComplete(.success(city))
                    case .failure(let error):
                        onComplete(.failure(error))
                    }
                }
            }else {
                repository.fetchLocalCity(id: id) { [weak self] result in
                    switch(result) {
                    case .success(let city):
                        print("[Info] completed")
//                        self?.repository.results = [city]
                        onComplete(.success(city))
                    case .failure(let error):
                        onComplete(.failure(error))
                    }
                }
            }
            
//        }
    }
    
}

extension TRPCityUseCases: FetchCitiesUseCase {
    
    public func executeFetchCities(completion: ((Result<[TRPCity], Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        if !repository.results.isEmpty {
            onComplete(.success(repository.results))
        }else {
            print("[Info] fetch cities")
            repository.fetchCities { [weak self] result in
                switch(result) {
                case .success(let cities):
                    print("[Info] completed")
                    self?.repository.results = cities
                    self?.repository.popularResults = cities.filter({$0.isPopular})
//                    self?.setParentCities()
                    onComplete(.success((self?.repository.results)!))
                case .failure(let error):
                    onComplete(.failure(error))
                }
            }
        }
    }
    
    public func executeFetchPopularCities(completion: ((Result<[TRPCity], Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        if !repository.popularResults.isEmpty {
            onComplete(.success(repository.popularResults))
        } else {
            print("[Info] fetch popular cities")
            executeFetchCities(completion: { [weak self] result in
                switch(result) {
                case .success(_):
                    onComplete(.success((self?.repository.popularResults)!))
                case .failure(let error):
                    onComplete(.failure(error))
                }
            })
        }
    }
    
    public func executeFetchShorexCities(completion: ((Result<[TRPCity], Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        if !repository.shorexResults.isEmpty {
            onComplete(.success(repository.shorexResults))
        } else {
            print("[Info] fetch cities")
            repository.fetchShorexCities { [weak self] result in
                switch(result) {
                case .success(let cities):
                    print("[Info] completed")
                    self?.repository.shorexResults = cities
//                    self?.setParentCities(forShorex: true)
                    onComplete(.success((self?.repository.shorexResults)!))
                case .failure(let error):
                    onComplete(.failure(error))
                }
            }
        }
    }
    
//    private func setParentCities(forShorex: Bool = false) {
//        ///Her seferinde döngü ile search yapmak yerine dictionary içerisinde id - name bilgileri üzerinden aramak için oluşturuldu
//        var results = forShorex  ? self.repository.shorexResults : self.repository.results
//        let cityDict: [Int : String] = Dictionary(uniqueKeysWithValues: results.map{ ($0.id, $0.name) })
//        for (index, city) in results.enumerated() {
//            let parentCityName = getParentCityName(city: city, cityDict: cityDict)
//            results[index].parentCityName = parentCityName
//        }
//    }
//
//    private func getParentCityName(city: TRPCity, cityDict: [Int : String]) -> String {
//        var parentCityName = city.parentCityName
//        guard let parentLocationId = city.parentLocationId, parentLocationId > 0, parentCityName.isEmpty else {
//            return parentCityName
//        }
//        if let parentCity = cityDict[parentLocationId] { // self.repository.results.first(where: {$0.id == city.parentLocationId})
//            parentCityName = parentCity
//        }
//
//        return parentCityName
//
//    }
    
}
