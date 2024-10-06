//
//  CreateTripPersonalizeTripCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 14.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

@objc(SPMCreateTripPersonalizeTripCell)
class CreateTripPersonalizeTripCell: UITableViewCell {
    @IBOutlet weak var checkImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var checkImageLeadingConstraint: NSLayoutConstraint!
    
    public var isSubSelectable: Bool = false {
        didSet {
            iconImage.isHidden = !isSubSelectable
        }
    }
    public var itemSelected: Bool = false {
        didSet {
            if itemSelected {
                setupForSelected()
            } else {
                setupForDeselected()
            }
        }
    }
    
    private var isSubAnswer: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        
        titleLabel.font = trpTheme.font.body1
        titleLabel.textColor = trpTheme.color.tripianTextPrimary
        checkImage.image = CheckBoxCellState.unselected.getImage()
        setupForDeselected()
    }
    
    public func setupForDeselected() {
        checkImage.image = TRPImageController().getImage(inFramework: "icon_empty_check_new", inApp: nil)
        titleLabel.textColor = trpTheme.color.tripianTextPrimary
        titleLabel.font = isSubAnswer ? trpTheme.font.regular14 : trpTheme.font.body1
        iconImage.image = TRPImageController().getImage(inFramework: "icon_arrow_down", inApp: nil)
    }
    
    public func setupForSelected() {
        checkImage.image = TRPImageController().getImage(inFramework: "icon_checked_new", inApp: nil)
        titleLabel.textColor = trpTheme.color.tripianBlack
        titleLabel.font = isSubAnswer ? trpTheme.font.regular14 : trpTheme.font.header2
        iconImage.image = TRPImageController().getImage(inFramework: "icon_arrow_up", inApp: nil)
        
    }
    
    func setSubAnsert(_ status: Bool) {
        isSubAnswer = status
        if status {
            checkImageLeadingConstraint.constant = 20
            titleLabel.font = trpTheme.font.regular14
        } else {
            checkImageLeadingConstraint.constant = 0
            titleLabel.font = trpTheme.font.body1
        }
    }
}
