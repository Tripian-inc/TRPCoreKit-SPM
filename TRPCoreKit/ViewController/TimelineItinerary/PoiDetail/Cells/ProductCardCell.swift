//
//  ProductCardCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - Product card cell extracted from TimelinePoiDetailViewController
//

import UIKit
import TRPFoundationKit
import TRPRestKit
import SDWebImage

class ProductCardCell: UICollectionViewCell {

    static let reuseIdentifier = "ProductCardCell"

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleToFill
        iv.clipsToBounds = true
        iv.backgroundColor = ColorSet.neutral100.uiColor
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratSemiBold.font(16)
        label.textColor = ColorSet.fg.uiColor
        label.numberOfLines = 2
        return label
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratBold.font(16)
        label.textColor = ColorSet.fg.uiColor
        label.textAlignment = .right
        label.numberOfLines = 0
        return label
    }()
    
    private let ratingStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 2
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()

    private let starImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = TRPImageController().getImage(inFramework: "ic_rating_star", inApp: nil)
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratBold.font(14)
        label.textColor = ColorSet.fg.uiColor
        return label
    }()
    
    private let reviewCountLabel: UILabel = {
        let label = UILabel()
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.fgWeak.uiColor
        return label
    }()
    
    private let durationStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()
    
    private let durationIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = TRPImageController().getImage(inFramework: "ic_duration", inApp: nil)
        imageView.tintColor = ColorSet.fgWeak.uiColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.fgWeak.uiColor
        return label
    }()

    private let freeCancellationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.greenAdvantage.uiColor
        label.text = CommonLocalizationKeys.localized(CommonLocalizationKeys.freeCancellation)
        return label
    }()

    private lazy var detailsStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        layer.cornerRadius = 8
        clipsToBounds = true

        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 8

        // Add rating subviews
        ratingStackView.addArrangedSubview(ratingLabel)
        ratingStackView.addArrangedSubview(starImageView)
        ratingStackView.addArrangedSubview(reviewCountLabel)
        
        // Setup duration stack view
        durationStackView.addArrangedSubview(durationIconImageView)
        durationStackView.addArrangedSubview(durationLabel)

        // Add to details stack
        detailsStackView.addArrangedSubview(ratingStackView)
        detailsStackView.addArrangedSubview(durationStackView)
        detailsStackView.addArrangedSubview(freeCancellationLabel)

        // Add to content view
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(detailsStackView)
        contentView.addSubview(priceLabel)

        NSLayoutConstraint.activate([
            // Cell width
            contentView.widthAnchor.constraint(equalToConstant: 253),

            // Image
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 152),

            // Title
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),

            // Details Stack (rating, duration, free cancellation)
            detailsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            detailsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            detailsStackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -8),

            // Rating Container
            ratingStackView.heightAnchor.constraint(equalToConstant: 18),
            
            // Star and duration icons size
            starImageView.widthAnchor.constraint(equalToConstant: 12),
            starImageView.heightAnchor.constraint(equalToConstant: 12),
            durationIconImageView.widthAnchor.constraint(equalToConstant: 16),
            durationIconImageView.heightAnchor.constraint(equalToConstant: 16),

            // Price - Below details stack with minimum 8px spacing
            priceLabel.topAnchor.constraint(equalTo: detailsStackView.bottomAnchor, constant: 8),
            priceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            priceLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8),
            priceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 8)
        ])
    }

    func configure(with product: TRPBookingProduct) {
        titleLabel.text = product.title

        // Configure Image
        if let imageUrlString = product.image, !imageUrlString.isEmpty, let url = URL(string: imageUrlString) {
            imageView.sd_setImage(with: url, placeholderImage: nil)
        } else {
            imageView.backgroundColor = ColorSet.neutral200.uiColor
            imageView.image = nil
        }

        // Configure Rating
        if let rating = product.rating, rating > 0 {
            ratingLabel.text = String(format: "%.1f", rating)
            if let ratingCount = product.ratingCount {
                reviewCountLabel.text = "\(ratingCount.formattedWithSeparator) " +
                    AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.opinions)
            }
            ratingStackView.isHidden = false
        } else {
            ratingStackView.isHidden = true
        }

        // Configure Duration
        if let duration = product.duration, !duration.isEmpty {
            durationLabel.text = duration
            durationLabel.isHidden = false
        } else {
            durationLabel.isHidden = true
        }

        // Configure Free Cancellation
        let hasNonRefundable = product.info.contains { $0.lowercased() == "non_refundable" }
        freeCancellationLabel.isHidden = hasNonRefundable
//        freeCancellationLabel.isHidden = true

        // Configure Price with "From:" prefix or "FREE" for zero price
        if let price = product.price, price == 0 {
            // Show "FREE" for zero price
            priceLabel.attributedText = NSAttributedString(
                string: CommonLocalizationKeys.localized(CommonLocalizationKeys.free),
                attributes: [
                    .font: FontSet.montserratBold.font(16),
                    .foregroundColor: ColorSet.primaryText.uiColor
                ]
            )
            return
        }

        let fromText = CommonLocalizationKeys.localized(CommonLocalizationKeys.from) + " "
        var priceText: String = ""

        if let price = product.price, let currency = product.currency {
            priceText = TRPCurrencyHelper.formatPrice(price, currency: currency)
        } else if let priceDescription = product.priceDescription {
            priceText = priceDescription
        }

        if priceText.isEmpty {
            priceLabel.text = ""
            return
        }

        let attributedString = NSMutableAttributedString()
        attributedString.append(NSAttributedString(
            string: fromText,
            attributes: [
                .font: FontSet.montserratMedium.font(14),
                .foregroundColor: ColorSet.primaryText.uiColor
            ]
        ))
        attributedString.append(NSAttributedString(
            string: priceText,
            attributes: [
                .font: FontSet.montserratBold.font(16),
                .foregroundColor: ColorSet.primaryText.uiColor
            ]
        ))
        priceLabel.attributedText = attributedString
    }

}
