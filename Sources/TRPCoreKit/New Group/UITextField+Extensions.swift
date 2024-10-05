//
//  UITextField+Extensions.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 10.06.2021.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
extension UITextField {
    //MARK: - TEXTFIELD LEFT & RIGHT PADDING AND IMAGE

    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    
    func setRightPaddingPoints(_ amount:CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
    
    func setLeftImage(image: UIImage, color : UIColor = trpTheme.color.extraMain) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 49, height: 24))
        let imageView = UIImageView(frame: CGRect(x: 16, y: 0, width: 24, height: 24))
        paddingView.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        imageView.tintColor = color
//        paddingView.backgroundColor = trpTheme.color.deepPink
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}
