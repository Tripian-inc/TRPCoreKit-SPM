//
//  CheckboxCollectionViewCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 9.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

class CheckboxCell: UITableViewCell {
    @IBOutlet weak var checkboxImg: UIImageView!
    @IBOutlet weak var label: UILabel!
    
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
//        bgView.layer.cornerRadius = 22
        label.font = trpTheme.font.body1
        setupForDeselected()
    }
    
    public func setupForDeselected() {
        checkboxImg.image = TRPImageController().getImage(inFramework: "icon_empty_check_new", inApp: nil)
        label.textColor = trpTheme.color.tripianTextPrimary
        label.font = label.font.noBold()
    }
    
    public func setupForSelected() {
        checkboxImg.image = TRPImageController().getImage(inFramework: "icon_checked_new", inApp: nil)
        label.textColor = trpTheme.color.tripianBlack
        label.font = label.font.bold()
    }
}
