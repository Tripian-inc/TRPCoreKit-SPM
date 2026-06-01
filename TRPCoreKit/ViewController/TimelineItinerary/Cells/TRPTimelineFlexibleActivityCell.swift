//
//  TRPTimelineFlexibleActivityCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 07.05.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import UIKit
import SDWebImage

protocol TRPTimelineFlexibleActivityCellDelegate: AnyObject {
    func flexibleActivityCellDidTapReservation(_ cell: TRPTimelineFlexibleActivityCell, segment: TRPTimelineSegment)
    func flexibleActivityCellDidTapRemove(_ cell: TRPTimelineFlexibleActivityCell, segment: TRPTimelineSegment)
    func flexibleActivityCellDidTapCell(_ cell: TRPTimelineFlexibleActivityCell, segment: TRPTimelineSegment)
}

class TRPTimelineFlexibleActivityCell: UITableViewCell {

    static let reuseIdentifier = "TRPTimelineFlexibleActivityCell"

    weak var delegate: TRPTimelineFlexibleActivityCellDelegate?

    private var segment: TRPTimelineSegment?

    /// `true` while the cell is rendered for a past day. Buttons stay enabled so they
    /// consume taps; this flag short-circuits their action handlers. See
    /// `TRPTimelineReservedActivityCell.isPastDayMode` for full reasoning.
    private var isPastDayMode: Bool = false

    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.clipsToBounds = true
        return view
    }()

    private let timeBadgeView: TRPTimelineFlexibleTimeBadgeView = {
        let view = TRPTimelineFlexibleTimeBadgeView()
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

        // Only remove button — no change-time button for flexible activities
        actionButtonsStack.addArrangedSubview(removeButton)

        durationStackView.addArrangedSubview(durationIcon)
        durationStackView.addArrangedSubview(durationLabel)

        badgeStackView.addArrangedSubview(activityBadge)
        badgeStackView.addArrangedSubview(noLocationBadge)

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
            timeBadgeView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),

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

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        resetTextAndBorderDefaults()
        resetPastDayState()
        noLocationBadge.isHidden = true
    }

    private func resetTextAndBorderDefaults() {
        titleLabel.textColor = ColorSet.fg.uiColor
        durationLabel.textColor = ColorSet.fg.uiColor
        cancellationLabel.textColor = ColorSet.greenAdvantage.uiColor
        activityBadge.textColor = ColorSet.fgGray.uiColor
        timeBadgeView.resetStyle()
    }

    /// Past-day rendering: keep info content (time/title/cancellation/price/tag) at normal
    /// colors. Hide the reservation CTA entirely; grey out the remove icon button. Button
    /// stays enabled so it consumes taps; `isPastDayMode` makes its action a no-op.
    func applyPastDayStyle() {
        isPastDayMode = true
        reservationButton.isHidden = true
        removeButton.setPastDayDisabled(true, originalTint: ColorSet.primary.uiColor)
    }

    /// Reverse of `applyPastDayStyle()` for cell reuse.
    private func resetPastDayState() {
        isPastDayMode = false
        reservationButton.isHidden = false
        removeButton.setPastDayDisabled(false, originalTint: ColorSet.primary.uiColor)
    }

    // MARK: - Configuration

    func configure(with cellData: FlexibleActivityCellData) {
        self.segment = cellData.segment

        titleLabel.text = cellData.title

        timeBadgeView.configure(
            title: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.flexibleEntryTitle),
            subtitle: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.flexibleEntrySubtitle)
        )

        if let imageUrl = cellData.imageUrl {
            activityImageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: nil)
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

        // Flexible activities carry a -1 duration sentinel; hide the duration row in that case.
        if let duration = cellData.duration, duration > 0 {
            durationLabel.text = TimelineLocalizationKeys.formatDuration(minutes: Int(duration))
            durationStackView.isHidden = false
        } else {
            durationStackView.isHidden = true
        }

        // Surface the "no exact location" tag for flexible activities the same way
        // the standard reserved cell does.
        noLocationBadge.isHidden = !cellData.isNoLocation

        configurePriceRow(with: cellData.price)
    }

    private func configurePriceRow(with priceData: TRPSegmentActivityPrice?) {
        guard let price = priceData else {
            priceRowContainer.isHidden = true
            return
        }

        priceRowContainer.subviews.forEach { $0.removeFromSuperview() }

        let priceRow = UIStackView()
        priceRow.translatesAutoresizingMaskIntoConstraints = false
        priceRow.axis = .horizontal
        priceRow.spacing = 4
        priceRow.alignment = .center

        if price.value == 0 {
            let freeLabel = UILabel()
            freeLabel.font = FontSet.montserratBold.font(16)
            freeLabel.textColor = ColorSet.primaryText.uiColor
            freeLabel.text = CommonLocalizationKeys.localized(CommonLocalizationKeys.free)
            priceRow.addArrangedSubview(freeLabel)

            priceRowContainer.addSubview(priceRow)
            NSLayoutConstraint.activate([
                priceRow.topAnchor.constraint(equalTo: priceRowContainer.topAnchor),
                priceRow.bottomAnchor.constraint(equalTo: priceRowContainer.bottomAnchor),
                priceRow.trailingAnchor.constraint(equalTo: priceRowContainer.trailingAnchor),
            ])
            priceRowContainer.isHidden = false
            return
        }

        let fromLabel = UILabel()
        fromLabel.font = FontSet.montserratMedium.font(14)
        fromLabel.textColor = ColorSet.primaryText.uiColor
        fromLabel.text = CommonLocalizationKeys.localized(CommonLocalizationKeys.from)

        let priceLabel = UILabel()
        priceLabel.font = FontSet.montserratBold.font(16)
        priceLabel.textColor = ColorSet.primaryText.uiColor

        let priceText = TRPCurrencyHelper.formatPrice(price.value, currency: price.currency)

        if !priceText.isEmpty {
            priceLabel.text = priceText
            priceRow.addArrangedSubview(fromLabel)
            priceRow.addArrangedSubview(priceLabel)

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
        guard !isPastDayMode, let segment = segment else { return }
        delegate?.flexibleActivityCellDidTapReservation(self, segment: segment)
    }

    @objc private func removeButtonTapped() {
        guard !isPastDayMode, let segment = segment else { return }
        delegate?.flexibleActivityCellDidTapRemove(self, segment: segment)
    }

    @objc private func cellTapped() {
        guard let segment = segment else { return }
        delegate?.flexibleActivityCellDidTapCell(self, segment: segment)
    }
}
