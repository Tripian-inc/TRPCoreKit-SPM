//
//  Loader.swift
//  TRPUIKit
//
//  Created by Evren Yaşar on 18.09.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import UIKit
class Loader : UIView{
    
    enum AnimationType: String {
        case opacity = "opacity"
        case scale = "transform.scale"
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        let layerSize = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
        let circleR: CGFloat = 12
        let circleCount: CGFloat = 3
        let p1 = createCircleLayer(r: circleR,
                                   position: CGPoint(x: layerSize.origin.x + (layerSize.width / (circleCount + 1)) - circleR/2,
                                                     y: layerSize.origin.y + (layerSize.height - circleR)/2))
        let p2 = createCircleLayer(r: circleR,
                                   position: CGPoint(x: layerSize.origin.x + (layerSize.width/(circleCount + 1)) * 2 - circleR/2,
                                                     y: layerSize.origin.y + (layerSize.height - circleR)/2))
        let p3 = createCircleLayer(r: circleR,
                                   position: CGPoint(x: layerSize.origin.x + (layerSize.width/(circleCount + 1)) * 3 - circleR/2,
                                                     y: layerSize.origin.y + (layerSize.height - circleR)/2))
        
        let layer = CAShapeLayer()
        layer.path = UIBezierPath(roundedRect: layerSize, cornerRadius: 14).cgPath
        layer.fillColor = UIColor.white.cgColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: -1, height: 1)
        layer.shadowRadius = 1
        layer.addSublayer(p1)
        layer.addSublayer(p2)
        layer.addSublayer(p3)
        
        self.layer.addSublayer(layer)
        p1.add(animation(duration: 0.4, delay: 0, animation: .scale, toValue: 0.3, fromValue: 1), forKey: "p1Scale")
        p2.add(animation(duration: 0.4, delay: 0.15, animation: .scale, toValue: 0.3, fromValue: 1), forKey: "p2Scale")
        p3.add(animation(duration: 0.4, delay: 0.30, animation: .scale, toValue: 0.3, fromValue: 1), forKey: "p3Scale")
    }
    
    private func createCircleLayer(r: CGFloat, position: CGPoint, color: UIColor? = TRPColor.orange) -> CAShapeLayer {
        let layer: CAShapeLayer = CAShapeLayer()
        let path: UIBezierPath = UIBezierPath()
        let size = CGSize(width: r, height: r)
        path.addArc(withCenter: CGPoint(x: size.width / 2, y: size.height / 2),
                    radius: size.width / 2,
                    startAngle: 0,
                    endAngle: CGFloat(2 * Double.pi),
                    clockwise: false)
        layer.fillColor = color?.cgColor
        
        layer.path = path.cgPath
        layer.frame = CGRect(x: position.x, y: position.y, width: size.width, height: size.height)
        return layer
    }
    
    private func animation(duration: TimeInterval, delay: TimeInterval? = nil, animation: AnimationType, toValue: Any?, fromValue: Any?) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: animation.rawValue)
        animation.toValue = toValue
        animation.fromValue = fromValue
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.autoreverses = true
        animation.repeatCount = .greatestFiniteMagnitude
        if let time = delay {
            animation.beginTime = CACurrentMediaTime() + time
        }
        animation.timeOffset = 0.3
        return animation
    }
}
