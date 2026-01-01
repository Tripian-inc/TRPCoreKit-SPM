//
//  TRPTimelineManualPoiCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 31.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit
import SDWebImage
import TRPFoundationKit

protocol TRPTimelineManualPoiCellDelegate: AnyObject {
    func manualPoiCellDidTapChangeTime(_ cell: TRPTimelineManualPoiCell, segment: TRPTimelineSegment)
    func manualPoiCellDidTapRemove(_ cell: TRPTimelineManualPoiCell, segment: TRPTimelineSegment)
    func manualPoiCellDidTapCell(_ cell: TRPTimelineManualPoiCell, segment: TRPTimelineSegment, poi: TRPPoi?)
}

class TRPTimelineManualPoiCell: UITableViewCell {

    static let reuseIdentifier = "TRPTimelineManualPoiCell"

    weak var delegate: TRPTimelineManualPoiCellDelegate?

    private var segment: TRPTimelineSegment?
    private var poi: TRPPoi?

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
        label.textColor = ColorSet.primaryText.uiColor
        label.textAlignment = .center
        label.layer.cornerRadius = 16
        label.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor
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

    private let poiImageView: UIImageView = {
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

    // Rating stack
    private let ratingStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()

    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratBold.font(12)
        label.textColor = ColorSet.fg.uiColor
        return label
    }()

    private let starIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = TRPImageController().getImage(inFramework: "ic_rating_star", inApp: nil)
        imageView.tintColor = ColorSet.ratingStar.uiColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let reviewLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratRegular.font(12)
        label.textColor = ColorSet.fgWeak.uiColor
        return label
    }()

    private let categoryBadge: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.bgBlue.uiColor
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        return view
    }()

    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(10)
        label.textColor = ColorSet.fgBlue.uiColor
        return label
    }()

    // Action buttons container
    private let actionButtonsStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()

    private lazy var changeTimeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(TRPImageController().getImage(inFramework: "ic_change_time", inApp: nil), for: .normal)
        button.addTarget(self, action: #selector(changeTimeButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var removeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(TRPImageController().getImage(inFramework: "ic_remove_step", inApp: nil), for: .normal)
        button.addTarget(self, action: #selector(removeButtonTapped), for: .touchUpInside)
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

        contentView.addSubview(timeLabel)
        contentView.addSubview(verticalLineView)
        contentView.addSubview(containerView)

        containerView.addSubview(poiImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(actionButtonsStack)
        containerView.addSubview(rightContentStackView)

        // Build rating horizontal stack
        ratingStackView.addArrangedSubview(ratingLabel)
        ratingStackView.addArrangedSubview(starIcon)
        ratingStackView.addArrangedSubview(reviewLabel)

        // Build category badge
        categoryBadge.addSubview(categoryLabel)

        // Build action buttons stack
        actionButtonsStack.addArrangedSubview(changeTimeButton)
        actionButtonsStack.addArrangedSubview(removeButton)

        // Build right content vertical stack (below title)
        rightContentStackView.addArrangedSubview(ratingStackView)
        rightContentStackView.addArrangedSubview(categoryBadge)

        setupConstraints()
        setupTapGesture()
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

            // POI Image
            poiImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            poiImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            poiImageView.widthAnchor.constraint(equalToConstant: 80),
            poiImageView.heightAnchor.constraint(equalToConstant: 80),

            // Title Label - top right area
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: poiImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: actionButtonsStack.leadingAnchor, constant: -8),

            // Action buttons stack - fixed to right, aligned with title
            actionButtonsStack.topAnchor.constraint(equalTo: containerView.topAnchor),
            actionButtonsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            // Button sizes
            changeTimeButton.widthAnchor.constraint(equalToConstant: 28),
            changeTimeButton.heightAnchor.constraint(equalToConstant: 28),
            removeButton.widthAnchor.constraint(equalToConstant: 28),
            removeButton.heightAnchor.constraint(equalToConstant: 28),

            // Right Content Stack View - below title
            rightContentStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            rightContentStackView.leadingAnchor.constraint(equalTo: poiImageView.trailingAnchor, constant: 12),
            rightContentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            rightContentStackView.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor),

            // Star icon size
            starIcon.widthAnchor.constraint(equalToConstant: 12),
            starIcon.heightAnchor.constraint(equalToConstant: 12),

            // Category label inside badge
            categoryLabel.topAnchor.constraint(equalTo: categoryBadge.topAnchor, constant: 4),
            categoryLabel.bottomAnchor.constraint(equalTo: categoryBadge.bottomAnchor, constant: -4),
            categoryLabel.leadingAnchor.constraint(equalTo: categoryBadge.leadingAnchor, constant: 8),
            categoryLabel.trailingAnchor.constraint(equalTo: categoryBadge.trailingAnchor, constant: -8),
        ])
    }

    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        containerView.addGestureRecognizer(tapGesture)
        containerView.isUserInteractionEnabled = true
    }

    // MARK: - Configuration
    func configure(with segment: TRPTimelineSegment, poi: TRPPoi?) {
        self.segment = segment
        self.poi = poi

        // Configure title from POI or segment
        titleLabel.text = poi?.name ?? segment.title ?? ""

        // Configure time from segment
        if let startDate = segment.startDate, let endDate = segment.endDate {
            let startTime = formatTime(from: startDate)
            let endTime = formatTime(from: endDate)
            timeLabel.text = "\(startTime) - \(endTime)"
        }

        // Configure image from POI
        if let imageUrl = poi?.image?.url {
            poiImageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: nil)
        } else {
            poiImageView.image = nil
        }

        // Configure rating
        if let rating = poi?.rating {
            ratingLabel.text = String(format: "%.1f", rating).replacingOccurrences(of: ".", with: ",")
            ratingStackView.isHidden = false

            if let ratingCount = poi?.ratingCount {
                reviewLabel.text = "\(ratingCount.formattedWithSeparator) opiniones"
            } else {
                reviewLabel.text = ""
            }
        } else {
            ratingStackView.isHidden = true
        }

        // Configure category
        if let firstCategory = poi?.categories.first {
            categoryLabel.text = firstCategory.name
            categoryBadge.isHidden = false
        } else {
            categoryLabel.text = "Punto de interés"
            categoryBadge.isHidden = false
        }
    }

    // MARK: - Configuration with Pre-computed Data

    /// Configure cell with pre-computed ManualPoiCellData
    func configure(with cellData: ManualPoiCellData) {
        self.segment = cellData.segment
        self.poi = cellData.poi

        // Title (pre-computed)
        titleLabel.text = cellData.title

        // Time range (pre-computed)
        timeLabel.text = cellData.timeRange

        // Image
        if let imageUrl = cellData.imageUrl {
            poiImageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: nil)
        } else {
            poiImageView.image = nil
        }

        // Configure rating
        if let rating = cellData.rating {
            ratingLabel.text = String(format: "%.1f", rating).replacingOccurrences(of: ".", with: ",")
            ratingStackView.isHidden = false

            if let ratingCount = cellData.ratingCount {
                reviewLabel.text = "\(ratingCount.formattedWithSeparator) opiniones"
            } else {
                reviewLabel.text = ""
            }
        } else {
            ratingStackView.isHidden = true
        }

        // Configure category
        if let categoryName = cellData.categoryName, !categoryName.isEmpty {
            categoryLabel.text = categoryName
            categoryBadge.isHidden = false
        } else {
            categoryLabel.text = "Punto de interés"
            categoryBadge.isHidden = false
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

    // MARK: - Actions
    @objc private func changeTimeButtonTapped() {
        guard let segment = segment else { return }
        delegate?.manualPoiCellDidTapChangeTime(self, segment: segment)
    }

    @objc private func removeButtonTapped() {
        guard let segment = segment else { return }
        delegate?.manualPoiCellDidTapRemove(self, segment: segment)
    }

    @objc private func cellTapped() {
        guard let segment = segment else { return }
        delegate?.manualPoiCellDidTapCell(self, segment: segment, poi: poi)
    }
}
