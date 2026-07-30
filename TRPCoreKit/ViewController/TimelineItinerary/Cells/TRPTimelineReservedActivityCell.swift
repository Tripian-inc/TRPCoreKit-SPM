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

    /// Past-day mode: buttons stay enabled to consume touches, but their handlers no-op on this flag.
    private var isPastDayMode: Bool = false

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

    private let ratingStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 0
        stack.alignment = .center
        stack.isHidden = true
        return stack
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

    private let noLocationBadge: TRPPaddingLabel = {
        let label = TRPPaddingLabel(4, 4, 8, 8)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(10)
        label.textColor = ColorSet.infoIcon.uiColor
        label.backgroundColor = ColorSet.bgBlue.uiColor
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        label.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.noExactLocation)
        label.isHidden = true
        return label
    }()

    private let badgeStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
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

    private let actionButtonsStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()

    private let rightContentStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .leading
        stack.distribution = .fill
        return stack
    }()

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

        actionButtonsStack.addArrangedSubview(changeTimeButton)
        actionButtonsStack.addArrangedSubview(removeButton)

        durationStackView.addArrangedSubview(durationIcon)
        durationStackView.addArrangedSubview(durationLabel)

        badgeStackView.addArrangedSubview(activityBadge)
        badgeStackView.addArrangedSubview(noLocationBadge)

        rightContentStackView.addArrangedSubview(ratingStack)
        rightContentStackView.addArrangedSubview(badgeStackView)
        rightContentStackView.addArrangedSubview(durationStackView)
        rightContentStackView.addArrangedSubview(cancellationLabel)
        rightContentStackView.addArrangedSubview(priceRowContainer)
        rightContentStackView.addArrangedSubview(reservationButton)

        let cellTapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        cellTapGesture.delegate = TRPDisabledControlAwareTapDelegate.shared
        contentView.addGestureRecognizer(cellTapGesture)

        setupConstraints()
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            timeBadgeView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            timeBadgeView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            containerView.topAnchor.constraint(equalTo: timeBadgeView.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: timeBadgeView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            activityImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            activityImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            activityImageView.widthAnchor.constraint(equalToConstant: 80),
            activityImageView.heightAnchor.constraint(equalToConstant: 80),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: activityImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: actionButtonsStack.leadingAnchor, constant: -8),

            actionButtonsStack.topAnchor.constraint(equalTo: containerView.topAnchor),
            actionButtonsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            changeTimeButton.widthAnchor.constraint(equalToConstant: 36),
            changeTimeButton.heightAnchor.constraint(equalToConstant: 28),
            removeButton.widthAnchor.constraint(equalToConstant: 40),
            removeButton.heightAnchor.constraint(equalToConstant: 28),

            rightContentStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            rightContentStackView.leadingAnchor.constraint(equalTo: activityImageView.trailingAnchor, constant: 12),
            rightContentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            rightContentStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            durationIcon.widthAnchor.constraint(equalToConstant: 16),
            durationIcon.heightAnchor.constraint(equalToConstant: 16),

            priceRowContainer.widthAnchor.constraint(equalTo: rightContentStackView.widthAnchor),

            reservationButton.widthAnchor.constraint(equalTo: rightContentStackView.widthAnchor),
        ])
    }

    // MARK: - Configuration with Pre-computed Data

    override func prepareForReuse() {
        super.prepareForReuse()
        resetTextAndBorderDefaults()
        resetPastDayState()
        ratingStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        ratingStack.isHidden = true
        noLocationBadge.isHidden = true
    }

    private func resetTextAndBorderDefaults() {
        titleLabel.textColor = ColorSet.fg.uiColor
        durationLabel.textColor = ColorSet.fg.uiColor
        cancellationLabel.textColor = ColorSet.greenAdvantage.uiColor
        activityBadge.textColor = ColorSet.fgGray.uiColor
    }

    /// Past-day rendering: hide the reservation CTA, grey out the action buttons (they stay
    /// enabled to consume taps; `isPastDayMode` makes their handlers no-op).
    func applyPastDayStyle() {
        isPastDayMode = true
        reservationButton.isHidden = true
        changeTimeButton.setPastDayDisabled(true, originalTint: ColorSet.primary.uiColor)
        removeButton.setPastDayDisabled(true, originalTint: ColorSet.primary.uiColor)
    }

    private func resetPastDayState() {
        isPastDayMode = false
        reservationButton.isHidden = false
        changeTimeButton.setPastDayDisabled(false, originalTint: ColorSet.primary.uiColor)
        removeButton.setPastDayDisabled(false, originalTint: ColorSet.primary.uiColor)
    }

    func configure(with cellData: BookedActivityCellData) {
        self.segment = cellData.segment

        titleLabel.text = cellData.title

        let timeParts = cellData.timeRange.components(separatedBy: " - ")
        let startTime = timeParts.first ?? ""
        let endTime = timeParts.count > 1 ? timeParts[1] : ""
        timeBadgeView.configure(
            order: cellData.order,
            startTime: startTime,
            endTime: endTime,
            hasConflict: cellData.hasConflict,
            showTimeOverlapText: cellData.showTimeOverlapText,
            isAvailabilityExpired: cellData.isAvailabilityExpired
        )

        // Desaturate to grayscale when the activity is no longer available for its slot.
        let shouldDesaturate = cellData.isAvailabilityExpired
        if let imageUrlString = cellData.imageUrl, let url = URL(string: imageUrlString) {
            activityImageView.sd_setImage(with: url, placeholderImage: nil) { [weak self] image, _, _, _ in
                guard let self = self, let image = image else { return }
                self.activityImageView.image = shouldDesaturate
                    ? (image.convertToGrayScale() ?? image)
                    : image
            }
        } else {
            activityImageView.image = nil
        }

        if let cancellation = cellData.cancellation, !cancellation.isEmpty {
            cancellationLabel.text = cancellation
            cancellationLabel.isHidden = false
        } else {
            cancellationLabel.text = CommonLocalizationKeys.localized(CommonLocalizationKeys.freeCancellation)
            cancellationLabel.isHidden = false
        }

        if let duration = cellData.duration, duration > 0 {
            durationLabel.text = formatDuration(duration)
            durationStackView.isHidden = false
        } else {
            durationStackView.isHidden = true
        }

        configureRating(rating: cellData.rating, ratingCount: cellData.ratingCount)

        noLocationBadge.isHidden = !cellData.isNoLocation

        configurePriceRow(with: cellData.price)
    }

    private func configureRating(rating: Float?, ratingCount: Int?) {
        ratingStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        guard let rating = rating else {
            ratingStack.isHidden = true
            return
        }

        let ratingLabel = UILabel()
        ratingLabel.font = FontSet.montserratBold.font(14)
        ratingLabel.textColor = ColorSet.primaryText.uiColor
        ratingLabel.text = String(format: "%.1f", rating).replacingOccurrences(of: ".", with: ",")

        let spacer1 = UIView()
        spacer1.translatesAutoresizingMaskIntoConstraints = false
        spacer1.widthAnchor.constraint(equalToConstant: 2).isActive = true

        let starIcon = UIImageView()
        starIcon.image = TRPImageController().getImage(inFramework: "ic_rating_star", inApp: nil)
        starIcon.tintColor = ColorSet.ratingStar.uiColor
        starIcon.translatesAutoresizingMaskIntoConstraints = false
        starIcon.contentMode = .scaleAspectFit
        starIcon.widthAnchor.constraint(equalToConstant: 14).isActive = true
        starIcon.heightAnchor.constraint(equalToConstant: 14).isActive = true

        ratingStack.addArrangedSubview(ratingLabel)
        ratingStack.addArrangedSubview(spacer1)
        ratingStack.addArrangedSubview(starIcon)

        if let ratingCount = ratingCount {
            let spacer2 = UIView()
            spacer2.translatesAutoresizingMaskIntoConstraints = false
            spacer2.widthAnchor.constraint(equalToConstant: 4).isActive = true

            let reviewLabel = UILabel()
            reviewLabel.font = FontSet.montserratRegular.font(14)
            reviewLabel.textColor = ColorSet.fgWeak.uiColor
            let opinionsText = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.opinions)
            reviewLabel.text = "\(ratingCount.formattedWithSeparator) \(opinionsText)"

            ratingStack.addArrangedSubview(spacer2)
            ratingStack.addArrangedSubview(reviewLabel)
        }

        ratingStack.isHidden = false
    }

    private func formatDuration(_ minutes: Double) -> String {
        return TimelineLocalizationKeys.formatDuration(minutes: Int(minutes))
    }

    /// A missing or non-positive price renders as "FREE" — the tour API omits the price for
    /// free products instead of sending zero.
    private func configurePriceRow(with priceData: TRPSegmentActivityPrice?) {
        priceRowContainer.subviews.forEach { $0.removeFromSuperview() }

        let priceRow = UIStackView()
        priceRow.translatesAutoresizingMaskIntoConstraints = false
        priceRow.axis = .horizontal
        priceRow.spacing = 4
        priceRow.alignment = .center

        if let price = priceData, price.value > 0 {
            let fromLabel = UILabel()
            fromLabel.font = FontSet.montserratMedium.font(14)
            fromLabel.textColor = ColorSet.primaryText.uiColor
            fromLabel.text = CommonLocalizationKeys.localized(CommonLocalizationKeys.from)

            let priceLabel = UILabel()
            priceLabel.font = FontSet.montserratBold.font(16)
            priceLabel.textColor = ColorSet.primaryText.uiColor
            priceLabel.text = TRPCurrencyHelper.formatPrice(price.value, currency: price.currency)

            priceRow.addArrangedSubview(fromLabel)
            priceRow.addArrangedSubview(priceLabel)
        } else {
            let freeLabel = UILabel()
            freeLabel.font = FontSet.montserratBold.font(16)
            freeLabel.textColor = ColorSet.primaryText.uiColor
            freeLabel.text = CommonLocalizationKeys.localized(CommonLocalizationKeys.free)

            priceRow.addArrangedSubview(freeLabel)
        }

        priceRowContainer.addSubview(priceRow)
        NSLayoutConstraint.activate([
            priceRow.topAnchor.constraint(equalTo: priceRowContainer.topAnchor),
            priceRow.bottomAnchor.constraint(equalTo: priceRowContainer.bottomAnchor),
            priceRow.trailingAnchor.constraint(equalTo: priceRowContainer.trailingAnchor),
        ])
        priceRowContainer.isHidden = false
    }

    // MARK: - Actions
    @objc private func reservationButtonTapped() {
        guard !isPastDayMode, let segment = segment else { return }
        delegate?.reservedActivityCellDidTapReservation(self, segment: segment)
    }

    @objc private func changeTimeButtonTapped() {
        guard !isPastDayMode, let segment = segment else { return }
        delegate?.reservedActivityCellDidTapChangeTime(self, segment: segment)
    }

    @objc private func removeButtonTapped() {
        guard !isPastDayMode, let segment = segment else { return }
        delegate?.reservedActivityCellDidTapRemove(self, segment: segment)
    }

    @objc private func cellTapped() {
        guard let segment = segment else { return }
        delegate?.reservedActivityCellDidTapCell(self, segment: segment)
    }
}
