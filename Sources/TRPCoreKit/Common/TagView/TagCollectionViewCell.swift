//
//  CompanionCollectionViewCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 13.06.2021.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import UIKit

class TagCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var bgView: UIView!
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
        bgView.layer.cornerRadius = 22
        label.font = trpTheme.font.body2
        setupForDeselected()
    }
    
    public func setupForDeselected() {
        bgView.backgroundColor = trpTheme.color.extraSub
        bgView.layer.borderWidth = 1
        bgView.layer.borderColor = trpTheme.color.extraShadow.cgColor
        label.textColor = trpTheme.color.tripianTextPrimary
    }
    
    public func setupForSelected() {
        bgView.backgroundColor = trpTheme.color.tripianPrimary
        bgView.layer.borderWidth = 0
        label.textColor = UIColor.white
    }
}
