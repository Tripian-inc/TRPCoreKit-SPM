//
//  YelpStatus.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 20.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

public struct YelpStatus: Codable {
    public let active: Bool
    public let date: String
    public let time: String
    public let covers: Int
}
 /**
 {
     "active": true,
     "date": "2020-07-21",
     "time": "16:30:00",
     "covers": 1
 }
 
 */
