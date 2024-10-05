//
//  StayAddressCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 21.08.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import UIKit

class StayAddressCell: UITableViewCell {
    
    @IBOutlet weak var mainTitle: UILabel!
    @IBOutlet weak var subTitle: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor.clear
        mainTitle.font = trpTheme.font.body2
        mainTitle.textColor = trpTheme.color.tripianTextPrimary
        
        subTitle.font = trpTheme.font.body3
        subTitle.textColor = trpTheme.color.tripianTextPrimary
    }
    
    func configCell(model: StayAddressCellModel) {
        mainTitle.text = "\(model.title)"
        subTitle.text = "\(model.subTitle)"
    }
}
