//
//  UIButton+Extension.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 6.06.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import UIKit

extension UIButton {

    func leftImage(image: UIImage, renderMode:UIImage.RenderingMode) {
        self.setImage(image.withRenderingMode(renderMode), for: .normal)
        self.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: image.size.width / 2)
        self.contentHorizontalAlignment = .left
        self.imageView?.contentMode = .scaleAspectFit
    }

    func rightImage(image: UIImage, renderMode:UIImage.RenderingMode){
        self.setImage(image.withRenderingMode(renderMode), for: .normal)
        self.imageEdgeInsets = UIEdgeInsets(top: 0, left:image.size.width / 2, bottom: 0, right: 0)
        self.contentHorizontalAlignment = .right
        self.imageView?.contentMode = .scaleAspectFit
    }

    /// Apply / remove the "past-day disabled" visual state used by timeline cells when the
    /// day is in the past. Greys out the icon via `tintColor = fgWeaker` (forces
    /// `.alwaysTemplate` rendering on the current image so the tint is visible).
    ///
    /// IMPORTANT: `isEnabled` stays `true` deliberately. A disabled `UIControl` does NOT
    /// track touches, which means parent gesture recognizers (cell's own tap gesture,
    /// `UITableView`'s selection gesture) still fire when the button area is tapped. By
    /// keeping the button enabled, it tracks the touch and blocks those parent gestures
    /// — matching the canonical `UISwitch`-inside-a-cell behavior. The cell is responsible
    /// for short-circuiting the button's own action handler when in past-day mode (e.g.
    /// via an `isPastDayMode` flag), so tapping the button is a silent no-op.
    func setPastDayDisabled(_ disabled: Bool, originalTint: UIColor) {
        if disabled {
            if let image = image(for: .normal) {
                setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
            }
            tintColor = ColorSet.fgWeaker.uiColor
            alpha = 1.0
        } else {
            tintColor = originalTint
            alpha = 1.0
        }
    }
}
