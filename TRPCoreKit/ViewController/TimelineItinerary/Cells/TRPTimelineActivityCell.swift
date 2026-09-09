//
//  TRPTimelineActivityCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 30.07.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import UIKit
import SDWebImage

/// Which activity flavour a row renders. Drives the layout variant and the host callback semantics:
/// a booked activity opens a booking detail, a reserved or flexible one an activity detail.
enum TRPTimelineActivityCellKind {
    case booked
    case reserved
    case flexible
}

protocol TRPTimelineActivityCellDelegate: AnyObject {
    func activityCellDidTapCell(_ cell: TRPTimelineActivityCell, segment: TRPTimelineSegment, kind: TRPTimelineActivityCellKind)
    func activityCellDidTapReservation(_ cell: TRPTimelineActivityCell, segment: TRPTimelineSegment, kind: TRPTimelineActivityCellKind)
    func activityCellDidTapChangeTime(_ cell: TRPTimelineActivityCell, segment: TRPTimelineSegment)
    func activityCellDidTapRemove(_ cell: TRPTimelineActivityCell, segment: TRPTimelineSegment)
}

/// One cell for booked, reserved and flexible-time activities: they share the same
/// time badge + image + title + meta + CTA skeleton, and the kind toggles the parts that differ.
///
/// | | booked | reserved | flexible |
/// |-|-|-|-|
/// | time badge | fixed | fixed | flexible |
/// | badge | "Confirmed" | "Activity" (+ no-location) | "Activity" (+ no-location) |
/// | travellers / rating | travellers | rating | rating |
/// | duration | — | ✅ | ✅ |
/// | price + reservation CTA | — | ✅ | ✅ |
/// | change time / remove | — | both | remove only |
class TRPTimelineActivityCell: UITableViewCell {

    static let reuseIdentifier = "TRPTimelineActivityCell"

    weak var delegate: TRPTimelineActivityCellDelegate?

    private var segment: TRPTimelineSegment?
    private var kind: TRPTimelineActivityCellKind = .reserved

    /// Past-day mode: buttons stay enabled to consume touches, but their handlers no-op on this flag.
    private var isPastDayMode: Bool = false

    private var titleTrailingConstraint: NSLayoutConstraint?

    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.clipsToBounds = true
        return view
    }()

    /// Holds both badge variants; the hidden one collapses so `containerView` follows the visible one.
    private let timeBadgeStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 0
        stack.alignment = .leading
        return stack
    }()

    private let timeBadgeView: TRPTimelineTimeBadgeView = {
        let view = TRPTimelineTimeBadgeView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let flexibleTimeBadgeView: TRPTimelineFlexibleTimeBadgeView = {
        let view = TRPTimelineFlexibleTimeBadgeView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
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

    private let ratingRowView = TRPActivityRatingRowView()

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
        label.isHidden = true
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

    private let personStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        stack.isHidden = true
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

    private let durationStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        return stack
    }()

    private let cancellationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.greenAdvantage.uiColor
        return label
    }()

    private let priceRowView = TRPActivityPriceRowView()

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

        contentView.addSubview(timeBadgeStackView)
        contentView.addSubview(containerView)

        timeBadgeStackView.addArrangedSubview(timeBadgeView)
        timeBadgeStackView.addArrangedSubview(flexibleTimeBadgeView)

        containerView.addSubview(activityImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(actionButtonsStack)
        containerView.addSubview(rightContentStackView)

        actionButtonsStack.addArrangedSubview(changeTimeButton)
        actionButtonsStack.addArrangedSubview(removeButton)

        badgeStackView.addArrangedSubview(activityBadge)
        badgeStackView.addArrangedSubview(confirmedBadge)
        badgeStackView.addArrangedSubview(noLocationBadge)

        personStackView.addArrangedSubview(personIcon)
        personStackView.addArrangedSubview(personLabel)

        durationStackView.addArrangedSubview(durationIcon)
        durationStackView.addArrangedSubview(durationLabel)

        rightContentStackView.addArrangedSubview(ratingRowView)
        rightContentStackView.addArrangedSubview(badgeStackView)
        rightContentStackView.addArrangedSubview(personStackView)
        rightContentStackView.addArrangedSubview(durationStackView)
        rightContentStackView.addArrangedSubview(cancellationLabel)
        rightContentStackView.addArrangedSubview(priceRowView)
        rightContentStackView.addArrangedSubview(reservationButton)

        let cellTapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        cellTapGesture.delegate = TRPDisabledControlAwareTapDelegate.shared
        contentView.addGestureRecognizer(cellTapGesture)

        setupConstraints()
    }

    private func setupConstraints() {
        let titleTrailing = titleLabel.trailingAnchor.constraint(equalTo: actionButtonsStack.leadingAnchor, constant: -8)
        titleTrailingConstraint = titleTrailing

        NSLayoutConstraint.activate([
            timeBadgeStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            timeBadgeStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            timeBadgeStackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),

            containerView.topAnchor.constraint(equalTo: timeBadgeStackView.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: timeBadgeStackView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            activityImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            activityImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            activityImageView.widthAnchor.constraint(equalToConstant: 80),
            activityImageView.heightAnchor.constraint(equalToConstant: 80),

            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: activityImageView.trailingAnchor, constant: 12),
            titleTrailing,

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

            personIcon.widthAnchor.constraint(equalToConstant: 16),
            personIcon.heightAnchor.constraint(equalToConstant: 16),

            durationIcon.widthAnchor.constraint(equalToConstant: 16),
            durationIcon.heightAnchor.constraint(equalToConstant: 16),

            priceRowView.widthAnchor.constraint(equalTo: rightContentStackView.widthAnchor),
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
        personLabel.textColor = ColorSet.fg.uiColor
        durationLabel.textColor = ColorSet.fg.uiColor
        cancellationLabel.textColor = ColorSet.greenAdvantage.uiColor
        activityBadge.textColor = ColorSet.fgGray.uiColor
        confirmedBadge.textColor = ColorSet.fgGreen.uiColor
        flexibleTimeBadgeView.resetStyle()
    }

    /// Past-day rendering: hide the reservation CTA and grey the action buttons (they stay enabled to
    /// consume taps; `isPastDayMode` makes their handlers no-op). Booked rows have no CTAs, so they
    /// keep their normal styling.
    func applyPastDayStyle() {
        guard kind != .booked else { return }

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

    // MARK: - Configuration

    /// Renders a booked or reserved activity; `cellData.isReserved` picks the variant.
    func configure(with cellData: BookedActivityCellData) {
        apply(ActivityCellContent(cellData))
    }

    /// Renders a reserved activity whose slot has no specific time.
    func configure(with cellData: FlexibleActivityCellData) {
        apply(ActivityCellContent(cellData))
    }

    private func apply(_ content: ActivityCellContent) {
        kind = content.kind
        segment = content.segment

        titleLabel.text = content.title

        configureTimeBadge(content)
        configureImage(urlString: content.imageUrl, desaturated: content.isAvailabilityExpired)

        let isBooked = content.kind == .booked

        activityBadge.isHidden = isBooked
        confirmedBadge.isHidden = !isBooked
        noLocationBadge.isHidden = !content.isNoLocation

        personStackView.isHidden = !isBooked
        if isBooked {
            personLabel.text = travellersText(adults: content.adultCount, children: content.childCount)
        }

        if let duration = content.duration, duration > 0 {
            durationLabel.text = TimelineLocalizationKeys.formatDuration(minutes: Int(duration))
            durationStackView.isHidden = false
        } else {
            durationStackView.isHidden = true
        }

        if let cancellation = content.cancellation, !cancellation.isEmpty {
            cancellationLabel.text = cancellation
        } else {
            cancellationLabel.text = CommonLocalizationKeys.localized(CommonLocalizationKeys.freeCancellation)
        }
        cancellationLabel.isHidden = false

        ratingRowView.configure(rating: content.rating, ratingCount: content.ratingCount)

        priceRowView.isHidden = isBooked
        if !isBooked {
            priceRowView.configure(with: content.price)
        }

        actionButtonsStack.isHidden = isBooked
        changeTimeButton.isHidden = content.kind != .reserved
        removeButton.isHidden = isBooked
        reservationButton.isHidden = isBooked
        titleTrailingConstraint?.constant = isBooked ? 0 : -8
    }

    private func configureTimeBadge(_ content: ActivityCellContent) {
        let isFlexible = content.kind == .flexible
        timeBadgeView.isHidden = isFlexible
        flexibleTimeBadgeView.isHidden = !isFlexible

        guard !isFlexible else {
            flexibleTimeBadgeView.configure(
                title: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.flexibleEntryTitle),
                subtitle: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.flexibleEntrySubtitle)
            )
            return
        }

        let timeParts = content.timeRange.components(separatedBy: " - ")
        timeBadgeView.configure(
            order: content.order,
            startTime: timeParts.first ?? "",
            endTime: timeParts.count > 1 ? timeParts[1] : "",
            hasConflict: content.hasConflict,
            showTimeOverlapText: content.showTimeOverlapText,
            isAvailabilityExpired: content.isAvailabilityExpired
        )
    }

    /// `desaturated` greys the photo out for an activity whose slot is no longer offered.
    private func configureImage(urlString: String?, desaturated: Bool) {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            activityImageView.image = nil
            return
        }

        guard desaturated else {
            activityImageView.sd_setImage(with: url, placeholderImage: nil)
            return
        }

        activityImageView.sd_setImage(with: url, placeholderImage: nil) { [weak self] image, _, _, _ in
            guard let self = self, let image = image else { return }
            self.activityImageView.image = image.convertToGrayScale() ?? image
        }
    }

    private func travellersText(adults: Int, children: Int) -> String {
        let adultsText = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.adults)

        guard children > 0 else {
            return "\(adults) \(adultsText)"
        }

        let childText = children == 1
            ? TimelineLocalizationKeys.localized(TimelineLocalizationKeys.child)
            : TimelineLocalizationKeys.localized(TimelineLocalizationKeys.children)
        return "\(adults) \(adultsText), \(children) \(childText)"
    }

    // MARK: - Actions
    @objc private func reservationButtonTapped() {
        guard !isPastDayMode, let segment = segment else { return }
        delegate?.activityCellDidTapReservation(self, segment: segment, kind: kind)
    }

    @objc private func changeTimeButtonTapped() {
        guard !isPastDayMode, let segment = segment else { return }
        delegate?.activityCellDidTapChangeTime(self, segment: segment)
    }

    @objc private func removeButtonTapped() {
        guard !isPastDayMode, let segment = segment else { return }
        delegate?.activityCellDidTapRemove(self, segment: segment)
    }

    @objc private func cellTapped() {
        guard let segment = segment else { return }
        delegate?.activityCellDidTapCell(self, segment: segment, kind: kind)
    }
}

// MARK: - Kind-agnostic content

/// Flattens the per-kind cell-data structs into what the cell actually renders.
private struct ActivityCellContent {
    let kind: TRPTimelineActivityCellKind
    let segment: TRPTimelineSegment
    let title: String
    let imageUrl: String?
    let timeRange: String
    let order: Int
    let hasConflict: Bool
    let showTimeOverlapText: Bool
    let isAvailabilityExpired: Bool
    let adultCount: Int
    let childCount: Int
    let duration: Double?
    let price: TRPSegmentActivityPrice?
    let cancellation: String?
    let rating: Float?
    let ratingCount: Int?
    let isNoLocation: Bool
}

private extension ActivityCellContent {

    /// A booked activity shows neither a duration, a rating, an overlap warning, the availability
    /// state nor the no-location tag — those belong to the reserved variant only.
    init(_ data: BookedActivityCellData) {
        let isReserved = data.isReserved

        kind = isReserved ? .reserved : .booked
        segment = data.segment
        title = data.title
        imageUrl = data.imageUrl
        timeRange = data.timeRange
        order = data.order
        hasConflict = data.hasConflict
        showTimeOverlapText = isReserved ? data.showTimeOverlapText : false
        isAvailabilityExpired = isReserved ? data.isAvailabilityExpired : false
        adultCount = data.adultCount
        childCount = data.childCount
        duration = isReserved ? data.duration : nil
        price = data.price
        cancellation = data.cancellation
        rating = isReserved ? data.rating : nil
        ratingCount = data.ratingCount
        isNoLocation = isReserved ? data.isNoLocation : false
    }

    init(_ data: FlexibleActivityCellData) {
        kind = .flexible
        segment = data.segment
        title = data.title
        imageUrl = data.imageUrl
        timeRange = ""
        order = 0
        hasConflict = false
        showTimeOverlapText = false
        isAvailabilityExpired = false
        adultCount = data.adultCount
        childCount = data.childCount
        duration = data.duration
        price = data.price
        cancellation = data.cancellation
        rating = data.rating
        ratingCount = data.ratingCount
        isNoLocation = data.isNoLocation
    }
}
