//
//  TimeInterval+Extension.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 7.10.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation
extension TimeInterval {
    
    func format(using units: NSCalendar.Unit) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = units
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: self)
    }
    
}
