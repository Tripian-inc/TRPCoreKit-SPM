//
//  PoiUseCases.swift
//  TRPDataLayer
//
//  Created by Evren Yaşar on 17.08.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation


public protocol SearchPoiUseCase {

    func executeSearchPoi(text: String,
                          categoies: [Int],
                          boundaryNorthEast: TRPLocation,
                          boundarySouthWest: TRPLocation,
                          completion: ((Result<[TRPPoi], Error>, TRPPagination?)-> Void)?
                            )
    
    /// Eğer kullanıcı o şehirde ise çalışır.
    func executeSearchPoi(text: String,
                          categoies: [Int],
                          userLocation: TRPLocation,
                          completion: ((Result<[TRPPoi], Error>, TRPPagination?)-> Void)?
                            )
}


public protocol FetchPoiUseCase {
    
    func executeFetchPoi(ids: [String],
                         completion: ((Result<[TRPPoi], Error>, TRPPagination?)-> Void)?
                        )
    
    func executeFetchPoi(id: String,
                         completion: ((Result<TRPPoi?, Error>)-> Void)?
                        )
    
}

public protocol FethCategoryPoisUseCase {
    
    // Recommendataion
    func executeFetchCategoryPois(categoryIds: [Int],
                                  completion: ((Result<[TRPPoi], Error>, TRPPagination?) -> Void)?
                                )
    
}


public protocol FetchNearByPoiUseCase {

    // Nearby
    func executeFetchNearByPois(location:TRPLocation,
                                categoryIds: [Int],
                                completion: ((Result<[TRPPoi], Error>, TRPPagination?)-> Void)?
                                )

}

public protocol FetchBoundsPoisUseCase {
    func executeFetchNearByPois(northEast:TRPLocation, southWest: TRPLocation,
                                categoryIds: [Int]?,
                                completion: ((Result<[TRPPoi], Error>, TRPPagination?)-> Void)?
                                )
    
    
}


public protocol FetchPoiWithMustTries {
    func executeFetchPoiWithMustTries(ids: [Int],
                                      completion: ((Result<[TRPPoi], Error>, TRPPagination?)-> Void)?
                                    )
}

public protocol FetchPoiNextUrlUseCase {
    
    func executeFetchPoi(url: String,
                         completion: ((Result<[TRPPoi], Error>, TRPPagination?)-> Void)?
                        )
}
