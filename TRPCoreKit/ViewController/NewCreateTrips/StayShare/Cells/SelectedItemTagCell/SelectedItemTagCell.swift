//
//  SelectedItemTagCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 9.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
@objc(SPMSelectedItemTagCell)
class SelectedItemTagCell: UICollectionViewCell {
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var label: UILabel!
    public var tagItem: SelectedItemTagModel?
    
    public var removeAction: (() -> Void)?
    
    @IBAction func removeAction(_ sender: Any) {
        self.removeAction?()
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        bgView.layer.cornerRadius = 10
        bgView.backgroundColor = trpTheme.color.tripianLightGrey
        bgView.layer.borderWidth = 0
        label.font = trpTheme.font.header2
        label.textColor = trpTheme.color.tripianBlack
    }
}
