//
//  TravelCompanionsTableViewCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 11.09.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import UIKit

class TravelCompanionsTableViewCell: UITableViewCell {
    
    lazy var titleLabel: UILabel = {
        let lbl = UILabel(frame: CGRect.zero)
        lbl.font = UIFont.systemFont(ofSize: 16)
        lbl.textColor = TRPColor.darkGrey
        lbl.text = ""
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    lazy var iconImage: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(titleLabel)
        titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: 24).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        addSubview(iconImage)
        iconImage.widthAnchor.constraint(equalToConstant: 22).isActive = true
        iconImage.heightAnchor.constraint(equalToConstant: 22).isActive = true
        iconImage.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        iconImage.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
