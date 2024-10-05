//
//  CompanionCollectionReusableView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 13.06.2021.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import UIKit

class TagCollectionReusableView: UICollectionReusableView {
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = trpTheme.font.body2
        titleLabel.textColor = trpTheme.color.tripianTextPrimary
    }
}
