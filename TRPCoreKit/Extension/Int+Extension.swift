//
//  Int+Extension.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 7.10.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation
extension Int {
    func minutesToHoursMinutes () -> (hours : Int , leftMinutes : Int) {
        return (self / 60, (self % 60))
    }
    
    func metesToKmMtr() -> (km:Int, m:Int) {
        return (self / 1000, (self % 1000))
    }
    
    /// Okunabilir mesafe verisi üretir.
    /// 1000 metreden kücükde sonun m ekler
    /// 1000 den büyükse, böler ve sonun km ekler
    func reableDistance() -> String {
        if self > 1000 {
            return "\(self / 1000) km"
        }
        return "\(self) m"
    }

    /// Formats the integer with thousand separators (e.g., 74913 -> "74.913")
    var formattedWithSeparator: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
