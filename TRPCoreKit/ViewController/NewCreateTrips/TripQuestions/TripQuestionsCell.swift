//
//  TripQuestionsCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2020-11-09.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
class TripQuestionsCell: UITableViewCell {
    
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var checkImage: UIImageView!
    @IBOutlet weak var iconImageWidth: NSLayoutConstraint!
    @IBOutlet weak var titleLabelLeadingConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        DispatchQueue.main.async {
            self.selectionStyle = .none
            self.removeIcon()
            
            self.titleLabel.font = trpTheme.font.body2
            self.titleLabel.textColor = trpTheme.color.tripianTextPrimary
            self.checkImage.image = CheckBoxCellState.unselected.getImage()
        }
    }
    
    override func prepareForReuse() {
        removeIcon()
    }
    
    func setSelectedState(isSelected: Bool) {
        let cellState: CheckBoxCellState = isSelected ? .selected : .unselected
        checkImage.image = cellState.getImage()
    }
    
    public func setTitle(_ text: String) {
        removeIcon()
        self.titleLabel.text = text
        self.setIcon()
    }
    
    func setSelect(_ select: Bool) {
        let cellState: CheckBoxCellState = select ? .selected : .unselected
        checkImage.image = cellState.getImage()
    }
    
    
    func setSubAnsert(_ status: Bool) {
        iconImage.isHidden = status
        if status {
            iconImageWidth.constant = 50
            iconImage.isHidden = true
        }
    }
    
    func removeIcon() {
        iconImageWidth.constant = 0
        iconImage.isHidden = true
    }
    
    func showIcon() {
        iconImageWidth.constant = 34
        iconImage.isHidden = false
    }
    
    func setIcon() {
        var img = ""
        switch titleLabel.text {
        case "Top Attractions":
            img = "icon_top_attraction"
        case "History & Landmarks":
            img = "icon_history"
        case "Museums":
            img = "icon_museum"
        case "Art":
            img = "icon_art"
        case "Hidden Gems":
            img = "icon_gems"
        case "Outdoor":
            img = "icon_top_attraction"
        default:
            img = ""
        }
        if !img.isEmpty {
            showIcon()
            iconImage.image = TRPImageController().getImage(inFramework: img, inApp: nil) ?? UIImage()
        }
    }
    
}

class TripQuestionsHeaderCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        DispatchQueue.main.async {
            self.titleLabel.font = trpTheme.font.body2
            self.titleLabel.textColor = trpTheme.color.extraMain
            self.titleLabel.numberOfLines = 0
        }
    }
}
