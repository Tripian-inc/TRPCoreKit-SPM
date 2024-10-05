//
//  YelpError.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 13.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
public struct YelpErrorResult: Codable {
    let error: YelpError
}

public struct YelpError: Codable {
    public let code, errorDescription: String

    enum CodingKeys: String, CodingKey {
        case code
        case errorDescription = "description"
    }
}
