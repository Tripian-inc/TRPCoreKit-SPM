//
//  SelectCompanionCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 9.06.2021.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import UIKit

class SelectCompanionCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var checkImg: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.font = trpTheme.font.body2
        checkImg.image = CheckBoxCellState.unselected.getImage()
        self.selectionStyle = .none
    }
    
    func setSelectedState(isSelected: Bool) {
        let cellState: CheckBoxCellState = isSelected ? .selected : .unselected
        checkImg.image = cellState.getImage()
    }
    
    func setTravelCompanionStyle() {
        checkImg.isHidden = true
    }

}

enum CheckBoxCellState {
    case selected, unselected
    
    func getImage() -> UIImage? {
        var img = "btn_check_default"
        switch self {
        case .selected:
            img = "btn_check"
        case .unselected:
            img = "btn_check_default"
        }
        return TRPImageController().getImage(inFramework: img, inApp: nil)
    }
}
