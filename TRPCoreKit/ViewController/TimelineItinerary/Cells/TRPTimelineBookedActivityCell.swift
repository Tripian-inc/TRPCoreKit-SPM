//
//  TRPTimelineBookedActivityCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 02.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit
import SDWebImage

protocol TRPTimelineBookedActivityCellDelegate: AnyObject {
    func bookedActivityCellDidTapMoreOptions(_ cell: TRPTimelineBookedActivityCell)
    func bookedActivityCellDidTapReservation(_ cell: TRPTimelineBookedActivityCell, segment: TRPTimelineSegment)
}

class TRPTimelineBookedActivityCell: UITableViewCell {

    static let reuseIdentifier = "TRPTimelineBookedActivityCell"

    weak var delegate: TRPTimelineBookedActivityCellDelegate?

    private var segment: TRPTimelineSegment?

    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.clipsToBounds = true
        return view
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.fgGreen.uiColor
        label.textAlignment = .center
        label.backgroundColor = ColorSet.bgGreen.uiColor
        label.layer.cornerRadius = 16
        label.layer.borderColor = ColorSet.green250.uiColor.cgColor
        label.layer.borderWidth = 2
        label.clipsToBounds = true
        return label
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
    
    private let confirmedBadge: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(12)
        label.textColor = ColorSet.fgGreen.uiColor
        label.backgroundColor = ColorSet.bgGreen.uiColor
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        // Text will be set dynamically in configure
        return label
    }()
    
    private let personIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = TRPImageController().getImage(inFramework: "ic_user", inApp: nil)
        imageView.tintColor = ColorSet.fgWeak.uiColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let personLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratLight.font(14)
        label.textColor = ColorSet.fg.uiColor
        return label
    }()
    
    private let cancellationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.greenAdvantage.uiColor
        return label
    }()

    private lazy var reservationButton: TRPButton = {
        let button = TRPButton(title: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.reservation), style: .primary, height: 40)
        button.addTarget(self, action: #selector(reservationButtonTapped), for: .touchUpInside)
        return button
    }()

    // Stack view for right side content (auto-adjusts height when elements are hidden)
    private let rightContentStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .leading
        stack.distribution = .fill
        return stack
    }()

    // Horizontal stack for person icon and label
    private let personStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        return stack
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

        contentView.addSubview(timeLabel)
        contentView.addSubview(verticalLineView)
        contentView.addSubview(containerView)

        containerView.addSubview(activityImageView)
        containerView.addSubview(rightContentStackView)

        // Build person horizontal stack
        personStackView.addArrangedSubview(personIcon)
        personStackView.addArrangedSubview(personLabel)

        // Build right content vertical stack
        rightContentStackView.addArrangedSubview(titleLabel)
        rightContentStackView.addArrangedSubview(confirmedBadge)
        rightContentStackView.addArrangedSubview(personStackView)
        rightContentStackView.addArrangedSubview(cancellationLabel)
        rightContentStackView.addArrangedSubview(reservationButton)

        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Time Label
            timeLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            timeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timeLabel.widthAnchor.constraint(equalToConstant: 120),
            timeLabel.heightAnchor.constraint(equalToConstant: 32),

            // Vertical Line
            verticalLineView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor),
            verticalLineView.leadingAnchor.constraint(equalTo: timeLabel.leadingAnchor, constant: 25),
            verticalLineView.widthAnchor.constraint(equalToConstant: 0.5),
            verticalLineView.bottomAnchor.constraint(equalTo: containerView.topAnchor),

            // Container View
            containerView.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 24),
            containerView.leadingAnchor.constraint(equalTo: timeLabel.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            // Activity Image
            activityImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            activityImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            activityImageView.widthAnchor.constraint(equalToConstant: 80),
            activityImageView.heightAnchor.constraint(equalToConstant: 80),

            // Right Content Stack View
            rightContentStackView.topAnchor.constraint(equalTo: containerView.topAnchor),
            rightContentStackView.leadingAnchor.constraint(equalTo: activityImageView.trailingAnchor, constant: 12),
            rightContentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            rightContentStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            // Element sizes within stack
            confirmedBadge.widthAnchor.constraint(equalToConstant: 90),
            confirmedBadge.heightAnchor.constraint(equalToConstant: 24),

            personIcon.widthAnchor.constraint(equalToConstant: 16),
            personIcon.heightAnchor.constraint(equalToConstant: 16),

            // Reservation button full width
            reservationButton.widthAnchor.constraint(equalTo: rightContentStackView.widthAnchor),
        ])
    }
    
    // MARK: - Configuration
    func configure(with segment: TRPTimelineSegment) {
        self.segment = segment

        guard let additionalData = segment.additionalData else {
            return
        }

        // Use additionalData for all information
        titleLabel.text = additionalData.title ?? segment.title ?? ""

        // Configure badge and button based on segment type
        if segment.segmentType == .reservedActivity {
            // Reserved activity - show "Reservation" badge and button
            confirmedBadge.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.reservation)
            confirmedBadge.textColor = ColorSet.fgOrange.uiColor
            confirmedBadge.backgroundColor = ColorSet.bgOrange.uiColor
            reservationButton.isHidden = false
        } else {
            // Booked activity - show "Confirmed" badge, hide button
            confirmedBadge.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.confirmed)
            confirmedBadge.textColor = ColorSet.fgGreen.uiColor
            confirmedBadge.backgroundColor = ColorSet.bgGreen.uiColor
            reservationButton.isHidden = true
        }
        
        // Configure time from additionalData
        if let startDatetime = additionalData.startDatetime,
           let endDatetime = additionalData.endDatetime {
            let startTime = formatTime(from: startDatetime)
            let endTime = formatTime(from: endDatetime)
            timeLabel.text = "\(startTime) - \(endTime)"
        }
        
        // Configure person count from additionalData
        let adults = additionalData.adultCount
        let childrenCount = additionalData.childCount

        let adultsText = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.adults)

        if childrenCount > 0 {
            let childText = childrenCount == 1
                ? TimelineLocalizationKeys.localized(TimelineLocalizationKeys.child)
                : TimelineLocalizationKeys.localized(TimelineLocalizationKeys.children)
            personLabel.text = "\(adults) \(adultsText), \(childrenCount) \(childText)"
        } else {
            personLabel.text = "\(adults) \(adultsText)"
        }
        
        // Configure image from additionalData
        if let imageUrl = additionalData.imageUrl {
            activityImageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: nil)
        }
        
        // Configure cancellation
        if let cancellation = additionalData.cancellation, !cancellation.isEmpty {
            cancellationLabel.text = cancellation
            cancellationLabel.isHidden = false
        } else {
            // Show default free cancellation text
            cancellationLabel.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.freeCancellation)
            cancellationLabel.isHidden = false
        }
    }
    
    private func formatTime(from dateString: String) -> String {
        // Try format with seconds first, then without seconds
        let date = Date.fromString(dateString, format: "yyyy-MM-dd HH:mm:ss")
                   ?? Date.fromString(dateString, format: "yyyy-MM-dd HH:mm")

        guard let validDate = date else {
            return ""
        }
        return validDate.toString(format: "HH:mm") ?? ""
    }

    private func formatDate(from dateString: String) -> String {
        // Try format with seconds first, then without seconds
        let date = Date.fromString(dateString, format: "yyyy-MM-dd HH:mm:ss")
                   ?? Date.fromString(dateString, format: "yyyy-MM-dd HH:mm")

        guard let validDate = date else {
            return ""
        }
        return validDate.toString(format: "dd/MM/yyyy HH:mm") ?? ""
    }

    // MARK: - Actions
    @objc private func reservationButtonTapped() {
        guard let segment = segment else { return }
        delegate?.bookedActivityCellDidTapReservation(self, segment: segment)
    }
}

