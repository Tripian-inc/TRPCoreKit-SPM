//
//  UIBarButtonItem+Extensions.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 12.07.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation

extension UIBarButtonItem {
    
    func setDefaultColor() {
        self.tintColor = TRPAppearanceSettings.Common.barButtonForInputButtonColor
    }
    
}
