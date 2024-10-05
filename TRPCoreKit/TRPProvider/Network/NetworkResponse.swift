//
//  NetworkResponse.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 13.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public enum NetworkResponse {
    case success
    case authenticationError
    case badRequest
    case outDated
    case failed
    case noData
    case unableToDecode
}

