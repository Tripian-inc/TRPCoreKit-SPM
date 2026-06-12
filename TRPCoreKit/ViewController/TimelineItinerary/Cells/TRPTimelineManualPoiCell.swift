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

    private var isPastDayMode: Bool = false
    private var poi: TRPPoi?

    // MARK: - UI Components

    private let timeBadgeView: TRPTimelineTimeBadgeView = {
        let view = TRPTimelineTimeBadgeView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let contentContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private let poiImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = ColorSet.bgDisabled.uiColor
        return imageView
    }()

    private let infoStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .leading
        stack.distribution = .fill
        return stack
    }()

    private let titleRow: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratSemiBold.font(16)
        label.textColor = ColorSet.primaryText.uiColor
        label.numberOfLines = 0
        return label
    }()

    private let actionButtonsStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 2
        stack.alignment = .center
        return stack
    }()

    private lazy var changeTimeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        let icon = TRPImageController().getImage(inFramework: "ic_change_time", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        button.setImage(icon, for: .normal)
        button.tintColor = ColorSet.primary.uiColor
        button.imageView?.contentMode = .scaleAspectFit
        button.contentVerticalAlignment = .center
        button.contentHorizontalAlignment = .trailing
        button.addTarget(self, action: #selector(changeTimeButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var removeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        let icon = TRPImageController().getImage(inFramework: "ic_remove_step", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        button.setImage(icon, for: .normal)
        button.tintColor = ColorSet.primary.uiColor
        button.imageView?.contentMode = .scaleAspectFit
        button.contentVerticalAlignment = .center
        button.contentHorizontalAlignment = .center
        button.addTarget(self, action: #selector(removeButtonTapped), for: .touchUpInside)
        return button
    }()

    private let ratingStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 0
        stack.alignment = .center
        return stack
    }()

    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratBold.font(14)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()

    private let ratingSpacer1: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let starIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = TRPImageController().getImage(inFramework: "ic_rating_star", inApp: nil)
        imageView.tintColor = ColorSet.ratingStar.uiColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let ratingSpacer2: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let reviewLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratLight.font(14)
        label.textColor = ColorSet.fgWeak.uiColor
        return label
    }()

    private let categoryBadge: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.neutral200.uiColor
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        return view
    }()

    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(12)
        label.textColor = ColorSet.fgGray.uiColor
        return label
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
        contentView.addSubview(contentContainer)

        contentContainer.addSubview(poiImageView)
        contentContainer.addSubview(infoStackView)

        titleRow.addSubview(titleLabel)
        titleRow.addSubview(actionButtonsStack)

        actionButtonsStack.addArrangedSubview(changeTimeButton)
        actionButtonsStack.addArrangedSubview(removeButton)

        ratingStackView.addArrangedSubview(ratingLabel)
        ratingStackView.addArrangedSubview(ratingSpacer1)
        ratingStackView.addArrangedSubview(starIcon)
        ratingStackView.addArrangedSubview(ratingSpacer2)
        ratingStackView.addArrangedSubview(reviewLabel)

        categoryBadge.addSubview(categoryLabel)

        infoStackView.addArrangedSubview(titleRow)
        infoStackView.addArrangedSubview(ratingStackView)
        infoStackView.addArrangedSubview(categoryBadge)

        setupConstraints()
        setupTapGesture()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            timeBadgeView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            timeBadgeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            contentContainer.topAnchor.constraint(equalTo: timeBadgeView.bottomAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: timeBadgeView.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            contentContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            poiImageView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            poiImageView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            poiImageView.widthAnchor.constraint(equalToConstant: 80),
            poiImageView.heightAnchor.constraint(equalToConstant: 80),

            infoStackView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            infoStackView.leadingAnchor.constraint(equalTo: poiImageView.trailingAnchor, constant: 16),
            infoStackView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -12),

            titleRow.widthAnchor.constraint(equalTo: infoStackView.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: titleRow.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: titleRow.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: actionButtonsStack.leadingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(equalTo: titleRow.bottomAnchor),

            actionButtonsStack.topAnchor.constraint(equalTo: titleRow.topAnchor),
            actionButtonsStack.trailingAnchor.constraint(equalTo: titleRow.trailingAnchor, constant: 12),

            changeTimeButton.widthAnchor.constraint(equalToConstant: 44),
            changeTimeButton.heightAnchor.constraint(equalToConstant: 32),
            removeButton.widthAnchor.constraint(equalToConstant: 44),
            removeButton.heightAnchor.constraint(equalToConstant: 32),

            ratingSpacer1.widthAnchor.constraint(equalToConstant: 2),
            ratingSpacer2.widthAnchor.constraint(equalToConstant: 4),

            starIcon.widthAnchor.constraint(equalToConstant: 14),
            starIcon.heightAnchor.constraint(equalToConstant: 14),

            categoryLabel.topAnchor.constraint(equalTo: categoryBadge.topAnchor, constant: 4),
            categoryLabel.bottomAnchor.constraint(equalTo: categoryBadge.bottomAnchor, constant: -4),
            categoryLabel.leadingAnchor.constraint(equalTo: categoryBadge.leadingAnchor, constant: 8),
            categoryLabel.trailingAnchor.constraint(equalTo: categoryBadge.trailingAnchor, constant: -8),
        ])

        contentContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true

        contentContainer.bottomAnchor.constraint(greaterThanOrEqualTo: infoStackView.bottomAnchor).isActive = true
    }

    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        tapGesture.delegate = TRPDisabledControlAwareTapDelegate.shared
        contentContainer.addGestureRecognizer(tapGesture)
        contentContainer.isUserInteractionEnabled = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        resetTextAndBorderDefaults()
        resetPastDayState()
    }

    private func resetTextAndBorderDefaults() {
        titleLabel.textColor = ColorSet.primaryText.uiColor
        ratingLabel.textColor = ColorSet.primaryText.uiColor
        reviewLabel.textColor = ColorSet.fgWeak.uiColor
        categoryLabel.textColor = ColorSet.fgGray.uiColor
    }

    /// Greys out action buttons but keeps them tappable; `isPastDayMode` makes their handlers no-op.
    func applyPastDayStyle() {
        isPastDayMode = true
        changeTimeButton.setPastDayDisabled(true, originalTint: ColorSet.primary.uiColor)
        removeButton.setPastDayDisabled(true, originalTint: ColorSet.primary.uiColor)
    }

    private func resetPastDayState() {
        isPastDayMode = false
        changeTimeButton.setPastDayDisabled(false, originalTint: ColorSet.primary.uiColor)
        removeButton.setPastDayDisabled(false, originalTint: ColorSet.primary.uiColor)
    }

    // MARK: - Configuration
    func configure(with segment: TRPTimelineSegment, poi: TRPPoi?, order: Int = 1) {
        self.segment = segment
        self.poi = poi

        titleLabel.text = poi?.name ?? segment.title ?? ""

        if let startDate = segment.startDate, let endDate = segment.endDate {
            let startTime = formatTime(from: startDate)
            let endTime = formatTime(from: endDate)
            timeBadgeView.configure(order: order, startTime: startTime, endTime: endTime)
        }

        if let imageUrl = poi?.image?.url {
            poiImageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: nil)
        } else {
            poiImageView.image = nil
        }

        ratingStackView.isHidden = true
//        if let rating = poi?.rating {
//            ratingLabel.text = String(format: "%.1f", rating).replacingOccurrences(of: ".", with: ",")
//            ratingStackView.isHidden = false
//
//            if let ratingCount = poi?.ratingCount {
//                let opinionsText = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.opinions)
//                reviewLabel.text = "\(ratingCount.formattedWithSeparator) \(opinionsText)"
//            } else {
//                reviewLabel.text = ""
//            }
//        } else {
//            ratingStackView.isHidden = true
//        }

        if let firstCategory = poi?.categories.first {
            categoryLabel.text = firstCategory.name
            categoryBadge.isHidden = false
        } else {
            categoryLabel.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.pointOfInterest)
            categoryBadge.isHidden = false
        }
    }

    // MARK: - Configuration with Pre-computed Data

    func configure(with cellData: ManualPoiCellData) {
        self.segment = cellData.segment
        self.poi = cellData.poi

        titleLabel.text = cellData.title

        let timeParts = cellData.timeRange.components(separatedBy: " - ")
        let startTime = timeParts.first ?? ""
        let endTime = timeParts.count > 1 ? timeParts[1] : ""
        timeBadgeView.configure(
            order: cellData.order,
            startTime: startTime,
            endTime: endTime,
            hasConflict: cellData.hasConflict,
            showTimeOverlapText: cellData.showTimeOverlapText
        )

        if let imageUrl = cellData.imageUrl {
            poiImageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: nil)
        } else {
            poiImageView.image = nil
        }

        ratingStackView.isHidden = true
//        if let rating = cellData.rating {
//            ratingLabel.text = String(format: "%.1f", rating).replacingOccurrences(of: ".", with: ",")
//            ratingStackView.isHidden = false
//
//            if let ratingCount = cellData.ratingCount {
//                let opinionsText = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.opinions)
//                reviewLabel.text = "\(ratingCount.formattedWithSeparator) \(opinionsText)"
//            } else {
//                reviewLabel.text = ""
//            }
//        } else {
//            ratingStackView.isHidden = true
//        }

        if let categoryName = cellData.categoryName, !categoryName.isEmpty {
            categoryLabel.text = categoryName
            categoryBadge.isHidden = false
        } else {
            categoryLabel.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.pointOfInterest)
            categoryBadge.isHidden = false
        }
    }

    private func formatTime(from dateString: String) -> String {
        let date = Date.fromString(dateString, format: "yyyy-MM-dd HH:mm:ss")
                   ?? Date.fromString(dateString, format: "yyyy-MM-dd HH:mm")

        guard let validDate = date else {
            return ""
        }
        return validDate.toString(format: "HH:mm") ?? ""
    }

    // MARK: - Actions
    @objc private func changeTimeButtonTapped() {
        guard !isPastDayMode, let segment = segment else { return }
        delegate?.manualPoiCellDidTapChangeTime(self, segment: segment)
    }

    @objc private func removeButtonTapped() {
        guard !isPastDayMode, let segment = segment else { return }
        delegate?.manualPoiCellDidTapRemove(self, segment: segment)
    }

    @objc private func cellTapped() {
        guard let segment = segment else { return }
        delegate?.manualPoiCellDidTapCell(self, segment: segment, poi: poi)
    }
}
