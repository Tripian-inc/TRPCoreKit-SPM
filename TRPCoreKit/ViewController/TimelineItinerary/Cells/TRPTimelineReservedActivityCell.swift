//
//  TRPTimelineReservedActivityCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 19.03.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import UIKit
import SDWebImage

protocol TRPTimelineReservedActivityCellDelegate: AnyObject {
    func reservedActivityCellDidTapReservation(_ cell: TRPTimelineReservedActivityCell, segment: TRPTimelineSegment)
    func reservedActivityCellDidTapRemove(_ cell: TRPTimelineReservedActivityCell, segment: TRPTimelineSegment)
    func reservedActivityCellDidTapChangeTime(_ cell: TRPTimelineReservedActivityCell, segment: TRPTimelineSegment)
    func reservedActivityCellDidTapCell(_ cell: TRPTimelineReservedActivityCell, segment: TRPTimelineSegment)
}

class TRPTimelineReservedActivityCell: UITableViewCell {

    static let reuseIdentifier = "TRPTimelineReservedActivityCell"

    weak var delegate: TRPTimelineReservedActivityCellDelegate?

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

    private let activityBadge: TRPPaddingLabel = {
        let label = TRPPaddingLabel(4, 4, 8, 8)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(10)
        label.textColor = ColorSet.fgGray.uiColor
        label.backgroundColor = ColorSet.neutral200.uiColor
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        label.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.activityBadge)
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

    private let priceRowContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
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

    private lazy var changeTimeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        let icon = TRPImageController().getImage(inFramework: "ic_change_time", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        button.setImage(icon, for: .normal)
        button.tintColor = ColorSet.primary.uiColor
        button.contentHorizontalAlignment = .trailing
        button.addTarget(self, action: #selector(changeTimeButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var removeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(TRPImageController().getImage(inFramework: "ic_remove_step", inApp: nil), for: .normal)
        button.contentHorizontalAlignment = .center
        button.addTarget(self, action: #selector(removeButtonTapped), for: .touchUpInside)
        return button
    }()

    // Action buttons container
    private let actionButtonsStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()

    // Stack view for right side content
    private let rightContentStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .leading
        stack.distribution = .fill
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
        containerView.addSubview(actionButtonsStack)
        containerView.addSubview(rightContentStackView)

        // Build action buttons stack
        actionButtonsStack.addArrangedSubview(changeTimeButton)
        actionButtonsStack.addArrangedSubview(removeButton)

        // Build duration horizontal stack
        durationStackView.addArrangedSubview(durationIcon)
        durationStackView.addArrangedSubview(durationLabel)

        // Build right content vertical stack (below title)
        rightContentStackView.addArrangedSubview(activityBadge)
        rightContentStackView.addArrangedSubview(durationStackView)
        rightContentStackView.addArrangedSubview(cancellationLabel)
        rightContentStackView.addArrangedSubview(priceRowContainer)
        rightContentStackView.addArrangedSubview(reservationButton)

        // Add tap gesture for cell selection
        let cellTapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        contentView.addGestureRecognizer(cellTapGesture)

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
            titleLabel.trailingAnchor.constraint(equalTo: actionButtonsStack.leadingAnchor, constant: -8),

            // Action buttons stack - fixed to right, aligned with title
            actionButtonsStack.topAnchor.constraint(equalTo: containerView.topAnchor),
            actionButtonsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            // Button sizes
            changeTimeButton.widthAnchor.constraint(equalToConstant: 36),
            changeTimeButton.heightAnchor.constraint(equalToConstant: 28),
            removeButton.widthAnchor.constraint(equalToConstant: 40),
            removeButton.heightAnchor.constraint(equalToConstant: 28),

            // Right Content Stack View - below title
            rightContentStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            rightContentStackView.leadingAnchor.constraint(equalTo: activityImageView.trailingAnchor, constant: 12),
            rightContentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            rightContentStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            durationIcon.widthAnchor.constraint(equalToConstant: 16),
            durationIcon.heightAnchor.constraint(equalToConstant: 16),

            // Price row container needs full width for right alignment
            priceRowContainer.widthAnchor.constraint(equalTo: rightContentStackView.widthAnchor),

            // Reservation button full width
            reservationButton.widthAnchor.constraint(equalTo: rightContentStackView.widthAnchor),
        ])
    }

    // MARK: - Configuration with Pre-computed Data

    /// Configure cell with pre-computed BookedActivityCellData
    func configure(with cellData: BookedActivityCellData) {
        self.segment = cellData.segment

        // Title (pre-computed)
        titleLabel.text = cellData.title

        // Time badge with order and time range
        let timeParts = cellData.timeRange.components(separatedBy: " - ")
        let startTime = timeParts.first ?? ""
        let endTime = timeParts.count > 1 ? timeParts[1] : ""
        timeBadgeView.configure(
            order: cellData.order,
            startTime: startTime,
            endTime: endTime,
            hasConflict: cellData.hasConflict,
            showTimeOverlapText: false  // BookedActivity never shows "Time Overlap" text
        )

        // Image
        if let imageUrl = cellData.imageUrl {
            activityImageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: nil)
        } else {
            activityImageView.image = nil
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
        configurePriceRow(with: cellData.price)
    }

    private func formatDuration(_ minutes: Double) -> String {
        return TimelineLocalizationKeys.formatDuration(minutes: Int(minutes))
    }

    private func configurePriceRow(with priceData: TRPSegmentActivityPrice?) {
        guard let price = priceData, price.value > 0 else {
            priceRowContainer.isHidden = true
            return
        }

        // Clear previous content
        priceRowContainer.subviews.forEach { $0.removeFromSuperview() }

        // Price row - "From" medium 14px + price bold 16px
        let priceRow = UIStackView()
        priceRow.translatesAutoresizingMaskIntoConstraints = false
        priceRow.axis = .horizontal
        priceRow.spacing = 4
        priceRow.alignment = .center

        // "From" label - medium 14px primaryText
        let fromLabel = UILabel()
        fromLabel.font = FontSet.montserratMedium.font(14)
        fromLabel.textColor = ColorSet.primaryText.uiColor
        fromLabel.text = CommonLocalizationKeys.localized(CommonLocalizationKeys.from)

        // Price label - bold 16px primaryText
        let priceLabel = UILabel()
        priceLabel.font = FontSet.montserratBold.font(16)
        priceLabel.textColor = ColorSet.primaryText.uiColor

        let priceText = TRPCurrencyHelper.formatPrice(price.value, currency: price.currency)

        if !priceText.isEmpty {
            priceLabel.text = priceText
            priceRow.addArrangedSubview(fromLabel)
            priceRow.addArrangedSubview(priceLabel)

            // Add priceRow to container, aligned to right
            priceRowContainer.addSubview(priceRow)
            NSLayoutConstraint.activate([
                priceRow.topAnchor.constraint(equalTo: priceRowContainer.topAnchor),
                priceRow.bottomAnchor.constraint(equalTo: priceRowContainer.bottomAnchor),
                priceRow.trailingAnchor.constraint(equalTo: priceRowContainer.trailingAnchor),
            ])
            priceRowContainer.isHidden = false
        }
    }

    // MARK: - Actions
    @objc private func reservationButtonTapped() {
        guard let segment = segment else { return }
        delegate?.reservedActivityCellDidTapReservation(self, segment: segment)
    }

    @objc private func changeTimeButtonTapped() {
        guard let segment = segment else { return }
        delegate?.reservedActivityCellDidTapChangeTime(self, segment: segment)
    }

    @objc private func removeButtonTapped() {
        guard let segment = segment else { return }
        delegate?.reservedActivityCellDidTapRemove(self, segment: segment)
    }

    @objc private func cellTapped() {
        guard let segment = segment else { return }
        delegate?.reservedActivityCellDidTapCell(self, segment: segment)
    }
}
