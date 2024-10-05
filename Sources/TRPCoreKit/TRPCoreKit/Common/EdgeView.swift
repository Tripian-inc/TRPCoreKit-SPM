//
//  EdgeView.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2021-05-24.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import UIKit

class EdgeView: UIView {

    private var shapeLayer: CALayer?
    var height: CGFloat = 1.0
    var fillColor: UIColor = UIColor.white
    var strokeColor: UIColor = UIColor.black.withAlphaComponent(0.3)
    var strokeLineWidth: CGFloat = 0.0
    
    override func draw(_ rect: CGRect) {
        self.addShape()
    }
    
    private func addShape() {
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = createPath()
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.fillColor = fillColor.cgColor
        shapeLayer.lineWidth = strokeLineWidth
        
         
        
        if let oldShapeLayer = self.shapeLayer {
            self.layer.replaceSublayer(oldShapeLayer, with: shapeLayer)
        } else {
            self.layer.insertSublayer(shapeLayer, at: 0)
        }
        
        self.shapeLayer = shapeLayer
    }
    
    
    
    func createPath() -> CGPath {
        
        let path = UIBezierPath()
        
        path.move(to: CGPoint(x: 0, y: -40)) // start top left
        path.addQuadCurve(to: CGPoint(x: 40, y: 0), controlPoint: CGPoint(x: 0, y: 0))
        
        path.addLine(to: CGPoint(x: self.frame.width - 40, y: 0))
        path.addQuadCurve(to: CGPoint(x: self.frame.width, y: -40), controlPoint: CGPoint(x: self.frame.width, y: 0))
        
        path.addLine(to: CGPoint(x: self.frame.width, y: 0))
        path.addLine(to: CGPoint(x: self.frame.width, y: self.frame.height))
        path.addLine(to: CGPoint(x: 0, y: self.frame.height))
        path.close()
        
        return path.cgPath
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var sizeThatFits = super.sizeThatFits(size)
        if height > 0.0 {
            sizeThatFits.height = height
        }
        return sizeThatFits
    }
}
