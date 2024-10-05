//
//  ExperienceDetailCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 18.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit


class ExperienceDetailTextCell: UITableViewCell {
    
    public lazy var titleLabel: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = UIColor.black
        label.numberOfLines = 0
        label.text = "TİTLE"
        return label
    }()
    
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
        addSubview(titleLabel)
        titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        
        addSubview(contentLabel)
        contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8).isActive = true
        contentLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        contentLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
        self.bottomAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 8).isActive = true
        //contentLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8).isActive = true
    }
}
