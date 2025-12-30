//
//  TRPTimelineActivityStepCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit
import SDWebImage

protocol TRPTimelineActivityStepCellDelegate: AnyObject {
    func activityStepCellDidTapMoreOptions(_ cell: TRPTimelineActivityStepCell)
    func activityStepCellDidTapReservation(_ cell: TRPTimelineActivityStepCell, step: TRPTimelineStep)
}

class TRPTimelineActivityStepCell: UITableViewCell {

    static let reuseIdentifier = "TRPTimelineActivityStepCell"

    weak var delegate: TRPTimelineActivityStepCellDelegate?

    private var step: TRPTimelineStep?

    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.clipsToBounds = true
        return view
    }()

    private let timeBadgeView: TRPTimelineTimeBadgeView = {
        let view = TRPTimelineTimeBadgeView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let verticalLineView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.lineWeak.uiColor
        return view
    }()
    
    private let activityImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 4
        imageView.backgroundColor = ColorSet.neutral100.uiColor
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratSemiBold.font(16)
        label.textColor = ColorSet.fg.uiColor
        label.numberOfLines = 2
        return label
    }()
    
    private let activityBadge: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Activity"
        label.font = FontSet.montserratMedium.font(12)
        label.textColor = ColorSet.fgGreen.uiColor
        label.backgroundColor = ColorSet.bgGreen.uiColor
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        return label
    }()
    
    private let ratingStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratLight.font(14)
        label.textColor = ColorSet.fgWeak.uiColor
        label.numberOfLines = 2
        return label
    }()

    private lazy var reservationButton: TRPButton = {
        let button = TRPButton(title: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.reservation), style: .primary, height: 40)
        button.addTarget(self, action: #selector(reservationButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupCell() {
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(timeBadgeView)
        contentView.addSubview(verticalLineView)
        contentView.addSubview(containerView)

        containerView.addSubview(activityImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(activityBadge)
        containerView.addSubview(ratingStack)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(reservationButton)

        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Time Badge View
            timeBadgeView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            timeBadgeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            timeBadgeView.widthAnchor.constraint(equalToConstant: 130),

            // Vertical Line
            verticalLineView.topAnchor.constraint(equalTo: timeBadgeView.bottomAnchor),
            verticalLineView.leadingAnchor.constraint(equalTo: timeBadgeView.leadingAnchor, constant: 25),
            verticalLineView.widthAnchor.constraint(equalToConstant: 0.5),
            verticalLineView.bottomAnchor.constraint(equalTo: containerView.topAnchor),

            // Container View
            containerView.topAnchor.constraint(equalTo: timeBadgeView.bottomAnchor, constant: 24),
            containerView.leadingAnchor.constraint(equalTo: timeBadgeView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            // Activity Image
            activityImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            activityImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            activityImageView.widthAnchor.constraint(equalToConstant: 80),
            activityImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: activityImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            
            // Activity Badge
            activityBadge.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            activityBadge.leadingAnchor.constraint(equalTo: activityImageView.trailingAnchor, constant: 12),
            activityBadge.widthAnchor.constraint(equalToConstant: 80),
            activityBadge.heightAnchor.constraint(equalToConstant: 24),
            
            // Rating Stack
            ratingStack.topAnchor.constraint(equalTo: activityBadge.bottomAnchor, constant: 6),
            ratingStack.leadingAnchor.constraint(equalTo: activityBadge.leadingAnchor),
            ratingStack.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -12),
            
            // Description Label
            descriptionLabel.topAnchor.constraint(equalTo: ratingStack.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: activityBadge.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

            // Reservation Button
            reservationButton.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 12),
            reservationButton.leadingAnchor.constraint(equalTo: activityImageView.trailingAnchor, constant: 12),
            reservationButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            reservationButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
        ])
    }
    
    // MARK: - Configuration
    func configure(with step: TRPTimelineStep, order: Int) {
        self.step = step

        guard let poi = step.poi else {
            return
        }

        // Configure time badge
        if let startTime = step.getStartTime(), let endTime = step.getEndTime() {
            timeBadgeView.configure(order: order, startTime: startTime, endTime: endTime, style: .activity)
        }

        // Configure title
        titleLabel.text = poi.name
        
        // Configure rating if available
        ratingStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if let rating = poi.rating {
            let ratingLabel = UILabel()
            ratingLabel.font = FontSet.montserratBold.font(14)
            ratingLabel.textColor = ColorSet.fg.uiColor
            ratingLabel.text = String(format: "%.1f", rating)
            
            let starIcon = UIImageView()
            starIcon.image = TRPImageController().getImage(inFramework: "ic_rating_star", inApp: nil)
            starIcon.tintColor = ColorSet.ratingStar.uiColor
            starIcon.translatesAutoresizingMaskIntoConstraints = false
            starIcon.widthAnchor.constraint(equalToConstant: 12).isActive = true
            starIcon.heightAnchor.constraint(equalToConstant: 12).isActive = true
            
            ratingStack.addArrangedSubview(ratingLabel)
            ratingStack.addArrangedSubview(starIcon)
            
            if let reviewCount = poi.ratingCount {
                let reviewLabel = UILabel()
                reviewLabel.font = FontSet.montserratLight.font(14)
                reviewLabel.textColor = ColorSet.fgWeak.uiColor
                reviewLabel.text = "(\(reviewCount) reviews)"
                ratingStack.addArrangedSubview(reviewLabel)
            }
        }
        
        // Configure description
        if let description = poi.description {
            descriptionLabel.text = description
            descriptionLabel.isHidden = false
        } else {
            descriptionLabel.isHidden = true
        }
        
        // Configure image
        if let image = poi.image {
            activityImageView.sd_setImage(with: URL(string: image.url), placeholderImage: nil)
        } else if let gallery = poi.gallery, let firstImage = gallery.compactMap({ $0 }).first {
            activityImageView.sd_setImage(with: URL(string: firstImage.url), placeholderImage: nil)
        }
    }

    // MARK: - Actions
    @objc private func reservationButtonTapped() {
        guard let step = step else { return }
        delegate?.activityStepCellDidTapReservation(self, step: step)
    }
}
