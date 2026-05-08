//
//  POIListingCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 30.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit
import SDWebImage
import TRPFoundationKit

protocol POIListingCellDelegate: AnyObject {
    func poiListingCellDidTapAdd(_ cell: POIListingCell, poi: TRPPoi)
}

class POIListingCell: UITableViewCell {

    static let reuseIdentifier = "POIListingCell"
    private static let skeletonAnimationKey = "shimmer"

    weak var delegate: POIListingCellDelegate?
    private var poi: TRPPoi?

    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()

    private let poiImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 4
        imageView.backgroundColor = ColorSet.neutral100.uiColor
        return imageView
    }()

    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        return stack
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratSemiBold.font(16)
        label.textColor = ColorSet.fg.uiColor
        label.numberOfLines = 2
        return label
    }()

    private let ratingStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 2
        stack.alignment = .center
        return stack
    }()

    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratBold.font(14)
        label.textColor = ColorSet.fg.uiColor
        return label
    }()

    private let starImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = TRPImageController().getImage(inFramework: "ic_rating_star", inApp: nil)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let reviewCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratLight.font(14)
        label.textColor = ColorSet.fgWeak.uiColor
        return label
    }()
    
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        let image = TRPImageController().getImage(inFramework: "ic_add_to_plan", inApp: nil)
        button.setImage(image, for: .normal)
        button.tintColor = ColorSet.primary.uiColor
        button.imageView?.contentMode = .scaleAspectFit
        // Center 20x20 image in 32x32 button (6px padding on each side)
        button.imageEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Skeleton Placeholders
    // Mirrors `ActivityCardCell`'s skeleton pattern: greyed bars overlayed on the real
    // subviews while a fetch / local recompute is in flight, animated with a shimmer.

    private let imageSkeletonView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSet.lineWeak.uiColor
        view.layer.cornerRadius = 4
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

    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Cell Reuse
    override func prepareForReuse() {
        super.prepareForReuse()

        // Clear previous data
        poi = nil
        titleLabel.text = nil
        poiImageView.sd_cancelCurrentImageLoad()
        poiImageView.image = nil
        ratingLabel.text = nil
        reviewCountLabel.text = nil
        ratingStackView.isHidden = false
        stopSkeletonAnimation()
    }

    // MARK: - Setup
    private func setupCell() {
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(containerView)
        containerView.addSubview(poiImageView)
        containerView.addSubview(contentStackView)
        containerView.addSubview(addButton)
        // Skeleton overlays — invisible by default; toggled by `configureSkeleton()`.
        containerView.addSubview(imageSkeletonView)
        containerView.addSubview(titleSkeletonView)
        containerView.addSubview(subtitleSkeletonView)

        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(ratingStackView)

        ratingStackView.addArrangedSubview(ratingLabel)
        ratingStackView.addArrangedSubview(starImageView)
        ratingStackView.addArrangedSubview(reviewCountLabel)

        // Add extra 2px spacing before reviewCountLabel (total: 2 + 2 = 4px)
        ratingStackView.setCustomSpacing(4, after: starImageView)

        // Connect add button action
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container View
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // POI Image
            poiImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            poiImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            poiImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            poiImageView.widthAnchor.constraint(equalToConstant: 80),
            poiImageView.heightAnchor.constraint(equalToConstant: 80),

            // Content Stack View
            contentStackView.leadingAnchor.constraint(equalTo: poiImageView.trailingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: addButton.leadingAnchor),
            contentStackView.topAnchor.constraint(equalTo: poiImageView.topAnchor),

            // Add Button
            addButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            addButton.topAnchor.constraint(equalTo: poiImageView.topAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 32),
            addButton.heightAnchor.constraint(equalToConstant: 32),

            // Star Image
            starImageView.widthAnchor.constraint(equalToConstant: 12),
            starImageView.heightAnchor.constraint(equalToConstant: 12),

            // Skeleton: image placeholder over real image
            imageSkeletonView.topAnchor.constraint(equalTo: poiImageView.topAnchor),
            imageSkeletonView.leadingAnchor.constraint(equalTo: poiImageView.leadingAnchor),
            imageSkeletonView.widthAnchor.constraint(equalTo: poiImageView.widthAnchor),
            imageSkeletonView.heightAnchor.constraint(equalTo: poiImageView.heightAnchor),

            // Skeleton: title bar — full width next to image
            titleSkeletonView.topAnchor.constraint(equalTo: poiImageView.topAnchor, constant: 8),
            titleSkeletonView.leadingAnchor.constraint(equalTo: poiImageView.trailingAnchor, constant: 16),
            titleSkeletonView.trailingAnchor.constraint(equalTo: addButton.leadingAnchor, constant: -8),
            titleSkeletonView.heightAnchor.constraint(equalToConstant: 14),

            // Skeleton: subtitle bar — half width
            subtitleSkeletonView.topAnchor.constraint(equalTo: titleSkeletonView.bottomAnchor, constant: 10),
            subtitleSkeletonView.leadingAnchor.constraint(equalTo: poiImageView.trailingAnchor, constant: 16),
            subtitleSkeletonView.widthAnchor.constraint(equalToConstant: 120),
            subtitleSkeletonView.heightAnchor.constraint(equalToConstant: 10)
        ])
    }

    // MARK: - Configuration
    func configure(with poi: TRPPoi) {
        exitSkeletonMode()
        self.poi = poi

        titleLabel.text = poi.name

        // Set image with placeholder
        let placeholderImage = TRPImageController().getImage(inFramework: "placeholder_poi", inApp: nil)
        if let imageUrl = poi.image?.url, let url = URL(string: imageUrl) {
            poiImageView.sd_setImage(with: url, placeholderImage: placeholderImage)
        } else {
            poiImageView.image = placeholderImage
        }

        // Set rating
        if let rating = poi.rating, rating > 0 {
            ratingLabel.text = String(format: "%.1f", rating)
            ratingStackView.isHidden = false
        } else {
            ratingStackView.isHidden = true
        }

        // Set review count
        if let reviewCount = poi.ratingCount, reviewCount > 0 {
            let formattedCount = formatReviewCount(reviewCount)
            let opinionsText = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.opinions)
            reviewCountLabel.text = "\(formattedCount) \(opinionsText)"
        } else {
            reviewCountLabel.text = nil
        }
    }

    private func formatReviewCount(_ count: Int) -> String {
        if count >= 1000 {
            let thousands = Double(count) / 1000.0
            return String(format: "%.1fK", thousands)
        }
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = "."
        return numberFormatter.string(from: NSNumber(value: count)) ?? "\(count)"
    }

    // MARK: - Skeleton Mode

    /// Render the cell as a shimmering skeleton — used while a POI fetch / local
    /// recompute is in flight. Mirrors `ActivityCardCell.configureSkeleton()`.
    func configureSkeleton() {
        self.poi = nil
        isUserInteractionEnabled = false

        // Hide real content
        poiImageView.isHidden = true
        titleLabel.isHidden = true
        ratingStackView.isHidden = true
        addButton.isHidden = true

        // Show skeleton overlays
        imageSkeletonView.isHidden = false
        titleSkeletonView.isHidden = false
        subtitleSkeletonView.isHidden = false

        startSkeletonAnimation()
    }

    /// Reverse of `configureSkeleton()` — restores real subviews. Called from `configure(with:)`
    /// so a recycled skeleton cell snaps back cleanly when bound to a real POI.
    private func exitSkeletonMode() {
        stopSkeletonAnimation()
        isUserInteractionEnabled = true

        imageSkeletonView.isHidden = true
        titleSkeletonView.isHidden = true
        subtitleSkeletonView.isHidden = true

        poiImageView.isHidden = false
        titleLabel.isHidden = false
        addButton.isHidden = false
        // ratingStackView visibility is content-driven (set by configure based on rating presence).
    }

    private func startSkeletonAnimation() {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.4
        animation.toValue = 1.0
        animation.duration = 0.8
        animation.autoreverses = true
        animation.repeatCount = .infinity
        for view in [imageSkeletonView, titleSkeletonView, subtitleSkeletonView] {
            view.layer.add(animation, forKey: Self.skeletonAnimationKey)
        }
    }

    private func stopSkeletonAnimation() {
        for view in [imageSkeletonView, titleSkeletonView, subtitleSkeletonView] {
            view.layer.removeAnimation(forKey: Self.skeletonAnimationKey)
        }
    }

    // MARK: - Actions
    @objc private func addButtonTapped() {
        guard let poi = poi else { return }
        delegate?.poiListingCellDidTapAdd(self, poi: poi)
    }
}
