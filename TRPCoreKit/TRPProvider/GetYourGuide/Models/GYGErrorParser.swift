//
//  GYGErrorParser.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 2020-12-09.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
//   let welcome = try? newJSONDecoder().decode(Welcome.self, from: jsonData)

import Foundation

// MARK: - Welcome
public struct GYGErrorParser: Codable {
    let method: String?
    let status: String
    let errors: [GYGError]?
    let date: String?
    let helpURL: String?
    let apiVersion, descriptor: String?
}

// MARK: - Error
struct GYGError: Codable {
    let errorMessage: String
    let errorCode: Int
}
