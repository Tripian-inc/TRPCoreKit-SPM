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

    /// Recursively recolors all UILabel `textColor` values and any view's `layer.borderColor`
    /// (where borderWidth > 0) to the provided color. Backgrounds, images, image tints,
    /// and button styling are left untouched. Used by timeline cells to render past-day
    /// items with muted text/border treatment.
    func trp_recolorLabelsAndBorders(to color: UIColor) {
        if let label = self as? UILabel {
            label.textColor = color
        }
        if layer.borderWidth > 0 {
            layer.borderColor = color.cgColor
        }
        for sub in subviews {
            sub.trp_recolorLabelsAndBorders(to: color)
        }
    }

}




