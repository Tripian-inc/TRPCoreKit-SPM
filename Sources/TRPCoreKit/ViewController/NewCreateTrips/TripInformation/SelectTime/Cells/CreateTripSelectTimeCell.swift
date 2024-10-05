//
//  CreateTripSelectTimeCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 4.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

class CreateTripSelectTimeCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    
    public var isSelectedTime: Bool = false {
        didSet {
            self.setupLabel()
        }
    }
    
    public func setText(text: String, isSelected: Bool) {
        label.text = text
        isSelectedTime = isSelected
        setupLabel()
    }
    
    private func setupLabel() {
        label.textColor = isSelectedTime ? trpTheme.color.tripianPrimary : .black
        label.font = trpTheme.font.regular24
        let selectedBgColor = UIColor.init(red: 255/255, green: 238/255, blue: 240/255, alpha: 1)
        label.backgroundColor = isSelectedTime ? selectedBgColor : .clear
        label.layer.cornerRadius = 6
    }
}
