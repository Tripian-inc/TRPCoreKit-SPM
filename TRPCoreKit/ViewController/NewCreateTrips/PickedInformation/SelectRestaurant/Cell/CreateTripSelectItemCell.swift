//
//  CreateTripSelectItemCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 14.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

@objc(SPMCreateTripSelectItemCell)
class CreateTripSelectItemCell: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none
        self.label.textColor = trpTheme.color.tripianTextPrimary
        self.label.font = trpTheme.font.display.noBold()
    }
}
