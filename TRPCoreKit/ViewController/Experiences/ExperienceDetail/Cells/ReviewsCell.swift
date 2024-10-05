//
//  ReviewsCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 23.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

class ReviewsCell: UITableViewCell {
    
    
    private lazy var starUI: UIImageView = {
        let star = UIImageView()
        if let image = TRPImageController().getImage(inFramework: "star", inApp: nil) {
            star.image = image
        }
        star.contentMode = .scaleAspectFit
        star.translatesAutoresizingMaskIntoConstraints = false
        return star
    }()
    
    public lazy var starAndDateLbl: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = UIColor.black //TRPColor.darkGrey
        label.numberOfLines = 0
        label.text = "4.3"
        return label
    }()
    
    
    public lazy var reviewLbl: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = TRPColor.darkGrey
        label.numberOfLines = 0
        label.text = "4.3"
        return label
    }()
    
    public lazy var userNameLbl: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = TRPColor.darkGrey
        label.numberOfLines = 0
        label.text = "User Name"
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func setupView() {
        
        addSubview(starUI)
        addSubview(starAndDateLbl)
        addSubview(reviewLbl)
        addSubview(userNameLbl)
        
        
        NSLayoutConstraint.activate([
            
            starUI.leadingAnchor.constraint(equalTo: leadingAnchor , constant: 16),
            starUI.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            starUI.widthAnchor.constraint(equalToConstant: 16),
            starUI.heightAnchor.constraint(equalToConstant: 16),
            
            starAndDateLbl.leadingAnchor.constraint(equalTo: starUI.trailingAnchor, constant: 8),
            starAndDateLbl.centerYAnchor.constraint(equalTo: starUI.centerYAnchor),

            reviewLbl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            reviewLbl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            reviewLbl.topAnchor.constraint(equalTo: starUI.bottomAnchor, constant: 8),
            
            userNameLbl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            userNameLbl.topAnchor.constraint(equalTo: reviewLbl.bottomAnchor, constant: 8),
            
            bottomAnchor.constraint(equalTo: userNameLbl.bottomAnchor, constant: 16)
            
            
            ])
    }
    
    
    
}
