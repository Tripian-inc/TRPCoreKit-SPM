//
//  DateAndTravellerAddButtonCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 22.06.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation

class DateAndTravellerAddButtonCell: UITableViewCell {
        
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subLabel: UILabel!
    @IBOutlet weak var addButton: UIImageView!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var subLabelImage: UIImageView!
    @IBOutlet weak var subViewHeightCOnstraint: NSLayoutConstraint!
    
    var subTitle: String? {
        didSet {
            subLabel.text = subTitle
            if let subTitle = self.subTitle, subTitle.count > 0 {
                showSubView()
            } else {
                hideSubView()
            }
        }
    }
    
    var showRemoveButton = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = trpTheme.font.body2
        titleLabel.textColor = trpTheme.color.extraMain
        
        subLabel.font = trpTheme.font.body2
        subLabel.textColor = trpTheme.color.tripianTextPrimary
        removeButton.isHidden = true
    }
    
    public func hideSubView() {
        subViewHeightCOnstraint.constant = 0
        showHideRemoveButton(willShow: false)
    }
    
    public func showSubView() {
        subViewHeightCOnstraint.constant = 29
        showHideRemoveButton(willShow: showRemoveButton)
    }
    
    private func showHideRemoveButton(willShow: Bool) {
        removeButton.isHidden = !willShow
        addButton.isHidden = willShow
    }
    
}


