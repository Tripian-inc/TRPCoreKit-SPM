//
//  Double+Extensions.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 24.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
extension Double {
    var clean: String {
       return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}
