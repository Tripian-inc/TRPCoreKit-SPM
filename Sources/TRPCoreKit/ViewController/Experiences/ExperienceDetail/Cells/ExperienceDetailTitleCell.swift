//
//  ExperienceDetailTitleCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 21.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import UIKit
import TRPUIKit

class ExperienceDetailTitleAndReviewCell: UITableViewCell {

    public lazy var titleLabel: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.textColor = TRPColor.pink
        label.numberOfLines = 0
        label.text = "TİTLE"
        label.textAlignment = .center
        return label
    }()
    
    private lazy var starUI: UIImageView = {
        let star = UIImageView()
        if let image = TRPImageController().getImage(inFramework: "star", inApp: nil) {
            star.image = image
        }
        star.contentMode = .scaleAspectFit
        star.translatesAutoresizingMaskIntoConstraints = false
        return star
    }()
    
    private lazy var starAndRatingLbl: UILabel = {
        let label = UILabel();
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = UIColor.black
        label.numberOfLines = 0
        label.text = "4.3"
        return label
    }()
    
        
        
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(titleLabel)
        addSubview(starUI)
        addSubview(starAndRatingLbl)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            
            starUI.trailingAnchor.constraint(equalTo: starAndRatingLbl.leadingAnchor , constant: -8),
            starUI.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            starUI.widthAnchor.constraint(equalToConstant: 16),
            starUI.heightAnchor.constraint(equalToConstant: 16),
            
            starAndRatingLbl.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 4),
            starAndRatingLbl.centerYAnchor.constraint(equalTo: starUI.centerYAnchor),

            bottomAnchor.constraint(equalTo: starAndRatingLbl.bottomAnchor, constant: 0)
            ])
    }
    
    
    
    public func setStarAndRating(star: Double?, review: Int?) {
        let formattedStar = String(format: "%.1f", star ?? 0)
        starAndRatingLbl.text = "\(formattedStar)  •  \(review ?? 0) reviews"
        
        if review != nil && review! != 0 {
            starUI.isHidden = false
            starAndRatingLbl.isHidden = false
        }else {
            starUI.isHidden = true
            starAndRatingLbl.isHidden = true
        }
        
    }
    
    
}
