//
//  Float+Extensions.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2020-11-09.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
extension Float {
    var clean: String {
       return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}
