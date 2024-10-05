//
//  CreateTripTextFieldCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 29.09.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

class CreateTripTextFieldCell: UITableViewCell {
    @IBOutlet weak var textField: TRPTextFieldNew!
    
    public func setPlaceholder(text: String) {
        textField.setPlaceholder(text: text)
    }
    
    public func setupCell() {
        selectionStyle = .none
        textField.isUserInteractionEnabled = false
    }
}


class CreateTripTextFieldHeaderCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = trpTheme.font.header1
        titleLabel.textColor = trpTheme.color.tripianBlack
        titleLabel.numberOfLines = 0
    }
    
    public func setTitle(_ text: String, isRequired: Bool = false) {
        if isRequired {
            let title = text + "*"
            let requiredAttriString = NSMutableAttributedString(string: title)
            let range1 = (title as NSString).range(of: "*")
            requiredAttriString.addAttribute(NSAttributedString.Key.foregroundColor, value: trpTheme.color.tripianPrimary, range: range1)
            titleLabel.attributedText = requiredAttriString
        } else {
            titleLabel.text = text
        }
    }
}
