//
//  ProfileLabelCell.swift
//  TRPUserProfileKit
//
//  Created by Evren Yaşar on 16.09.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import UIKit
import TRPUIKit
class ProfileLabelCell: UITableViewCell {
    lazy var label: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = TRPColor.darkGrey
        label.text = ""
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var labelPlaceholder:UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = label.font.withSize(12)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.gray
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(label)
        label.centerYAnchor.constraint(equalTo: bottomAnchor, constant: -20).isActive = true
        label.heightAnchor.constraint(equalToConstant: 24).isActive = true
        label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
        label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20).isActive = true
        
        addSubview(labelPlaceholder)
        labelPlaceholder.bottomAnchor.constraint(equalTo:label.topAnchor, constant:-10).isActive = true
        labelPlaceholder.leadingAnchor.constraint(equalTo:leadingAnchor,constant: 20).isActive = true
        labelPlaceholder.trailingAnchor.constraint(equalTo:trailingAnchor,constant: -20).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
