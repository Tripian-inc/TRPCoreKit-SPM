//
//  TRPStar.swift
//  TRPUIKit
//
//  Created by Evren Yaşar on 19.09.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//
import UIKit

public class TRPStar: UIView {
    
    var spacing: CGFloat = 4
    var lineWidth: CGFloat = 10
    var fillColor = TRPColor.orange
    var lineColor = TRPColor.orange
    var shapes: [CAShapeLayer] = []
    var isLoaded = false
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.blue
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setRating(_ count: Int) {
        
        for i in 0...4 {
            //Fixme: - ac bu kodu
            if i < count {
                shapes[i].fillColor = fillColor.cgColor
            }else {
                shapes[i].fillColor = UIColor.clear.cgColor
            }
        }
    }
    
    public func show() {
        
        if isLoaded == true {return}
        let size = getSize()
        
        let posX = getShortEdge() + spacing
        for i in 0...4 {
            let star = getStartLayer(false)
            shapes.append(star)
            layer.addSublayer(star)
            star.transform = CATransform3DMakeScale(size, size, 1.0)
            star.position.x = posX * CGFloat(i)
            
        }
        
        frame = CGRect(x: 0, y: 0, width: posX * CGFloat(4) , height: 20)
        isLoaded = true
        layoutIfNeeded()
    }
    
    private func getSize() -> CGFloat {
        return getShortEdge() / 160
    }
    
    private func getShortEdge() -> CGFloat {
        var value: CGFloat = 0
        if self.frame.width < self.frame.height  {
            value = self.frame.width
        }else {
            value = self.frame.height
        }
        return value
    }
    
    
    func getStartLayer(_ isSelected: Bool) -> CAShapeLayer{
        let starPath = UIBezierPath()
        starPath.move(to: CGPoint(x: 81.5, y: 7.0))
        starPath.addLine(to: CGPoint(x: 101.07, y: 63.86))
        starPath.addLine(to: CGPoint(x: 163.0, y: 64.29))
        starPath.addLine(to: CGPoint(x: 113.16, y: 99.87))
        starPath.addLine(to: CGPoint(x: 131.87, y: 157.0))
        starPath.addLine(to: CGPoint(x: 81.5, y: 122.13))
        starPath.addLine(to: CGPoint(x: 31.13, y: 157.0))
        starPath.addLine(to: CGPoint(x: 49.84, y: 99.87))
        starPath.addLine(to: CGPoint(x: 0.0, y: 64.29))
        starPath.addLine(to: CGPoint(x: 61.93, y: 63.86))
        starPath.addLine(to: CGPoint(x: 81.5, y: 7.0))
        
        let starLayer = CAShapeLayer()
        starLayer.path = starPath.cgPath
        if isSelected {
            starLayer.fillColor = fillColor.cgColor
        }else  {
            starLayer.fillColor = UIColor.clear.cgColor
        }
        
        starLayer.strokeColor = lineColor.cgColor
        starLayer.lineWidth = lineWidth
        return starLayer
    }
}
