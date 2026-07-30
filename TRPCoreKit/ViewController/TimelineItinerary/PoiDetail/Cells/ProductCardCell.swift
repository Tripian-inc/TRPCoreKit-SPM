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

    private let imageSkeletonView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSet.lineWeak.uiColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private let titleSkeletonView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSet.lineWeak.uiColor
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private let subtitleSkeletonView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSet.lineWeak.uiColor
        view.layer.cornerRadius = 3
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private let priceSkeletonView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSet.lineWeak.uiColor
        view.layer.cornerRadius = 3
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private static let skeletonAnimationKey = "ProductCardCellSkeletonPulse"

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

        ratingStackView.addArrangedSubview(ratingLabel)
        ratingStackView.addArrangedSubview(starImageView)
        ratingStackView.addArrangedSubview(reviewCountLabel)

        durationStackView.addArrangedSubview(durationIconImageView)
        durationStackView.addArrangedSubview(durationLabel)

        detailsStackView.addArrangedSubview(ratingStackView)
        detailsStackView.addArrangedSubview(durationStackView)
        detailsStackView.addArrangedSubview(freeCancellationLabel)

        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(detailsStackView)
        contentView.addSubview(priceLabel)
        contentView.addSubview(imageSkeletonView)
        contentView.addSubview(titleSkeletonView)
        contentView.addSubview(subtitleSkeletonView)
        contentView.addSubview(priceSkeletonView)

        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalToConstant: 253),

            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 152),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),

            detailsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            detailsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            detailsStackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -8),

            ratingStackView.heightAnchor.constraint(equalToConstant: 18),

            starImageView.widthAnchor.constraint(equalToConstant: 12),
            starImageView.heightAnchor.constraint(equalToConstant: 12),
            durationIconImageView.widthAnchor.constraint(equalToConstant: 16),
            durationIconImageView.heightAnchor.constraint(equalToConstant: 16),

            priceLabel.topAnchor.constraint(equalTo: detailsStackView.bottomAnchor, constant: 8),
            priceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            priceLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8),
            priceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 8),

            imageSkeletonView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageSkeletonView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageSkeletonView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageSkeletonView.heightAnchor.constraint(equalToConstant: 152),

            titleSkeletonView.topAnchor.constraint(equalTo: imageSkeletonView.bottomAnchor, constant: 12),
            titleSkeletonView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleSkeletonView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            titleSkeletonView.heightAnchor.constraint(equalToConstant: 14),

            subtitleSkeletonView.topAnchor.constraint(equalTo: titleSkeletonView.bottomAnchor, constant: 10),
            subtitleSkeletonView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            subtitleSkeletonView.widthAnchor.constraint(equalToConstant: 120),
            subtitleSkeletonView.heightAnchor.constraint(equalToConstant: 10),

            priceSkeletonView.topAnchor.constraint(equalTo: subtitleSkeletonView.bottomAnchor, constant: 18),
            priceSkeletonView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            priceSkeletonView.widthAnchor.constraint(equalToConstant: 60),
            priceSkeletonView.heightAnchor.constraint(equalToConstant: 10)
        ])
    }

    func configure(with product: TRPTourProduct) {
        exitSkeletonMode()

        titleLabel.text = product.name

        if let imageUrlString = product.image?.url, !imageUrlString.isEmpty, let url = URL(string: imageUrlString) {
            imageView.sd_setImage(with: url, placeholderImage: nil)
        } else {
            imageView.backgroundColor = ColorSet.neutral200.uiColor
            imageView.image = nil
        }

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

        if let duration = product.duration, duration > 0 {
            durationLabel.text = TimelineLocalizationKeys.formatDuration(minutes: duration)
            durationStackView.isHidden = false
        } else {
            durationStackView.isHidden = true
        }

        freeCancellationLabel.isHidden = !product.tags.contains { $0.lowercased() == "full_refundable" }

        guard let price = product.price, price > 0 else {
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
        let priceText = TRPCurrencyHelper.formatPrice(price, currency: product.currency ?? "EUR")

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

    /// Render the cell as a shimmering placeholder while a page is in flight.
    func configureSkeleton() {
        isUserInteractionEnabled = false

        imageView.isHidden = true
        titleLabel.isHidden = true
        detailsStackView.isHidden = true
        priceLabel.isHidden = true

        imageSkeletonView.isHidden = false
        titleSkeletonView.isHidden = false
        subtitleSkeletonView.isHidden = false
        priceSkeletonView.isHidden = false

        startSkeletonAnimation()
    }

    private func exitSkeletonMode() {
        stopSkeletonAnimation()
        isUserInteractionEnabled = true

        imageSkeletonView.isHidden = true
        titleSkeletonView.isHidden = true
        subtitleSkeletonView.isHidden = true
        priceSkeletonView.isHidden = true

        imageView.isHidden = false
        titleLabel.isHidden = false
        detailsStackView.isHidden = false
        priceLabel.isHidden = false
    }

    private func startSkeletonAnimation() {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.4
        animation.toValue = 1.0
        animation.duration = 0.8
        animation.autoreverses = true
        animation.repeatCount = .infinity
        for view in [imageSkeletonView, titleSkeletonView, subtitleSkeletonView, priceSkeletonView] {
            view.layer.add(animation, forKey: Self.skeletonAnimationKey)
        }
    }

    private func stopSkeletonAnimation() {
        for view in [imageSkeletonView, titleSkeletonView, subtitleSkeletonView, priceSkeletonView] {
            view.layer.removeAnimation(forKey: Self.skeletonAnimationKey)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopSkeletonAnimation()
    }

}
