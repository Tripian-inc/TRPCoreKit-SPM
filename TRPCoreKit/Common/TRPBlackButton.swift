//
//  TRPBlackButton.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2021-05-19.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
@objc(SPMTRPBlackButton)
class TRPBlackButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = trpTheme.color.tripianPrimary
        layer.cornerRadius = 15
        setTitleColor(UIColor.white, for: .normal)
    }
}
@objc(SPMTRPBlackButtonSecondary)
class TRPBlackButtonSecondary: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        layer.borderWidth = 1
        layer.borderColor = trpTheme.color.tripianPrimary.cgColor
        backgroundColor = .clear
        layer.cornerRadius = 15
        setTitleColor(trpTheme.color.tripianPrimary, for: .normal)
    }
}
