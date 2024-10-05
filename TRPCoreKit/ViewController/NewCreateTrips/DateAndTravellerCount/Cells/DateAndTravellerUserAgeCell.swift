//
//  DateAndTravellerUserAgeCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 30.06.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
class DateAndTravellerUserAgeCell: DateAndTravellerCell {
    
    public var inputText: UITextField = {
        let input = UITextField()
        input.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        input.textColor = UIColor.black //UIColor(red: 73.0/255.0, green: 73.0/255.0, blue: 73.0/255.0, alpha: 1.0);
        input.placeholder = "0"
        input.keyboardType = .numberPad
        input.translatesAutoresizingMaskIntoConstraints = false
        return input
    }()
    
    override func setupCustom(stack: UIStackView) {
        stack.addArrangedSubview(inputText)
        inputText.widthAnchor.constraint(equalToConstant: 280).isActive = true
    }
    
}
