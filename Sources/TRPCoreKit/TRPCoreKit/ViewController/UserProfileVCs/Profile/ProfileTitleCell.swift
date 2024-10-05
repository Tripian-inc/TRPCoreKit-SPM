//
//  ProfileTitleCell.swift
//  TRPUserProfileKit
//
//  Created by Evren Yaşar on 17.09.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import UIKit
class ProfileTitleCell: UITableViewCell {
    
    lazy var titleLabel: UILabel = {
        let lbl = UILabel(frame: CGRect.zero)
        lbl.font = UIFont.systemFont(ofSize: 24, weight: UIFont.Weight.thin)
        lbl.textColor = UIColor.gray
        lbl.textAlignment = .center
        //lbl.text = "Necati Evren Yaşar"
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(titleLabel)
        titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 0).isActive = true
        titleLabel.heightAnchor.constraint(equalToConstant: 24).isActive = true
        titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
