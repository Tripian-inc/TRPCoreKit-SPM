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
    func bookedActivityCellDidTapRemove(_ cell: TRPTimelineBookedActivityCell, segment: TRPTimelineSegment)
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

    private let timeBadgeView: TRPTimelineTimeBadgeView = {
        let view = TRPTimelineTimeBadgeView()
        view.translatesAutoresizingMaskIntoConstraints = false
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

    private let durationIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = TRPImageController().getImage(inFramework: "ic_duration", inApp: nil)
        imageView.tintColor = ColorSet.fgWeak.uiColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratLight.font(14)
        label.textColor = ColorSet.fg.uiColor
        return label
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratSemiBold.font(14)
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

    private lazy var removeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(TRPImageController().getImage(inFramework: "ic_remove_step", inApp: nil), for: .normal)
        button.addTarget(self, action: #selector(removeButtonTapped), for: .touchUpInside)
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

    // Horizontal stack for duration icon and label
    private let durationStackView: UIStackView = {
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

        contentView.addSubview(timeBadgeView)
        contentView.addSubview(containerView)

        containerView.addSubview(activityImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(removeButton)
        containerView.addSubview(rightContentStackView)

        // Build person horizontal stack
        personStackView.addArrangedSubview(personIcon)
        personStackView.addArrangedSubview(personLabel)

        // Build duration horizontal stack
        durationStackView.addArrangedSubview(durationIcon)
        durationStackView.addArrangedSubview(durationLabel)

        // Build right content vertical stack (below title)
        rightContentStackView.addArrangedSubview(confirmedBadge)
        rightContentStackView.addArrangedSubview(personStackView)
        rightContentStackView.addArrangedSubview(durationStackView)
        rightContentStackView.addArrangedSubview(priceLabel)
        rightContentStackView.addArrangedSubview(cancellationLabel)
        rightContentStackView.addArrangedSubview(reservationButton)

        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Time Badge View
            timeBadgeView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            timeBadgeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            // Container View
            containerView.topAnchor.constraint(equalTo: timeBadgeView.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: timeBadgeView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            // Activity Image
            activityImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            activityImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            activityImageView.widthAnchor.constraint(equalToConstant: 80),
            activityImageView.heightAnchor.constraint(equalToConstant: 80),

            // Title Label - top right area
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: activityImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: removeButton.leadingAnchor, constant: -8),

            // Remove button - fixed to right, aligned with title
            removeButton.topAnchor.constraint(equalTo: containerView.topAnchor),
            removeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            removeButton.widthAnchor.constraint(equalToConstant: 28),
            removeButton.heightAnchor.constraint(equalToConstant: 28),

            // Right Content Stack View - below title
            rightContentStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            rightContentStackView.leadingAnchor.constraint(equalTo: activityImageView.trailingAnchor, constant: 12),
            rightContentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            rightContentStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            // Element sizes within stack
            confirmedBadge.widthAnchor.constraint(equalToConstant: 90),
            confirmedBadge.heightAnchor.constraint(equalToConstant: 24),

            personIcon.widthAnchor.constraint(equalToConstant: 16),
            personIcon.heightAnchor.constraint(equalToConstant: 16),

            durationIcon.widthAnchor.constraint(equalToConstant: 16),
            durationIcon.heightAnchor.constraint(equalToConstant: 16),

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
            // Reserved activity - show "Reservation" badge, buttons, hide person count
            confirmedBadge.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.reservation)
            confirmedBadge.textColor = ColorSet.fgOrange.uiColor
            confirmedBadge.backgroundColor = ColorSet.bgOrange.uiColor
            reservationButton.isHidden = false
            removeButton.isHidden = false
            personStackView.isHidden = true
        } else {
            // Booked activity - show "Confirmed" badge, hide buttons, show person count
            confirmedBadge.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.confirmed)
            confirmedBadge.textColor = ColorSet.fgGreen.uiColor
            confirmedBadge.backgroundColor = ColorSet.bgGreen.uiColor
            reservationButton.isHidden = true
            removeButton.isHidden = true
            personStackView.isHidden = false
        }
        
        // Configure time badge from additionalData (order defaults to 0 for legacy method)
        if let startDatetime = additionalData.startDatetime,
           let endDatetime = additionalData.endDatetime {
            let startTime = formatTime(from: startDatetime)
            let endTime = formatTime(from: endDatetime)
            timeBadgeView.configure(order: 0, startTime: startTime, endTime: endTime)
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
            cancellationLabel.text = CommonLocalizationKeys.localized(CommonLocalizationKeys.freeCancellation)
            cancellationLabel.isHidden = false
        }

        // Configure duration
        if let duration = additionalData.duration, duration > 0 {
            durationLabel.text = formatDuration(duration)
            durationStackView.isHidden = false
        } else {
            durationStackView.isHidden = true
        }

        // Configure price
        if let price = additionalData.price, price.value > 0 {
            priceLabel.text = formatPrice(price)
            priceLabel.isHidden = false
        } else {
            priceLabel.isHidden = true
        }
    }

    // MARK: - Configuration with Pre-computed Data

    /// Configure cell with pre-computed BookedActivityCellData
    func configure(with cellData: BookedActivityCellData) {
        self.segment = cellData.segment

        // Title (pre-computed)
        titleLabel.text = cellData.title

        // Time badge with order and time range
        // Parse time range from "HH:mm - HH:mm" format
        let timeParts = cellData.timeRange.components(separatedBy: " - ")
        let startTime = timeParts.first ?? ""
        let endTime = timeParts.count > 1 ? timeParts[1] : ""
        timeBadgeView.configure(order: cellData.order, startTime: startTime, endTime: endTime)

        // Image
        if let imageUrl = cellData.imageUrl {
            activityImageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: nil)
        } else {
            activityImageView.image = nil
        }

        // Configure badge and buttons based on reservation status
        if cellData.isReserved {
            // Reserved activity - show "Reservation" badge, buttons, hide person count
            confirmedBadge.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.reservation)
            confirmedBadge.textColor = ColorSet.fgOrange.uiColor
            confirmedBadge.backgroundColor = ColorSet.bgOrange.uiColor
            reservationButton.isHidden = false
            removeButton.isHidden = false
            personStackView.isHidden = true
        } else {
            // Booked activity - show "Confirmed" badge, hide buttons, show person count
            confirmedBadge.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.confirmed)
            confirmedBadge.textColor = ColorSet.fgGreen.uiColor
            confirmedBadge.backgroundColor = ColorSet.bgGreen.uiColor
            reservationButton.isHidden = true
            removeButton.isHidden = true
            personStackView.isHidden = false
        }

        // Configure person count
        let adultsText = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.adults)
        if cellData.childCount > 0 {
            let childText = cellData.childCount == 1
                ? TimelineLocalizationKeys.localized(TimelineLocalizationKeys.child)
                : TimelineLocalizationKeys.localized(TimelineLocalizationKeys.children)
            personLabel.text = "\(cellData.adultCount) \(adultsText), \(cellData.childCount) \(childText)"
        } else {
            personLabel.text = "\(cellData.adultCount) \(adultsText)"
        }

        // Configure cancellation
        if let cancellation = cellData.cancellation, !cancellation.isEmpty {
            cancellationLabel.text = cancellation
            cancellationLabel.isHidden = false
        } else {
            cancellationLabel.text = CommonLocalizationKeys.localized(CommonLocalizationKeys.freeCancellation)
            cancellationLabel.isHidden = false
        }

        // Configure duration
        if let duration = cellData.duration, duration > 0 {
            durationLabel.text = formatDuration(duration)
            durationStackView.isHidden = false
        } else {
            durationStackView.isHidden = true
        }

        // Configure price
        if let price = cellData.price, price.value > 0 {
            priceLabel.text = formatPrice(price)
            priceLabel.isHidden = false
        } else {
            priceLabel.isHidden = true
        }
    }

    private func formatDuration(_ minutes: Double) -> String {
        return TimelineLocalizationKeys.formatDuration(minutes: Int(minutes))
    }

    private func formatPrice(_ price: TRPSegmentActivityPrice) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = price.currency

        if let formattedPrice = formatter.string(from: NSNumber(value: price.value)) {
            return formattedPrice
        }
        return "\(price.currency) \(String(format: "%.2f", price.value))"
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

    @objc private func removeButtonTapped() {
        guard let segment = segment else { return }
        delegate?.bookedActivityCellDidTapRemove(self, segment: segment)
    }
}

