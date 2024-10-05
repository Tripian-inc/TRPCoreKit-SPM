//
//  ReservationUserInfoCell.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 8.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import UIKit
class ReservationUserInfoCell: ReservationBaseCell {

    public var inputText: UITextField = {
        let input = UITextField()
        input.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        input.textColor = UIColor.black //UIColor(red: 73.0/255.0, green: 73.0/255.0, blue: 73.0/255.0, alpha: 1.0);
        
        input.text = ""
        return input
    }()
    
    
    override func setupCustom(stack: UIStackView) {
        stack.addArrangedSubview(inputText)
        inputText.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
    }
    
    
}

