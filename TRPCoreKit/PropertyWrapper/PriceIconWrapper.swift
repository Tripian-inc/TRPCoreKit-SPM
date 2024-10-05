//
//  PriceIconWrapper.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 25.03.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
@propertyWrapper
struct PriceIconWrapper {
    
    let min = 0
    let max = 4
    var value: Int
    
    var wrappedValue: Int {
        get {
            return value
        }
        set {
            value = Swift.max(Swift.min(newValue, self.max), self.min)
        }
    }
    
    init(wrappedValue: Int) {
        self.value = wrappedValue
        self.wrappedValue = wrappedValue
    }
    
    
    var projectedValue: PriceIconWrapper {
        return self
    }
    
    public func generateDolarSign(largeFontSize: Int = 13,
                                  smallFontSize: Int = 13,
                                  largeColor: UIColor = trpTheme.color.tripianTextPrimary,
                                  smallColor: UIColor = trpTheme.color.extraMain) -> NSMutableAttributedString{
        let boldPrice = String(repeating: "$" , count: 4)
        let largeAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: CGFloat(largeFontSize)),.foregroundColor: largeColor]
        let smallAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: CGFloat(smallFontSize)),.foregroundColor: smallColor]
        let attributedSentence = NSMutableAttributedString(string: boldPrice, attributes: smallAttributes)
        attributedSentence.setAttributes(largeAttributes, range: NSRange(location: 0, length: value))
        return attributedSentence
    }
    
}
