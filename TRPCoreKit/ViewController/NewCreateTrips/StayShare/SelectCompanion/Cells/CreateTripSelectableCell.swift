//
//  CreateTripSelectableCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 10.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

class CreateTripSelectableCell: UITableViewCell {
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var removeIcon: UIImageView!
    
    public var itemSelected: Bool = false {
        didSet {
            if itemSelected {
                setupForSelected()
            } else {
                setupForDeselected()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        bgView.layer.cornerRadius = 10
        label.font = trpTheme.font.display.noBold()
        label.textColor = trpTheme.color.tripianBlack
        removeIcon.isHidden = true
//        setupForDeselected()
    }
    
    public func setupForDeselected() {
        bgView.backgroundColor = .clear
        label.textColor = trpTheme.color.tripianTextPrimary
        label.font = trpTheme.font.display.noBold()
        removeIcon.isHidden = true
    }
    
    public func setupForSelected() {
        bgView.backgroundColor = trpTheme.color.tripianLightGrey
        label.textColor = trpTheme.color.tripianBlack
        label.font = trpTheme.font.display
        removeIcon.isHidden = false
    }
}
