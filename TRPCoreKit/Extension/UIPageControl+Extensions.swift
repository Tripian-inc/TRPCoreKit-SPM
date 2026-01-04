//
//  UIPageControl+Extensions.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 18.06.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
extension UIPageControl {

    func customPageControl(shadowColor: UIColor = UIColor.black, shadowOpacity: Float = 1, shadowRadius: CGFloat = 1) {
        for (_, dotView) in self.subviews.enumerated() {
            dotView.layer.shadowColor = shadowColor.cgColor
            dotView.layer.shadowOpacity = shadowOpacity
            dotView.layer.shadowOffset = .zero
            dotView.layer.shadowRadius = shadowRadius
        }
    }

}
