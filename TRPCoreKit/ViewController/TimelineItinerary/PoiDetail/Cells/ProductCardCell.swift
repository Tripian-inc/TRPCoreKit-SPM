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
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = ColorSet.neutral100.uiColor
        iv.layer.cornerRadius = 8
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

    private let ratingContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratRegular.font(12)
        label.textColor = ColorSet.fgWeak.uiColor
        return label
    }()

    private let freeCancellationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratRegular.font(12)
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
        contentView.backgroundColor = .white

        // Add rating subviews
        ratingContainerView.addSubview(ratingLabel)
        ratingContainerView.addSubview(starImageView)

        // Add to details stack
        detailsStackView.addArrangedSubview(ratingContainerView)
        detailsStackView.addArrangedSubview(durationLabel)
        detailsStackView.addArrangedSubview(freeCancellationLabel)

        // Add to content view
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(detailsStackView)
        contentView.addSubview(priceLabel)

        NSLayoutConstraint.activate([
            // Cell width
            contentView.widthAnchor.constraint(equalToConstant: 280),

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
            ratingContainerView.heightAnchor.constraint(equalToConstant: 18),

            // Rating Label - Star ordering: RatingLabel - Star
            ratingLabel.leadingAnchor.constraint(equalTo: ratingContainerView.leadingAnchor),
            ratingLabel.centerYAnchor.constraint(equalTo: ratingContainerView.centerYAnchor),

            // Star Image
            starImageView.leadingAnchor.constraint(equalTo: ratingLabel.trailingAnchor, constant: 4),
            starImageView.centerYAnchor.constraint(equalTo: ratingContainerView.centerYAnchor),
            starImageView.trailingAnchor.constraint(equalTo: ratingContainerView.trailingAnchor),
            starImageView.widthAnchor.constraint(equalToConstant: 14),
            starImageView.heightAnchor.constraint(equalToConstant: 14),

            // Price - Bottom right corner
            priceLabel.topAnchor.constraint(greaterThanOrEqualTo: detailsStackView.bottomAnchor, constant: 8),
            priceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            priceLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            priceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 8)
        ])
    }

    func configure(with product: TRPBookingProduct) {
        titleLabel.text = product.title

        // Configure Image
        if let imageUrlString = product.image, !imageUrlString.isEmpty, let url = URL(string: imageUrlString) {
            imageView.sd_setImage(with: url, placeholderImage: nil) { [weak self] image, error, _, _ in
                if error != nil || image == nil {
                    self?.imageView.backgroundColor = ColorSet.neutral200.uiColor
                }
            }
        } else {
            imageView.backgroundColor = ColorSet.neutral200.uiColor
            imageView.image = nil
        }

        // Configure Rating
        if let rating = product.rating, rating > 0 {
            ratingLabel.text = String(format: "%.1f", rating)
            ratingContainerView.isHidden = false
        } else {
            ratingContainerView.isHidden = true
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

        // Configure Price with "From:" prefix
        let fromText = CommonLocalizationKeys.localized(CommonLocalizationKeys.from)

        if let price = product.price, let currency = product.currency {
            let priceText = "\(currency) \(String(format: "%.2f", price))"
            let fullText = "\(fromText) \(priceText)"

            let attributedString = NSMutableAttributedString(string: fullText)

            // "From:" -> Medium 14, fg
            attributedString.addAttribute(.font,
                                        value: FontSet.montserratMedium.font(14),
                                        range: NSRange(location: 0, length: fromText.count))
            attributedString.addAttribute(.foregroundColor,
                                        value: ColorSet.fg.uiColor,
                                        range: NSRange(location: 0, length: fromText.count))

            // Price (with space) -> Bold 16, fg
            let priceRange = NSRange(location: fromText.count, length: fullText.count - fromText.count)
            attributedString.addAttribute(.font,
                                        value: FontSet.montserratBold.font(16),
                                        range: priceRange)
            attributedString.addAttribute(.foregroundColor,
                                        value: ColorSet.fg.uiColor,
                                        range: priceRange)

            priceLabel.attributedText = attributedString
        } else if let priceDescription = product.priceDescription {
            let fullText = "\(fromText) \(priceDescription)"

            let attributedString = NSMutableAttributedString(string: fullText)

            // "From:" -> Medium 14, fg
            attributedString.addAttribute(.font,
                                        value: FontSet.montserratMedium.font(14),
                                        range: NSRange(location: 0, length: fromText.count))
            attributedString.addAttribute(.foregroundColor,
                                        value: ColorSet.fg.uiColor,
                                        range: NSRange(location: 0, length: fromText.count))

            // Price (with space) -> Bold 16, fg
            let priceRange = NSRange(location: fromText.count, length: fullText.count - fromText.count)
            attributedString.addAttribute(.font,
                                        value: FontSet.montserratBold.font(16),
                                        range: priceRange)
            attributedString.addAttribute(.foregroundColor,
                                        value: ColorSet.fg.uiColor,
                                        range: priceRange)

            priceLabel.attributedText = attributedString
        } else {
            priceLabel.text = ""
        }
    }
}
