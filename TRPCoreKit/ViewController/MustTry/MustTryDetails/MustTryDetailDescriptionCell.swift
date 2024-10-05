//
//  MustTryDetailDescriptionCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 9.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit



class MustTryDetailDescriptionCell: UITableViewCell {
    
    public lazy var label: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.black
        label.numberOfLines = 0
        
        return label
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    private func setup() {
        addSubview(label)
        label.topAnchor.constraint(equalTo: topAnchor, constant: 16).isActive = true
        label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16).isActive = true
        label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
    }
    
    
    
}
