//
//  OverviewVCTableViewCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 17.06.2021.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import UIKit


struct OverviewVCTableViewCellModel {
    var title: String = ""
    var placeImage: URL?
    var matchPercent: String = ""
    var placeType: String = ""
}

class OverviewVCTableViewCell: UITableViewCell {

    @IBOutlet weak var placeImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var placeTypeLabel: UILabel!
    @IBOutlet weak var matchPercentLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        DispatchQueue.main.async {
            self.selectionStyle = .none
            self.setupPlaceImage()
            self.setupLabels()
            self.clearCell()
        }
    }
    public func configCell(with model: OverviewVCTableViewCellModel) {
        titleLabel.text = model.title
        matchPercentLabel.text = model.matchPercent
        placeTypeLabel.text = " - \(model.placeType)"
        if let image = model.placeImage {
            placeImage.sd_setImage(with: image)
        }
    }
    
    private func setupPlaceImage() {
        placeImage.layer.cornerRadius = 34
        placeImage.clipsToBounds = true
        placeImage.contentMode = UIView.ContentMode.scaleAspectFill
        placeImage.backgroundColor = TRPColor.darkGrey
    }
    
    private func setupLabels() {
        titleLabel.font = trpTheme.font.header2
        titleLabel.textColor = trpTheme.color.tripianBlack
        matchPercentLabel.font = trpTheme.font.body2
        matchPercentLabel.textColor = trpTheme.color.tripianPrimary
        placeTypeLabel.font = trpTheme.font.body3
        placeTypeLabel.textColor = TRPColor.lightGrey
    }

    private func clearCell() {
        titleLabel.text = ""
        matchPercentLabel.text = ""
        placeTypeLabel.text = ""
        placeImage.image = nil
    }
}
