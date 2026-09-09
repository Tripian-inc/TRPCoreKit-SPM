//
//  TRPTimelineStepRowView.swift
//  TRPCoreKit
//

import UIKit
import SDWebImage
import TRPFoundationKit

/// One itinerary step row: order/time badge, image, title with change-time and remove
/// buttons, and for activity steps rating, duration, cancellation, price and the
/// reservation CTA. Shared by the recommendations card and the flat timeline's step cell.
final class TRPTimelineStepRowView: UIView {

    var onTap: ((TRPTimelineStep) -> Void)?
    var onChangeTime: ((TRPTimelineStep) -> Void)?
    var onRemove: ((TRPTimelineStep) -> Void)?
    var onReservation: ((TRPTimelineStep) -> Void)?

    /// Reservation CTAs, hidden on past days.
    private(set) var reservationButtons: [UIButton] = []
    /// Change-time / remove buttons, greyed out on past days.
    private(set) var actionButtons: [UIButton] = []

    private let step: TRPTimelineStep

    init(step: TRPTimelineStep, order: Int) {
        self.step = step
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        build(order: order)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Past-day rendering: hide reservation CTAs, grey out action buttons (still tap-consuming).
    func applyPastDayStyle() {
        for button in reservationButtons {
            button.isHidden = true
        }
        for button in actionButtons {
            button.setPastDayDisabled(true, originalTint: ColorSet.primary.uiColor)
        }
    }

    // MARK: - Build

    private func build(order: Int) {
        let isActivity = step.stepType == "activity"

        let timeBadgeView = TRPTimelineTimeBadgeView()
        timeBadgeView.translatesAutoresizingMaskIntoConstraints = false

        let isExpired = step.isAvailabilityExpired
        if let startTime = step.getStartTime(), let endTime = step.getEndTime() {
            timeBadgeView.configure(
                order: order,
                startTime: startTime,
                endTime: endTime,
                hasConflict: step.hasConflict,
                showTimeOverlapText: step.showTimeOverlapText,
                isAvailabilityExpired: isExpired
            )
        }

        let contentContainer = UIView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false

        let poiImageView = UIImageView()
        poiImageView.translatesAutoresizingMaskIntoConstraints = false
        poiImageView.contentMode = .scaleAspectFill
        poiImageView.clipsToBounds = true
        poiImageView.layer.cornerRadius = 8
        poiImageView.backgroundColor = ColorSet.bgDisabled.uiColor

        if let poi = step.poi, let imageUrl = poi.image?.url, let url = URL(string: imageUrl) {
            poiImageView.sd_setImage(with: url, placeholderImage: nil) { [weak poiImageView] image, _, _, _ in
                guard let poiImageView = poiImageView, let image = image else { return }
                poiImageView.image = isExpired
                    ? (image.convertToGrayScale() ?? image)
                    : image
            }
        }

        let infoStackView = UIStackView()
        infoStackView.translatesAutoresizingMaskIntoConstraints = false
        infoStackView.axis = .vertical
        infoStackView.spacing = 8
        infoStackView.alignment = .leading
        infoStackView.distribution = .fill

        let titleRow = UIView()
        titleRow.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = FontSet.montserratSemiBold.font(16)
        titleLabel.textColor = ColorSet.primaryText.uiColor
        titleLabel.numberOfLines = 0
        titleLabel.text = step.poi?.name ?? ""

        let actionButtonsStack = UIStackView()
        actionButtonsStack.translatesAutoresizingMaskIntoConstraints = false
        actionButtonsStack.axis = .horizontal
        actionButtonsStack.spacing = 4
        actionButtonsStack.alignment = .center

        let changeTimeButton = UIButton(type: .custom)
        changeTimeButton.translatesAutoresizingMaskIntoConstraints = false
        let changeTimeIcon = TRPImageController().getImage(inFramework: "ic_change_time", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        changeTimeButton.setImage(changeTimeIcon, for: .normal)
        changeTimeButton.tintColor = ColorSet.primary.uiColor
        changeTimeButton.imageView?.contentMode = .scaleAspectFit
        changeTimeButton.contentVerticalAlignment = .center
        changeTimeButton.contentHorizontalAlignment = .trailing
        changeTimeButton.addTarget(self, action: #selector(changeTimeTapped), for: .touchUpInside)

        let removeStepButton = UIButton(type: .custom)
        removeStepButton.translatesAutoresizingMaskIntoConstraints = false
        let removeStepIcon = TRPImageController().getImage(inFramework: "ic_remove_step", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        removeStepButton.setImage(removeStepIcon, for: .normal)
        removeStepButton.tintColor = ColorSet.primary.uiColor
        removeStepButton.imageView?.contentMode = .scaleAspectFit
        removeStepButton.contentVerticalAlignment = .center
        removeStepButton.contentHorizontalAlignment = .center
        removeStepButton.addTarget(self, action: #selector(removeTapped), for: .touchUpInside)

        actionButtonsStack.addArrangedSubview(changeTimeButton)
        actionButtonsStack.addArrangedSubview(removeStepButton)
        actionButtons.append(changeTimeButton)
        actionButtons.append(removeStepButton)

        titleRow.addSubview(titleLabel)
        titleRow.addSubview(actionButtonsStack)

        let ratingRow = TRPActivityRatingRowView()
        if isActivity, let poi = step.poi {
            ratingRow.configure(rating: poi.rating, ratingCount: poi.ratingCount)
        }

        let bookingProduct = step.poi?.bookings?.first?.firstProduct()

        let categoryBadge = UIView()
        categoryBadge.translatesAutoresizingMaskIntoConstraints = false
        categoryBadge.layer.cornerRadius = 4
        categoryBadge.clipsToBounds = true

        let categoryLabel = UILabel()
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryLabel.font = FontSet.montserratMedium.font(10)

        categoryBadge.backgroundColor = ColorSet.neutral200.uiColor
        categoryLabel.textColor = ColorSet.fgGray.uiColor
        if isActivity {
            categoryLabel.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.activityBadge)
        } else if let poi = step.poi, let firstCategory = poi.categories.first {
            categoryLabel.text = firstCategory.name
        } else {
            categoryLabel.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.pointOfInterest)
        }

        categoryBadge.addSubview(categoryLabel)

        let durationStack = UIStackView()
        durationStack.translatesAutoresizingMaskIntoConstraints = false
        durationStack.axis = .horizontal
        durationStack.spacing = 4
        durationStack.alignment = .center
        durationStack.isHidden = true

        var hasDuration = false
        if isActivity {
            let durationIcon = UIImageView()
            durationIcon.translatesAutoresizingMaskIntoConstraints = false
            durationIcon.image = TRPImageController().getImage(inFramework: "ic_duration", inApp: nil)
            durationIcon.tintColor = ColorSet.fgWeak.uiColor
            durationIcon.contentMode = .scaleAspectFit

            let durationLabel = UILabel()
            durationLabel.font = FontSet.montserratMedium.font(14)
            durationLabel.textColor = ColorSet.fgWeak.uiColor

            var durationText: String? = nil
            if let duration = bookingProduct?.duration {
                durationText = duration
            } else if let poiDuration = step.poi?.duration {
                durationText = TimelineLocalizationKeys.formatDuration(minutes: poiDuration)
            }

            if let durationText = durationText {
                durationLabel.text = durationText
                durationStack.addArrangedSubview(durationIcon)
                durationStack.addArrangedSubview(durationLabel)
                durationStack.isHidden = false
                hasDuration = true

                NSLayoutConstraint.activate([
                    durationIcon.widthAnchor.constraint(equalToConstant: 16),
                    durationIcon.heightAnchor.constraint(equalToConstant: 16),
                ])
            }
        }

        let cancellationLabel = UILabel()
        cancellationLabel.translatesAutoresizingMaskIntoConstraints = false
        cancellationLabel.font = FontSet.montserratMedium.font(14)
        cancellationLabel.textColor = ColorSet.fgGreen.uiColor
        cancellationLabel.numberOfLines = 1
        cancellationLabel.isHidden = true

        var hasCancellation = false
        if isActivity {
            if let tags = step.poi?.tags,
               tags.contains(where: { $0.lowercased() == "full_refundable" }) {
                cancellationLabel.text = CommonLocalizationKeys.localized(CommonLocalizationKeys.freeCancellation)
                cancellationLabel.isHidden = false
                hasCancellation = true
            } else if let info = bookingProduct?.info, !info.isEmpty,
                      let cancellation = info.first(where: { $0.lowercased().contains("cancel") || $0.lowercased().contains("refund") }) {
                cancellationLabel.text = cancellation
                cancellationLabel.isHidden = false
                hasCancellation = true
            }
        }

        let priceRow = TRPActivityPriceRowView()
        if isActivity {
            let resolvedPrice: Double? = step.poi?.additionalData?.price
                ?? bookingProduct?.price.map { Double($0) }
                ?? step.poi?.price.map { Double($0) }
            let currency = step.poi?.additionalData?.currency ?? bookingProduct?.currency ?? "EUR"
            priceRow.configure(value: resolvedPrice, currency: currency)
        }

        let reservationButton = TRPButton(title: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.reservation), style: .primary, height: 40)
        reservationButton.translatesAutoresizingMaskIntoConstraints = false
        reservationButton.addTarget(self, action: #selector(reservationTapped), for: .touchUpInside)
        reservationButton.isHidden = !isActivity
        reservationButtons.append(reservationButton)

        addSubview(timeBadgeView)
        addSubview(contentContainer)
        contentContainer.addSubview(poiImageView)
        contentContainer.addSubview(infoStackView)

        infoStackView.addArrangedSubview(titleRow)
        if isActivity {
            infoStackView.addArrangedSubview(ratingRow)
        }
        infoStackView.addArrangedSubview(categoryBadge)

        if isActivity {
            if hasDuration {
                infoStackView.addArrangedSubview(durationStack)
            }
            if hasCancellation {
                infoStackView.addArrangedSubview(cancellationLabel)
            }
            infoStackView.addArrangedSubview(priceRow)
            priceRow.widthAnchor.constraint(equalTo: infoStackView.widthAnchor).isActive = true

            infoStackView.addArrangedSubview(reservationButton)
            NSLayoutConstraint.activate([
                reservationButton.heightAnchor.constraint(equalToConstant: 40),
                reservationButton.widthAnchor.constraint(equalTo: infoStackView.widthAnchor)
            ])
        }

        NSLayoutConstraint.activate([
            timeBadgeView.topAnchor.constraint(equalTo: topAnchor),
            timeBadgeView.leadingAnchor.constraint(equalTo: leadingAnchor),

            contentContainer.topAnchor.constraint(equalTo: timeBadgeView.bottomAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            poiImageView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            poiImageView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            poiImageView.widthAnchor.constraint(equalToConstant: 80),
            poiImageView.heightAnchor.constraint(equalToConstant: 80),

            infoStackView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            infoStackView.leadingAnchor.constraint(equalTo: poiImageView.trailingAnchor, constant: 16),
            infoStackView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),

            titleRow.widthAnchor.constraint(equalTo: infoStackView.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: titleRow.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: titleRow.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: actionButtonsStack.leadingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(equalTo: titleRow.bottomAnchor),

            actionButtonsStack.topAnchor.constraint(equalTo: titleRow.topAnchor),
            actionButtonsStack.trailingAnchor.constraint(equalTo: titleRow.trailingAnchor, constant: 8),

            changeTimeButton.widthAnchor.constraint(equalToConstant: 36),
            changeTimeButton.heightAnchor.constraint(equalToConstant: 32),
            removeStepButton.widthAnchor.constraint(equalToConstant: 40),
            removeStepButton.heightAnchor.constraint(equalToConstant: 32),

            categoryLabel.topAnchor.constraint(equalTo: categoryBadge.topAnchor, constant: 4),
            categoryLabel.bottomAnchor.constraint(equalTo: categoryBadge.bottomAnchor, constant: -4),
            categoryLabel.leadingAnchor.constraint(equalTo: categoryBadge.leadingAnchor, constant: 8),
            categoryLabel.trailingAnchor.constraint(equalTo: categoryBadge.trailingAnchor, constant: -8),
        ])

        contentContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true
        contentContainer.bottomAnchor.constraint(greaterThanOrEqualTo: infoStackView.bottomAnchor).isActive = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(rowTapped))
        tapGesture.delegate = TRPDisabledControlAwareTapDelegate.shared
        contentContainer.addGestureRecognizer(tapGesture)
    }

    // MARK: - Actions

    @objc private func rowTapped() {
        onTap?(step)
    }

    @objc private func changeTimeTapped() {
        onChangeTime?(step)
    }

    @objc private func removeTapped() {
        onRemove?(step)
    }

    @objc private func reservationTapped() {
        onReservation?(step)
    }
}
