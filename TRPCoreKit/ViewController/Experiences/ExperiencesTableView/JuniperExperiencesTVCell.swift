//
//  JuniperExperiencesTVCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 26.08.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit


class JuniperExperiencesTVCell: UITableViewCell {
    @IBOutlet weak var imgTOur: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblFrom: UILabel!
    @IBOutlet weak var lblPrice: UILabel!
    @IBOutlet weak var lblPerson: UILabel!
    
    override func awakeFromNib() {
        imgTOur.layer.masksToBounds = true
        imgTOur.layer.cornerRadius = 12
        
        lblTitle.font = trpTheme.font.title2
        lblTitle.textColor = trpTheme.color.subMain
        
        lblFrom.font = trpTheme.font.caption
        lblFrom.textColor = trpTheme.color.subMain
        
        lblPrice.font = trpTheme.font.header3
        lblPrice.textColor = trpTheme.color.tripianPrimary
        
        lblPerson.font = trpTheme.font.caption
        lblPerson.textColor = trpTheme.color.subMain
    }
}
