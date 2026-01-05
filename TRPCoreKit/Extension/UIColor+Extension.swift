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
    
    /// Creates a UIColor from RGB values (0-255) without needing to divide by 255.0
    /// - Parameters:
    ///   - red: Red component (0-255)
    ///   - green: Green component (0-255)
    ///   - blue: Blue component (0-255)
    ///   - alpha: Alpha component (0.0-1.0), defaults to 1.0
    convenience init(red: Int, green: Int, blue: Int, alpha: CGFloat = 1.0) {
        self.init(red: CGFloat(red) / 255.0,
                  green: CGFloat(green) / 255.0,
                  blue: CGFloat(blue) / 255.0,
                  alpha: alpha)
    }
    
}
