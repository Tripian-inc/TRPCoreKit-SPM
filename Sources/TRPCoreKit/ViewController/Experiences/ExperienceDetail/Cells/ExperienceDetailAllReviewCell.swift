//
//  ExperienceDetailAllReviewCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 5.10.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPUIKit

class ExperienceDetailAllReviewCell: UITableViewCell {
    
    public lazy var button: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Read All Reviews", for: .normal)
        button.setTitleColor(TRPColor.pink, for: .normal)
        button.titleLabel!.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        //button.backgroundColor = TRPColor.pink
        //button.layer. = TRPColor.pink.cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        button.layer.cornerRadius = 20
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.isHidden = true
        addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.widthAnchor.constraint(equalToConstant: 200),
            button.heightAnchor.constraint(equalToConstant: 40),
            button.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
        ])
    }
    
}
