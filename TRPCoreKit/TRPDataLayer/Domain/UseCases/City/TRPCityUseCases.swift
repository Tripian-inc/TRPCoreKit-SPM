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
        if let city = repository.results.first(where: { $0.id == id }) {
            onComplete(.success(city))
        }else {
            if ReachabilityUseCases.shared.isOnline {
                repository.fetchCity(id: id) { result in
                    switch(result) {
                    case .success(let city):
                        onComplete(.success(city))
                    case .failure(let error):
                        onComplete(.failure(error))
                    }
                }
            }else {
                repository.fetchLocalCity(id: id) { result in
                    switch(result) {
                    case .success(let city):
                        onComplete(.success(city))
                    case .failure(let error):
                        onComplete(.failure(error))
                    }
                }
            }
            
        }
    }
    
}

extension TRPCityUseCases: FetchCitiesUseCase {
    
    public func executeFetchCities(completion: ((Result<[TRPCity], Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        if !repository.results.isEmpty {
            onComplete(.success(repository.results))
        }else {
            repository.fetchCities { [weak self] result in
                switch(result) {
                case .success(let cities):
                    self?.repository.results = cities.sorted(by: {$0.displayName ?? $0.name < $1.displayName ?? $1.name})
                    self?.repository.popularResults = cities.filter({$0.isPopular})
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
            repository.fetchShorexCities { [weak self] result in
                switch(result) {
                case .success(let cities):
                    self?.repository.shorexResults = cities
                    onComplete(.success((self?.repository.shorexResults)!))
                case .failure(let error):
                    onComplete(.failure(error))
                }
            }
        }
    }
    
}

extension TRPCityUseCases: FetchCityInformationUseCase {
    public func executeFetchCityInformation(id: Int, completion: ((Result<TRPCityInformationData, any Error>) -> Void)?) {
        let onComplete = completion ?? { result in }
        repository.fetchCityInformation(id: id) { result in
            switch(result) {
            case .success(let cityInformation):
                onComplete(.success(cityInformation))
            case .failure(let error):
                onComplete(.failure(error))
            }
        }
    }
}
