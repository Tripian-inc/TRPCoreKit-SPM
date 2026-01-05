//
//  TRPPoiRepository.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 17.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

final public class TRPPoiRepository: PoiRepository {
    
    private let USE_CACHE = true
    
    public var pois: [TRPPoi] = []
    
    public var poiCategories: [TRPPoiCategoyGroup] = []
    
    public var poisWithParameters: [PoiParameters : [TRPPoi]] = [:]
    public var poisParametersNextLink: [PoiParameters : TRPPagination?] = [:]
    
    public var remoteApi: PoiRemoteApi
    
    public var localStorage: PoiLocalStorage
    
    
    public init(remoteApi: PoiRemoteApi = TRPPoiRemoteApi(),
         localStorage: PoiLocalStorage = TRPPoiLocalStorage()) {
        
        self.remoteApi = remoteApi
        self.localStorage = localStorage
    }
    
    
    /// Sehir bazlı Poi isteklerini kontrol eder
    /// - Parameters:
    ///   - cityId: SehirId
    ///   - parameters: Istencek poilerin parametleri
    ///   - completion:
    public func fetchPoi(cityId: Int,
                         parameters: PoiParameters,
                         completion: @escaping (PoiResultsValue) -> Void) {
        
        //Parametreye sehir bilgisi eklenir.
        var parametersWithCity = parameters
        parametersWithCity.cityId = cityId
        
        //Parametre kontrol edilir.
        let checkWithParams = checkParameters(parametersWithCity)
        
        //Eğer parametre daha önce kullnıldı ise bir önceki sorgu gönderili.
        if let poisInCache = checkWithParams.pois, checkWithParams.continue == false {
            
            completion((.success(poisInCache), checkNextLink(parametersWithCity)))
            return
        }
        
        
        //Sadece PoiId bazlı sorgular için kontrol edilir.
        let existingResult = checkExistPoi(parameters: parametersWithCity)
        
         
        if let newPois = existingResult.pois, existingResult.continue == false {
            completion((.success(newPois), nil))
        }else {
            remoteApi.fetchPoi(cityId: cityId, parameters: existingResult.parameters) { [weak self] result in
                switch result.0 {
                case .success(let apiPois):
                    guard let strongSelf = self else {return}
                    strongSelf.pois.append(contentsOf: apiPois)
                    var _pois = apiPois
                    
                    _pois.append(contentsOf: existingResult.pois ?? [])
                    if strongSelf.USE_CACHE, !strongSelf.poisWithParameters.contains(where: {$0.key == parametersWithCity}) {
                        if result.1 != .completed {
                            strongSelf.poisParametersNextLink[parametersWithCity] = result.1
                        }
                        strongSelf.poisWithParameters[parametersWithCity] = _pois.unique()
                    }
                    completion((.success(_pois.unique()), result.1))
                case .failure(let error):
                    print("[Error] \(existingResult.parameters.poiIds ?? [])")
                    completion((.failure(error), result.1))
                }
            }
            
        }
        
    }
    public func fetchLocalPoi(completion: @escaping (PoiResultsValue) -> Void) {
        localStorage.fetchLocalPoi(completion: completion)
    }
    
    
    public func fetchPoi(coordinate: TRPLocation,
                         parameters: PoiParameters,
                         completion: @escaping (PoiResultsValue) -> Void) {
        
        var parametersWithCity = parameters
        parametersWithCity.userLocation = coordinate
        
        //Parametre kontrol edilir.
        let checkWithParams = checkParameters(parametersWithCity)
        
        //Eğer parametre daha önce kullnıldı ise bir önceki sorgu gönderili.
        if let poisInChach = checkWithParams.pois, checkWithParams.continue == false {
            completion((.success(poisInChach), nil))
            return
        }
        
        remoteApi.fetchPoi(coordinate: coordinate, parameters: parametersWithCity) { [weak self] result in
            switch result.0 {
            case .success(let apiPois):
                
                self?.pois.append(contentsOf: apiPois)
                self?.poisWithParameters[parametersWithCity] = apiPois
                
                completion((.success(apiPois), result.1))
            case .failure(let error):
                completion((.failure(error), result.1))
            }
        }
        
    }
    
    
    
    public func fetchPoi(url: String, completion: @escaping (PoiResultsValue) -> Void) {
        
        let parameters = PoiParameters(url:url)
        let checkWithParams = checkParameters(parameters)
        
        //Eğer parametre daha önce kullnıldı ise bir önceki sorgu gönderili.
        if let poisInCache = checkWithParams.pois, checkWithParams.continue == false {
            completion((.success(poisInCache), checkNextLink(parameters)))
            return
        }
        
        
        remoteApi.fetchPoi(url: url) { [weak self] result in
            guard let strongSelf = self else {return}
            
            switch result.0 {
            case .success(let apiPois):
                
                strongSelf.pois.append(contentsOf: apiPois)
                
                if strongSelf.USE_CACHE, !strongSelf.poisWithParameters.contains(where: {$0.key == parameters}) {
                    if result.1 != .completed {
                        strongSelf.poisParametersNextLink[parameters] = result.1
                    }
                    strongSelf.poisWithParameters[parameters] = apiPois.unique()
                }
                completion((.success(apiPois.unique()), result.1))
            case .failure(let error):
                completion((.failure(error), result.1))
            }
            
        }
        
        remoteApi.fetchPoi(url: url, completion: completion)
    }
    
    
    
    public func fetchPoi(poiId: String, completion: @escaping (PoiResultValue) -> Void) {
        if let poi = pois.first(where: {$0.id == poiId}) {
            completion(.success(poi))
            return
        }
        
        remoteApi.fetchPoi(poiId: poiId) { [weak self] result in
            guard let strongSelf = self else {return}
            
            switch result {
            case .success(let poi):
                strongSelf.pois.append(poi)
                completion((.success(poi)))
            case .failure(let error):
                completion((.failure(error)))
            }
            
        }
    }
    
    public func addPois(contentsOf: [TRPPoi]) {
        var uniqeu = [TRPPoi]()
        contentsOf.forEach { poi in
            if !pois.contains(poi) {
                uniqeu.append(poi)
            }
        }
        pois.append(contentsOf: uniqeu)
    }
    
    public func fetchPoiCategories(completion: @escaping (PoiCategoriesResultValue) -> Void) {
        if !poiCategories.isEmpty {
            completion((.success(poiCategories)))
            return
        }
        remoteApi.fetchPoiCategories() { [weak self] result in
            guard let strongSelf = self else {return}
            
            switch result {
            case .success(let poiCategories):
                strongSelf.poiCategories = poiCategories
                completion((.success(poiCategories)))
            case .failure(let error):
                completion((.failure(error)))
            }
        }
    }
}


//MARK: LOGIC
extension TRPPoiRepository {
    
    
    /// Sorguları parametre bazlı kontrol eder.
    /// Eğer aynı parametreler ile sorgu geldiyse onları tekrardan çekmek yerine mevcut verideki sonucu döndürür
    /// - Parameter parameters: Sorgular. CityId veya Coordinate eklenmek zorundadır
    /// - Returns: Continue false ise APi ye sorgu yapılmaz. Sonuc direk var olan arrayden döndürürlür.
    private func checkParameters(_ parameters: PoiParameters) -> (continue: Bool, parameters: PoiParameters, pois: [TRPPoi]?) {
        if let pois = poisWithParameters.first(where: {$0.key == parameters}) {
            return (false, parameters, pois.value)
        }
        
        return (true, parameters, nil)
    }
    
    private func checkNextLink(_ parameters: PoiParameters) -> TRPPagination? {
        if let params = poisParametersNextLink.first(where: {$0.key == parameters}) {
            return params.value
        }
        return nil
    }
    
    
    /// Sadece poi id istendiğinde kullanılır. Mevcut poilere bakılarak var olanlar çıkarılır. Eksik olalar ise talep edilir.
    /// - Parameter parameters: PoiParameterleri
    /// - Returns: Parameterda eskik poiler gönderiler, var olanlar listeden silinir.
    private func checkExistPoi(parameters: PoiParameters ) -> (continue: Bool, parameters: PoiParameters, pois: [TRPPoi]?)   {
        
        var _parameters = parameters
        
        guard let requestedPois = _parameters.poiIds else {
            return (true, parameters, [])
        }
        
        
        var existingPois = [TRPPoi]()
        var missingPoiIds = [String]()
        
        requestedPois.forEach { poiId in
            if let existingPoi = pois.first(where: {$0.id == poiId}) {
                existingPois.append(existingPoi)
            }else {
                missingPoiIds.append(poiId)
            }
        }
        
        if requestedPois.count == existingPois.count && missingPoiIds.count == 0 {
            
            _parameters.poiIds = []
            
            return (false, _parameters, existingPois)
        }else {

            _parameters.poiIds = missingPoiIds
            
            return (true, parameters, existingPois)
        }
    }
    
    
}
