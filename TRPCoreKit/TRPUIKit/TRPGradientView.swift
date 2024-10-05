//
//  TRPGradientView.swift
//  TRPUIKit
//
//  Created by Evren Yaşar on 31.08.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import UIKit
public class TRPGradientView: UIView {
    
    public var topColor: UIColor = UIColor.black {
        didSet {
            gradientLayer.colors = [topColor.cgColor, bottomColor.cgColor]
        }
    }
    
    public var bottomColor: UIColor = UIColor.white {
        didSet {
            gradientLayer.colors = [topColor.cgColor, bottomColor.cgColor]
        }
    }
    
    public var cornerRadius: CGFloat = 2 {
        didSet {
            layoutSubviews()
        }
    }
    
    public lazy var gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [topColor.cgColor, bottomColor.cgColor]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 0, y: 1)
        return layer
    }()
    
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        backgroundColor = UIColor.red
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        layer.addSublayer(gradientLayer)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        print("layer loaded")
        let mFrame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        gradientLayer.frame = mFrame
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(roundedRect: mFrame, cornerRadius: cornerRadius).cgPath
        layer.mask = maskLayer
    }
    
}
