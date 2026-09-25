//
//  CheckBookingUseCase.swift
//  TRPProvider
//
//  Created by Cem Çaygöz on 9.08.2023.
//  Copyright © 2023 Tripian Inc. All rights reserved.
//

import Foundation

public protocol CheckBookingUseCase: AnyObject {
    func checkBookingStatus(hash: String, completion: @escaping (Result<GYGPaymentBooking?, Error>) -> Void)
}

public class TRPCheckBookingUseCase: CheckBookingUseCase {
    
    public let language: String
    public let currency: String
    
    public init(language: String = "en",
                currency: String = "EUR") {
        self.language = language
        self.currency = currency
    }
    
    public func checkBookingStatus(hash: String, completion: @escaping (Result<GYGPaymentBooking?, Error>) -> Void) {
        GetYourGuideApi().getBooking(hash: hash, language: language, currency: currency) {result in
            switch result{
            case .success(let booking):
                completion(.success(booking))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
}
