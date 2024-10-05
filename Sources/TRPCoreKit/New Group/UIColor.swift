//
//  UIColor.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 22.01.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import UIKit
extension UIColor {
    
    static var random: UIColor {
        return UIColor(red: .random(in: 0...1),
                       green: .random(in: 0...1),
                       blue: .random(in: 0...1),
                       alpha: 1)
    }
    
}
