////
////  ActivityListingCell.swift
////  TRPCoreKit
////
////  Created by Cem Çaygöz on 26.12.2024.
////  Copyright © 2024 Tripian Inc. All rights reserved.
////
//
//import UIKit
//import SDWebImage
//import TRPFoundationKit
//
//class ActivityListingCell: UITableViewCell {
//
//    static let reuseIdentifier = "ActivityListingCell"
//
//    // MARK: - UI Components
//    private let containerView: UIView = {
//        let view = UIView()
//        view.translatesAutoresizingMaskIntoConstraints = false
//        view.backgroundColor = .white
//        view.layer.cornerRadius = 8
//        view.layer.borderWidth = 1
//        view.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor
//        view.clipsToBounds = false
//        return view
//    }()
//
//    private let activityImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        imageView.contentMode = .scaleAspectFill
//        imageView.clipsToBounds = true
//        imageView.layer.cornerRadius = 8
//        imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
//        imageView.backgroundColor = ColorSet.neutral100.uiColor
//        return imageView
//    }()
//
//    private let titleLabel: UILabel = {
//        let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.font = FontSet.montserratSemiBold.font(16)
//        label.textColor = ColorSet.fg.uiColor
//        label.numberOfLines = 2
//        return label
//    }()
//
//    private let categoryIcon: UIImageView = {
//        let imageView = UIImageView()
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        imageView.image = TRPImageController().getImage(inFramework: "ic_category", inApp: nil)
//        imageView.tintColor = ColorSet.fgWeak.uiColor
//        imageView.contentMode = .scaleAspectFit
//        return imageView
//    }()
//
//    private let categoryLabel: UILabel = {
//        let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.font = FontSet.montserratLight.font(14)
//        label.textColor = ColorSet.fgWeak.uiColor
//        return label
//    }()
//
//    private let durationIcon: UIImageView = {
//        let imageView = UIImageView()
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        imageView.image = TRPImageController().getImage(inFramework: "ic_clock", inApp: nil)
//        imageView.tintColor = ColorSet.fgWeak.uiColor
//        imageView.contentMode = .scaleAspectFit
//        return imageView
//    }()
//
//    private let durationLabel: UILabel = {
//        let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.font = FontSet.montserratLight.font(14)
//        label.textColor = ColorSet.fgWeak.uiColor
//        return label
//    }()
//
//    private let ratingStackView: UIStackView = {
//        let stackView = UIStackView()
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        stackView.axis = .horizontal
//        stackView.spacing = 4
//        stackView.alignment = .center
//        return stackView
//    }()
//
//    private let starIcon: UIImageView = {
//        let imageView = UIImageView()
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        imageView.image = UIImage(systemName: "star.fill")
//        imageView.tintColor = ColorSet.yellow.uiColor
//        imageView.contentMode = .scaleAspectFit
//        return imageView
//    }()
//
//    private let ratingLabel: UILabel = {
//        let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.font = FontSet.montserratMedium.font(14)
//        label.textColor = ColorSet.fg.uiColor
//        return label
//    }()
//
//    private let reviewCountLabel: UILabel = {
//        let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.font = FontSet.montserratLight.font(12)
//        label.textColor = ColorSet.fgWeak.uiColor
//        return label
//    }()
//
//    private let priceLabel: UILabel = {
//        let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.font = FontSet.montserratSemiBold.font(16)
//        label.textColor = ColorSet.primary.uiColor
//        label.textAlignment = .right
//        return label
//    }()
//
//    private let distanceLabel: UILabel = {
//        let label = UILabel()
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.font = FontSet.montserratLight.font(12)
//        label.textColor = ColorSet.fgWeak.uiColor
//        label.textAlignment = .right
//        return label
//    }()
//
//    // MARK: - Initialization
//    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        setupUI()
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    // MARK: - Setup
//    private func setupUI() {
//        selectionStyle = .none
//        contentView.backgroundColor = .white
//        contentView.addSubview(containerView)
//
//        containerView.addSubview(activityImageView)
//        containerView.addSubview(titleLabel)
//        containerView.addSubview(categoryIcon)
//        containerView.addSubview(categoryLabel)
//        containerView.addSubview(durationIcon)
//        containerView.addSubview(durationLabel)
//        containerView.addSubview(ratingStackView)
//        containerView.addSubview(priceLabel)
//        containerView.addSubview(distanceLabel)
//
//        ratingStackView.addArrangedSubview(starIcon)
//        ratingStackView.addArrangedSubview(ratingLabel)
//        ratingStackView.addArrangedSubview(reviewCountLabel)
//
//        NSLayoutConstraint.activate([
//            // Container View
//            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
//            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
//            containerView.heightAnchor.constraint(equalToConstant: 120),
//
//            // Activity Image
//            activityImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
//            activityImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
//            activityImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
//            activityImageView.widthAnchor.constraint(equalToConstant: 100),
//
//            // Title Label
//            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
//            titleLabel.leadingAnchor.constraint(equalTo: activityImageView.trailingAnchor, constant: 12),
//            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
//
//            // Category Icon & Label
//            categoryIcon.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
//            categoryIcon.leadingAnchor.constraint(equalTo: activityImageView.trailingAnchor, constant: 12),
//            categoryIcon.widthAnchor.constraint(equalToConstant: 14),
//            categoryIcon.heightAnchor.constraint(equalToConstant: 14),
//
//            categoryLabel.centerYAnchor.constraint(equalTo: categoryIcon.centerYAnchor),
//            categoryLabel.leadingAnchor.constraint(equalTo: categoryIcon.trailingAnchor, constant: 4),
//
//            // Duration Icon & Label
//            durationIcon.centerYAnchor.constraint(equalTo: categoryIcon.centerYAnchor),
//            durationIcon.leadingAnchor.constraint(equalTo: categoryLabel.trailingAnchor, constant: 12),
//            durationIcon.widthAnchor.constraint(equalToConstant: 14),
//            durationIcon.heightAnchor.constraint(equalToConstant: 14),
//
//            durationLabel.centerYAnchor.constraint(equalTo: durationIcon.centerYAnchor),
//            durationLabel.leadingAnchor.constraint(equalTo: durationIcon.trailingAnchor, constant: 4),
//
//            // Rating Stack View
//            ratingStackView.topAnchor.constraint(equalTo: categoryIcon.bottomAnchor, constant: 8),
//            ratingStackView.leadingAnchor.constraint(equalTo: activityImageView.trailingAnchor, constant: 12),
//
//            starIcon.widthAnchor.constraint(equalToConstant: 14),
//            starIcon.heightAnchor.constraint(equalToConstant: 14),
//
//            // Price Label
//            priceLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
//            priceLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
//
//            // Distance Label
//            distanceLabel.bottomAnchor.constraint(equalTo: priceLabel.topAnchor, constant: -4),
//            distanceLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12)
//        ])
//    }
//
//    // MARK: - Configuration
//    func configure(with tour: TRPTourProduct) {
//        titleLabel.text = tour.name
//
//        // Set image
//        if let imageUrl = tour.image?.url, let url = URL(string: imageUrl) {
//            activityImageView.sd_setImage(with: url, placeholderImage: nil)
//        } else {
//            activityImageView.image = nil
//            activityImageView.backgroundColor = ColorSet.neutral100.uiColor
//        }
//
//        // Set category
//        categoryLabel.text = tour.getCategoryName()
//
//        // Set duration
//        if let duration = tour.duration {
//            let hours = duration / 60
//            let minutes = duration % 60
//            if hours > 0 {
//                durationLabel.text = "\(hours)h \(minutes)m"
//            } else {
//                durationLabel.text = "\(minutes)m"
//            }
//            durationIcon.isHidden = false
//            durationLabel.isHidden = false
//        } else {
//            durationIcon.isHidden = true
//            durationLabel.isHidden = true
//        }
//
//        // Set rating
//        if tour.isRatingAvailable() {
//            ratingLabel.text = String(format: "%.1f", tour.rating ?? 0)
//            reviewCountLabel.text = "(\(tour.ratingCount ?? 0))"
//            ratingStackView.isHidden = false
//        } else {
//            ratingStackView.isHidden = true
//        }
//
//        // Set price
//        if let price = tour.price {
//            priceLabel.text = "$\(price)"
//        } else {
//            priceLabel.text = ""
//        }
//
//        // Set distance
//        if let distance = tour.distance {
//            distanceLabel.text = String(format: "%.1f km", distance)
//        } else {
//            distanceLabel.text = ""
//        }
//    }
//}
