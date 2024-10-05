//
//  TRPSearchAreaButton.swift
//  TRPUIKit
//
//  Created by Evren Yaşar on 10.09.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import UIKit
public class TRPSearchAreaButton: UIButton {
    
    private var animator = UIViewPropertyAnimator()
    public var title:String? {
        didSet {
            setTitle(title ?? "", for: UIControl.State.normal)
        }
    }
    
    
    public var titleColor: UIColor = UIColor.black {
        didSet {
            setTitleColor(titleColor, for: UIControl.State.normal)
        }
    }
    public var fontSize: CGFloat = 13 {
        didSet {
            titleLabel?.font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)
        }
    }
    public var cornerRadius : CGFloat = 14 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    
    public var shadowColor: UIColor = UIColor.black{
        didSet {
            layer.shadowColor = shadowColor.cgColor
        }
    }
    
    public var shadowRadius: CGFloat = 1 {
        didSet {
            layer.shadowRadius = shadowRadius
        }
    }
    
    public var shadowOpacity: Float = 0.7 {
        didSet {
            layer.shadowOpacity = shadowOpacity
        }
    }
    
    public var shadownOffset: CGSize = CGSize(width: 0, height: 1) {
        didSet {
            layer.shadowOffset = shadownOffset
        }
    }
    
    public var isAnimating = false
    public var isOpen: Bool = false
    public var zoomLevelTrashHold: Double = 20 //12.4 //asd
    
    public init(frame: CGRect, title:String) {
        super.init(frame: frame)
        self.title = title
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        backgroundColor = UIColor.white
        layer.cornerRadius = cornerRadius
        setTitle(title ?? "", for: UIControl.State.normal)
        setTitleColor(titleColor, for: UIControl.State.normal)
        titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
        layer.borderColor = UIColor(red: 227/255, green: 228/255, blue: 236/255, alpha: 1).cgColor
        layer.borderWidth = 1
        /*layer.shadowColor = shadowColor.cgColor
        layer.shadowRadius = shadowRadius
        layer.shadowOpacity = shadowOpacity
        layer.shadowOffset = shadownOffset */
        hidden()
    }
    
    
    public func show() {
        isHidden = false
    }
    
    public func hidden() {
        isHidden = true
    }
    
    public func zoomLevel(_ level: Double) {
        if level > zoomLevelTrashHold {
            show()
        }else {
            hidden()
        }
    }
    
    public func setZoomLevelTreshold(_ level: Double){
        self.zoomLevelTrashHold = level
    }
    
}
