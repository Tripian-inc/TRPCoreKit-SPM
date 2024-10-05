//
//  UIView+constraints.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 9.08.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    static let seperatorTag = 983682
 
    func loadNib(nibName: String) -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
        layer.shadowRadius = 1
        layer.shadowOffset = CGSize(width: 3, height: 3)
        layer.shadowOpacity = 0.5
    }
    
    
    func addShadow(withRadius: CGFloat = 0) {
        layer.masksToBounds = false
        layer.cornerRadius = withRadius
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: -2, height: 2)
        layer.shadowRadius = withRadius
    }
    
    func constrainCentered(_ subview: UIView) {
        
        subview.translatesAutoresizingMaskIntoConstraints = false
        
        let verticalContraint = NSLayoutConstraint(
            item: subview,
            attribute: .centerY,
            relatedBy: .equal,
            toItem: self,
            attribute: .centerY,
            multiplier: 1.0,
            constant: 0)
        
        let horizontalContraint = NSLayoutConstraint(
            item: subview,
            attribute: .centerX,
            relatedBy: .equal,
            toItem: self,
            attribute: .centerX,
            multiplier: 1.0,
            constant: 0)
        
        let heightContraint = NSLayoutConstraint(
            item: subview,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1.0,
            constant: subview.frame.height)
        
        let widthContraint = NSLayoutConstraint(
            item: subview,
            attribute: .width,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1.0,
            constant: subview.frame.width)
        
        addConstraints([
                        horizontalContraint,
                        verticalContraint,
                        heightContraint,
                        widthContraint])
        
    }
    
    func constrainToEdges(_ subview: UIView, topSpacing: CGFloat = 0) {
        
        subview.translatesAutoresizingMaskIntoConstraints = false
        
        let topContraint = NSLayoutConstraint(
            item: subview,
            attribute: .top,
            relatedBy: .equal,
            toItem: self,
            attribute: .top,
            multiplier: 1.0,
            constant: topSpacing)
        
        let bottomConstraint = NSLayoutConstraint(
            item: subview,
            attribute: .bottom,
            relatedBy: .equal,
            toItem: self,
            attribute: .bottom,
            multiplier: 1.0,
            constant: 0)
        
        let leadingContraint = NSLayoutConstraint(
            item: subview,
            attribute: .leading,
            relatedBy: .equal,
            toItem: self,
            attribute: .leading,
            multiplier: 1.0,
            constant: 0)
        
        let trailingContraint = NSLayoutConstraint(
            item: subview,
            attribute: .trailing,
            relatedBy: .equal,
            toItem: self,
            attribute: .trailing,
            multiplier: 1.0,
            constant: 0)
        
        addConstraints([
                        topContraint,
                        bottomConstraint,
                        leadingContraint,
                        trailingContraint])
    }
    
    
    func addOverlay(color: UIColor = .black,alpha : CGFloat = 0.6) {
        let overlay = UIView()
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlay.frame = bounds
        overlay.backgroundColor = color
        overlay.alpha = alpha
        addSubview(overlay)
    }
    
    
    enum SeparatorPosition {
        case top
        case bottom
        case left
        case right
    }
    
    @discardableResult
    func addSeparator(at position: SeparatorPosition,
                      color: UIColor,
                      alpha: CGFloat = 1,
                      weight: CGFloat = 1.0 / UIScreen.main.scale,
                      insets: UIEdgeInsets = .zero) -> UIView {
        let view = UIView()
        view.backgroundColor = color
        view.alpha = alpha
        view.translatesAutoresizingMaskIntoConstraints = false
        view.tag = UIView.seperatorTag
        self.addSubview(view)
        
        switch position {
        case .top:
            view.topAnchor.constraint(equalTo: self.topAnchor, constant: insets.top).isActive = true
            view.leftAnchor.constraint(equalTo: self.leftAnchor, constant: insets.left).isActive = true
            view.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -insets.right).isActive = true
            view.heightAnchor.constraint(equalToConstant: weight).isActive = true
            
        case .bottom:
            view.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -insets.bottom).isActive = true
            view.leftAnchor.constraint(equalTo: self.leftAnchor, constant: insets.left).isActive = true
            view.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -insets.right).isActive = true
            view.heightAnchor.constraint(equalToConstant: weight).isActive = true
            
        case .left:
            view.topAnchor.constraint(equalTo: self.topAnchor, constant: insets.top).isActive = true
            view.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -insets.bottom).isActive = true
            view.leftAnchor.constraint(equalTo: self.leftAnchor, constant: insets.left).isActive = true
            view.widthAnchor.constraint(equalToConstant: weight).isActive = true
            
        case .right:
            view.topAnchor.constraint(equalTo: self.topAnchor, constant: insets.top).isActive = true
            view.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -insets.bottom).isActive = true
            view.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -insets.right).isActive = true
            view.widthAnchor.constraint(equalToConstant: weight).isActive = true
        }
        
        return view
    }
    
    func removeSeperator() {
        if let seperator = self.subviews.first(where: {$0.tag == UIView.seperatorTag}) {
            seperator.removeFromSuperview()
        }
    }
}
