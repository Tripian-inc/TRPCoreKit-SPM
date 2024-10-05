//
//  ExperienceDetailImageCell.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 19.09.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
import TRPUIKit
final class ExperienceDetailImageCell: UICollectionViewCell{
    
    lazy var topImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = TRPColor.darkGrey
        if let image = TRPImageController().getImage(inFramework: "image_loading", inApp: TRPAppearanceSettings.PoiDetail.imageLoadingImage) {
            imageView.image = image
        }
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(topImageView)
        
        NSLayoutConstraint.activate([
                topImageView.topAnchor.constraint(equalTo: topAnchor),
                topImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
                topImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
                topImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            ])
    }
    
    
}
