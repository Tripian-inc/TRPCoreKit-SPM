//
//  AddPlaceCell2.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2021-05-23.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import Foundation
import SDWebImage
class AddPlaceCell2: UITableViewCell {
    
    @IBOutlet weak var placeName: UILabel!
    @IBOutlet weak var tripianCheck: UIImageView!
    @IBOutlet weak var placeImage: UIImageView!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var explaineLbl: UILabel!
    @IBOutlet weak var distanceLbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }
    
    private func commonInit() {
        contentView.backgroundColor = UIColor.clear
        placeImage.backgroundColor = trpTheme.color.tripianTextPrimary
        placeImage.layer.cornerRadius = 34
        placeImage.layer.masksToBounds = true
        placeName.textColor = trpTheme.color.tripianBlack
        placeName.font = trpTheme.font.header2
        placeName.numberOfLines = 2
        distanceLbl.textColor = trpTheme.color.tripianTextPrimary
        distanceLbl.font = trpTheme.font.body2
    }
    
    
    func config(_ model: AddPlaceCellModel) {
        placeName.text = model.title
        tripianCheck.isHidden = !model.isSuggestion

        if let explaine = model.explaineText {
            explaineLbl.isHidden = false
            explaineLbl.attributedText = explaine
        }else {
            explaineLbl.isHidden = true
        }

        if let url = model.image {
            placeImage.sd_setImage(with: url, completed: nil)
        }else {
            placeImage.image = nil
        }
        if let distance = model.distance, !distance.isEmpty {
            distanceLbl.isHidden = false
            distanceLbl.text = distance
        }else {
            distanceLbl.isHidden = true
        }
    }
 
    
    
}
