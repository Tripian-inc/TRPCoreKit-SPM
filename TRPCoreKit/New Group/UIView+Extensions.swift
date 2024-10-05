//
//  UIView+Extensions.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2020-12-23.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
extension UIView {
    
    static func makeSpacer() -> UIView {
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return spacer
    }
    
}



