//
//  PoiDetailActionsCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 27.10.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPUIKit
import UIKit
final class PoiDetailActionsCell: UITableViewCell {
    @IBOutlet weak var addRemoveButton: UIButton!
    @IBOutlet weak var replaceButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var navigationButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    
    @IBOutlet weak var explaineText: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.isHidden = true
        setupViews()
        layoutIfNeeded()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setupViews() {
        explaineText.text = "Replace"
        explaineText.font = trpTheme.font.body3
        explaineText.textColor = trpTheme.color.tripianTextPrimary
        explaineText.isHidden = true
        
        replaceButton.isHidden = true
        addRemoveButton.isHidden = false
    }
    
    
    
    func setAddRemoveStatus(_ status: AddRemovePoiStatus) {
        var inFramework: String = ""
        var inApp: String?
        switch status {
        case .add:
            inFramework = "poi_action_add2"
            inApp = TRPAppearanceSettings.Common.addButtonImage
        case .remove:
            inFramework = "poi_action_remove2"
            inApp = TRPAppearanceSettings.Common.removeButtonImage
        case .alternative:
            replaceButton.isHidden = false
            addRemoveButton.isHidden = true
//            inFramework = "poi_action_replace"
//            inApp = TRPAppearanceSettings.Common.alternativePoiButtonImage
            explaineText.isHidden = false
        }
        
        if let img = TRPImageController().getImage(inFramework: inFramework, inApp: inApp) {
            addRemoveButton.setImage(img, for: .normal)
        }
    }
    
    func setFavorite(_ isFavorite: Bool) {
        var inFramework: String = ""
        var inApp: String?
        
        if !isFavorite {
            inFramework = "ic_favorite"
            inApp = TRPAppearanceSettings.PoiDetail.favoritePoiImage
        }else {
            inFramework = "ic_fav_selected"
            inApp = TRPAppearanceSettings.PoiDetail.selectedFavoritePoiImage
        }
        
        if let img = TRPImageController().getImage(inFramework: inFramework, inApp: inApp) {
//            var tempImg = img
//            if isFavorite, let pinkIcon = img.maskWithColor(color: TRPColor.pink) {
//                tempImg =  pinkIcon
//            }
            favoriteButton.setImage(img, for: .normal)
        }
    }
}
