//
//  CreateTripStepView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 17.06.2021.
//  Copyright © 2021 Tripian Inc. All rights reserved.
//

import UIKit

class CreateTripStepView: UIView {
    private let nibName = "CreateTripStepView"
    private let totalStepCount = 3
    
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    private func commonInit() {
        guard let view = loadNib(nibName: nibName) else {return}
        view.frame = self.bounds
        self.addSubview(view)
        
        bgView.roundCorners(corners: UIRectCorner.allCorners, radius: 15)
        bgView.backgroundColor = trpTheme.color.extraSub
        
    }
    
    public func setStep(step: String) {
        titleLabel.attributedText = createStepLabel(step: step)
    }
    
    private func createStepLabel(step: String) -> NSMutableAttributedString{
        let typeStepStyle = [NSAttributedString.Key.font: trpTheme.font.body2, NSAttributedString.Key.foregroundColor:trpTheme.color.tripianPrimary]
        let stepTextAttribute = NSMutableAttributedString(string: step, attributes: typeStepStyle)
        
        let totalStepStyle = [NSAttributedString.Key.font: trpTheme.font.body3, NSAttributedString.Key.foregroundColor: trpTheme.color.tripianTextPrimary]
        let totalStepAttribute = NSMutableAttributedString(string: " / \(totalStepCount)", attributes: totalStepStyle)
        stepTextAttribute.append(totalStepAttribute)
        return stepTextAttribute
    }
}
