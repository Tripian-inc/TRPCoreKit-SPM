//
//  ReservationExplainCell.swift
//  TRPProvider
//
//  Created by Evren Yaşar on 8.07.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import UIKit
class ReservationExplainCell: ReservationBaseCell {

    public var explainLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        label.textColor = UIColor.black //UIColor(red: 73.0/255.0, green: 73.0/255.0, blue: 73.0/255.0, alpha: 1.0);
        label.text = ""
        label.numberOfLines = 0
        return label
    }()
    
    
    override func setupCustom(stack: UIStackView) {
        stack.addArrangedSubview(explainLabel)
        explainLabel.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
    }
    
  
}
