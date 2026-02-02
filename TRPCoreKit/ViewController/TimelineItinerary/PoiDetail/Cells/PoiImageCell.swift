//
//  PoiImageCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - Image gallery cell extracted from TimelinePoiDetailViewController
//

import UIKit
import TRPFoundationKit
import SDWebImage

class PoiImageCell: UICollectionViewCell {

    static let reuseIdentifier = "PoiImageCell"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = ColorSet.neutral100.uiColor
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func configure(with urlString: String) {
        if urlString.isEmpty {
            // Show placeholder for empty URL
            imageView.backgroundColor = ColorSet.neutral200.uiColor
            imageView.image = nil
        } else if let url = URL(string: urlString) {
            imageView.sd_setImage(with: url, placeholderImage: nil) { [weak self] image, error, _, _ in
                if error != nil || image == nil {
                    self?.imageView.backgroundColor = ColorSet.neutral200.uiColor
                }
            }
        }
    }
}
