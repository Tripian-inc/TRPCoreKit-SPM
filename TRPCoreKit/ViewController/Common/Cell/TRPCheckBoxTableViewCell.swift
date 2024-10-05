//
//  TRPCheckBoxTableViewCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 2020-12-14.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
class TRPCheckBoxTableViewCell: UITableViewCell {
    
    public var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = UIColor.black
        label.text = "Explaine"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    public var switchButton: UISwitch = {
        var switchButton = UISwitch()
        switchButton.translatesAutoresizingMaskIntoConstraints = false
        switchButton.isOn = true
        switchButton.isEnabled = true
        switchButton.isUserInteractionEnabled = true
        return switchButton
    }()
    
    var switchAction: ((_ isOn: Bool) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.isHidden = true
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(titleLabel)
        addSubview(switchButton)
        NSLayoutConstraint.activate([
            switchButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            switchButton.topAnchor.constraint(equalTo: topAnchor, constant: 8),

            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: switchButton.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            bottomAnchor.constraint(equalTo: switchButton.bottomAnchor, constant: 8)
        ])
    }
  
    
    
}
