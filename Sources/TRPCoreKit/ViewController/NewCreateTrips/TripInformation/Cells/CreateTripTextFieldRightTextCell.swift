//
//  CreateTripTextFieldRightTextCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 2.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation

class CreateTripTextFieldRightTextCell: CreateTripTextFieldCell {
    @IBOutlet weak var lblRightText: UILabel!
    
    public func setRightText(_ text: String) {
        lblRightText.font = trpTheme.font.header2
        lblRightText.textColor = trpTheme.color.tripianBlack
        lblRightText.text = text
    }
}
