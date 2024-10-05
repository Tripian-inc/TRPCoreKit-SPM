//
//  CreateTripTextFieldRightAddRemoveButtons.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 5.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation

protocol CreateTripTextFieldRightAddRemoveButtonsDelegate: AnyObject {
    func countChanged(count: Int)
}

class CreateTripTextFieldRightAddRemoveButtonsCell: CreateTripTextFieldCell {
    @IBOutlet weak var lblRightText: UILabel!
    @IBOutlet weak var btnMinus: UIButton!
    @IBOutlet weak var btnPlus: UIButton!
    
    public var currentCount: Int = 0 {
        didSet {
            setCountLbl()
            self.countChangeAction?(currentCount)
        }
    }
    public var minimumCount = 0
    public var maximumCount = 20
    
    public var countChangeAction: ((Int)-> Void)?
    public weak var delegate: CreateTripTextFieldRightAddRemoveButtonsDelegate?
    
    override func setupCell() {
        super.setupCell()
        lblRightText.font = trpTheme.font.header2
        lblRightText.textColor = trpTheme.color.tripianBlack
        
        textField.isUserInteractionEnabled = false
        countChangeAction = nil
    }
        
    @IBAction func minusAction(_ sender: Any) {
        currentCount -= 1
    }
    
    @IBAction func plusAction(_ sender: Any) {
        currentCount += 1
    }
    
    private func changeBtnStatus(btn: UIButton, isEnable: Bool) {
        btn.isEnabled = isEnable
        btn.alpha = isEnable ? 1 : 0.5
    }
    
    private func setCountLbl() {
        lblRightText.text = "\(currentCount)"
        changeBtnStatus(btn: btnMinus, isEnable: currentCount != minimumCount)
        changeBtnStatus(btn: btnPlus, isEnable: currentCount != maximumCount)
    }
}
