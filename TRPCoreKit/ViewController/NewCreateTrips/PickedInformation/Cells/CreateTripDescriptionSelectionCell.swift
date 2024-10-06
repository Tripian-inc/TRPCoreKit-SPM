//
//  CreateTripDescriptionSelectionCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 12.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

@objc(SPMCreateTripDescriptionSelectionCell)
class CreateTripDescriptionSelectionCell: UITableViewCell {
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var descriptionLbl: UILabel!
    @IBOutlet weak var checkImg: UIImageView!
    
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
        
        selectionStyle = .none
        bgView.layer.cornerRadius = 15
        bgView.backgroundColor = trpTheme.color.tripianLightGrey
        bgView.layer.borderWidth = 0
        titleLbl.font = trpTheme.font.header2
        titleLbl.textColor = trpTheme.color.tripianBlack
        descriptionLbl.font = trpTheme.font.body1
        descriptionLbl.textColor = trpTheme.color.tripianTextPrimary
        setupForDeselected()
    }
    
    public func setupForDeselected() {
        checkImg.image = TRPImageController().getImage(inFramework: "icon_empty_check_new", inApp: nil)
        bgView.layer.borderWidth = 1
        bgView.layer.borderColor = UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1).cgColor
        bgView.backgroundColor = .clear
    }
    
    public func setupForSelected() {
        checkImg.image = TRPImageController().getImage(inFramework: "icon_checked_new", inApp: nil)
        bgView.layer.borderWidth = 0
        bgView.backgroundColor = UIColor(red: 255/255, green: 238/255, blue: 240/255, alpha: 1)
    }
}
