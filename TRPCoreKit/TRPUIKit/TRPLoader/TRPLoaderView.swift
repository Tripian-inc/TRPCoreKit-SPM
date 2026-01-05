//
//  TRPLoaderView.swift
//  TRPUIKit
//
//  Created by Evren Yaşar on 27.09.2018.
//  Copyright © 2018 Evren Yaşar. All rights reserved.
//

import Foundation
import UIKit

public class TRPLoaderView: UIView {
    var loaderView: Loader?
    var backgroundBtn: UIButton?
    let superView: UIView
    var isAdded = false
    
    public init(superView: UIView) {
        self.superView = superView
        super.init(frame: CGRect.zero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func show() {
        if isAdded == true {return}
        
        let widht: CGFloat = 100
        let height: CGFloat = 40
        loaderView = Loader(frame: CGRect(x: (superView.frame.width - widht) / 2,
                                          y: (superView.frame.height - height) / 3,
                                          width: widht,
                                          height: height))
        backgroundBtn = UIButton(frame: .init(x: 0, y: 0, width: superView.frame.width, height: superView.frame.height))
        backgroundBtn!.setTitle("", for: .normal)
        backgroundBtn!.backgroundColor = .clear
        
        superView.addSubview(backgroundBtn!)
        superView.addSubview(loaderView!)
        isAdded = true
    }
    
    public func remove() {
        if isAdded == false {return}
        if loaderView != nil {
            loaderView!.removeFromSuperview()
        }
        if backgroundBtn != nil {
            backgroundBtn!.removeFromSuperview()
        }
        isAdded = false
    }
}
