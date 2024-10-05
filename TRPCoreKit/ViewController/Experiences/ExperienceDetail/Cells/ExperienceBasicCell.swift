//
//  ExperienceBasicCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2020-11-07.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

class ExperienceBasicCell: UITableViewCell {

    public lazy var contentLabel: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = TRPColor.darkGrey
        label.numberOfLines = 0
        label.text = "Content"
        return label
    }()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        
        addSubview(contentLabel)
        contentLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16).isActive = true
        contentLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        contentLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
        self.bottomAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 8).isActive = true
        //contentLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8).isActive = true
    }
}
