//
//  TRPStarView.swift
//  TRPUIKit
//
//  Created by Evren Yaşar on 2020-10-30.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import UIKit

public class TRPStarView: UIView {

    var lineWidth: CGFloat = 10
    var fillColor = UIColor.yellow
    var lineColor = UIColor.yellow
    var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalCentering
        return stack
    }()
    var starViews: [UIView] = []
    public var star: Int = 5 {
        didSet {
            setup()
        }
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupStack()
        layoutIfNeeded()
    }
   
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        for index in 0..<5 {
            var isSelected = false
            if index <= star - 1 {
                isSelected = true
            }
            let star = createStarView(isSelected: isSelected)
            starViews.append(star)
            stackView.addArrangedSubview(star)
        }
    }
    
    private func setupStack() {
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
    
    private func createStarView(isSelected: Bool) -> UIView {
        let starView = UIView()
        starView.translatesAutoresizingMaskIntoConstraints = false
        starView.widthAnchor.constraint(equalToConstant: frame.height).isActive = true
        starView.heightAnchor.constraint(equalToConstant: frame.height).isActive = true
        let shapeLayer = getStartLayer(isSelected)
        let size = getSize()
        shapeLayer.transform = CATransform3DMakeScale(size, size, 1.0)
        starView.layer.addSublayer(shapeLayer)
        return starView
    }
    
    private func getSize() -> CGFloat {
        return frame.height / 160
    }
    
    
    private func updateStarFilling(){
        for (index, item) in starViews.enumerated() {
            
            if let shape = item.layer as? CAShapeLayer {
                if index >= star {
                    shape.fillColor = fillColor.cgColor
                }else {
                    shape.fillColor = UIColor.clear.cgColor
                }
            }
        }
    }
}

extension TRPStarView {
   
    
    private func getStartLayer(_ isSelected: Bool) -> CAShapeLayer{
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
