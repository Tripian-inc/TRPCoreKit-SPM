//
//  FavoritesTableViewCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 3.10.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

@objc(SPMFavoritesTableViewCell)
class FavoritesTableViewCell: UITableViewCell {
    
    public var index:Int?
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var placeImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        placeImage.backgroundColor = trpTheme.color.tripianTextPrimary
        placeImage.layer.cornerRadius = 32
        placeImage.clipsToBounds = true
        titleLbl.font = trpTheme.font.header2
        titleLbl.textColor = trpTheme.color.tripianBlack
        selectionStyle = .none
    }
    
}
