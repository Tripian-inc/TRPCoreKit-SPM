//
//  TRPTextField.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 10.06.2021.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

class TRPTextField: UITextField {
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        borderStyle = .none
        backgroundColor = trpTheme.color.extraSub
        layer.borderWidth = 1
        layer.borderColor = trpTheme.color.extraShadow.cgColor
        layer.cornerRadius = 15
        setLeftPaddingPoints(16)
        
        font = trpTheme.font.body2
        textColor = trpTheme.color.tripianTextPrimary
    }
}

@objc(SPMTRPTextFieldNew)
class TRPTextFieldNew: UITextField {
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        borderStyle = .none
        backgroundColor = trpTheme.color.tripianLightGrey
        layer.borderWidth = 0
        layer.cornerRadius = 10
        setLeftPaddingPoints(16)
        
//        font = trpTheme.font.header2
//        textColor = trpTheme.color.textBody
        font = trpTheme.font.header2
        textColor = trpTheme.color.tripianBlack
    }
    
    
    public func setPlaceholder(text: String) {
        self.attributedPlaceholder = NSAttributedString(
            string: text,
            attributes: [NSAttributedString.Key.foregroundColor: trpTheme.color.tripianTextPrimary,
                         NSAttributedString.Key.font: trpTheme.font.body1]
        )
    }
}
