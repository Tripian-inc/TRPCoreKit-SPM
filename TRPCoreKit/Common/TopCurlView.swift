//
//  TopCurlView.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2021-05-23.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import UIKit
@objc(SPMTRPTopCurlView)
class TopCurlView: UIView {
    
    var backGroundView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        addSubview(backGroundView)
        backGroundView.translatesAutoresizingMaskIntoConstraints = false
        backGroundView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        backGroundView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        backGroundView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        backGroundView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        backGroundView.backgroundColor = UIColor.white
//        backGroundView.layer.cornerRadius = 30
        backGroundView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        backGroundView.layer.shadowColor = UIColor.lightGray.cgColor
        backGroundView.layer.shadowOffset = CGSize(width: 0, height: 4)
        backGroundView.layer.shadowOpacity = 0.3
        backGroundView.layer.shadowRadius = 5
        
        backgroundColor = UIColor.clear
    }
}
