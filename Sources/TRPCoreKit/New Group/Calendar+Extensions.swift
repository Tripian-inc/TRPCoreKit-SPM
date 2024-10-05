//
//  Calendar+Extancion.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 8.07.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation
extension Calendar {
  
    static var currentWithUTC: Calendar {
        get {
            var cal = Calendar.current
            if let timeZone = TimeZone(identifier: "UTC") {
                cal.timeZone = timeZone
            }
            return cal
        }
    }

}




