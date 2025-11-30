//
//  UIImageView+Extensions.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 16.08.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import UIKit

extension UIImageView {
    
    func gradient(bounds: CGRect, colors: [CGColor]) {
        let view = UIView(frame: bounds)
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = colors
        gradient.locations = [0.0, 1.0]
        view.layer.insertSublayer(gradient, at: 0)
        self.addSubview(view)
        self.bringSubviewToFront(view)
    }
    
    
}
