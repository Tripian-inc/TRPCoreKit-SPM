//
//  TRPBlackButton.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2021-05-19.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import Foundation
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
