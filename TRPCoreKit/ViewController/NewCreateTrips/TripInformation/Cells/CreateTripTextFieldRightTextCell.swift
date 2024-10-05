//
//  CreateTripTextFieldRightTextCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 2.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

class CreateTripTextFieldRightTextCell: CreateTripTextFieldCell {
    @IBOutlet weak var lblRightText: UILabel!
    @IBOutlet weak var lblPlaceHolder: UILabel!
    
    public func setRightText(_ text: String) {
        lblRightText.font = trpTheme.font.header2
        lblRightText.textColor = trpTheme.color.tripianBlack
        lblRightText.text = text
        lblPlaceHolder.isHidden = text.isEmpty
        if !text.isEmpty {
            lblPlaceHolder.font = trpTheme.font.semiBold12
            lblPlaceHolder.textColor = trpTheme.color.tripianPrimary
            lblPlaceHolder.text = textField.placeholder
            textField.placeholder = ""
        }
    }
}
