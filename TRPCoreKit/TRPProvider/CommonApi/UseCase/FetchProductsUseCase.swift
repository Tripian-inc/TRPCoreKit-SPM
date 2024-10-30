//
//  FetchProductsUseCase.swift
//  TRPProvider
//
//  Created by Cem Çaygöz on 26.08.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation

public protocol FetchProductsUseCase: AnyObject {
    func getJuniperProducts(startDate: String, endDate: String, destinationId: Int, completion: @escaping (Result<[JuniperProduct]?, Error>) -> Void)
}

public class TRPFetchProductsUseCase: FetchProductsUseCase {
    public func getJuniperProducts(startDate: String, 
                                   endDate: String,
                                   destinationId: Int,
                                   completion: @escaping (Result<[JuniperProduct]?, any Error>) -> Void) {
        TripianCommonApi.shared.getProducts(destinationId,
                                       startDate: startDate,
                                       endDate: endDate) { result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
