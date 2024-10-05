//
//  ExperienceHeaderCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 23.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import UIKit

class ExperienceHeaderCell: UITableViewCell {

    public lazy var headerLabel: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = UIColor.black
        label.numberOfLines = 0
        label.text = "HEADER"
        label.textAlignment = .center
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
        addSubview(headerLabel)
        
        NSLayoutConstraint.activate([
        
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            headerLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            headerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 44),
            bottomAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8)
        ])
    }
    
    
}
