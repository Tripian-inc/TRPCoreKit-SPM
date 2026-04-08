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
    func bookedActivityCellDidTapCell(_ cell: TRPTimelineBookedActivityCell, segment: TRPTimelineSegment)
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

    private let confirmedBadge: TRPPaddingLabel = {
        let label = TRPPaddingLabel(4, 4, 8, 8)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(10)
        label.textColor = ColorSet.fgGreen.uiColor
        label.backgroundColor = ColorSet.bgGreen.uiColor
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        label.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.confirmed)
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

    private let cancellationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.greenAdvantage.uiColor
        return label
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
        rightContentStackView.addArrangedSubview(cancellationLabel)

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
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            // Right Content Stack View - below title
            rightContentStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            rightContentStackView.leadingAnchor.constraint(equalTo: activityImageView.trailingAnchor, constant: 12),
            rightContentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            rightContentStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            personIcon.widthAnchor.constraint(equalToConstant: 16),
            personIcon.heightAnchor.constraint(equalToConstant: 16),

            durationIcon.widthAnchor.constraint(equalToConstant: 16),
            durationIcon.heightAnchor.constraint(equalToConstant: 16),
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
    }

    private func formatDuration(_ minutes: Double) -> String {
        return TimelineLocalizationKeys.formatDuration(minutes: Int(minutes))
    }

    // MARK: - Actions
    @objc private func cellTapped() {
        guard let segment = segment else { return }
        delegate?.bookedActivityCellDidTapCell(self, segment: segment)
    }
}
