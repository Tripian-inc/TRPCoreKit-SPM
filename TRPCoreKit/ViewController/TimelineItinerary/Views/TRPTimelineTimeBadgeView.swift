//
//  TRPTimelineTimeBadgeView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 29.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit

class TRPTimelineTimeBadgeView: UIView {

    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 16
        view.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor
        view.layer.borderWidth = 1.0
        view.clipsToBounds = true
        return view
    }()

    private let orderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratSemiBold.font(16)
        label.textColor = .white
        label.backgroundColor = ColorSet.fg.uiColor
        label.textAlignment = .center
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        return label
    }()

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.fg.uiColor
        return label
    }()

    /// Middle-dot separator between the time range and the status row. Same
    /// font/color as `timeLabel`; hidden in normal state.
    private let dotLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(14)
        label.text = "·"
        label.textColor = ColorSet.fg.uiColor
        label.isHidden = true
        return label
    }()

    /// 16pt warning icon shown between the dot and the status text in conflict
    /// (`civiOrange` tint) or availability-expired (`errorIcon` tint) states.
    private let warningIconView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = TRPImageController().getImage(inFramework: "ic_warning", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    /// "Time Overlap" / "Not available" text shown after the warning icon. Hidden
    /// in normal state.
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.fg.uiColor
        label.isHidden = true
        return label
    }()

    /// Horizontal stack hosting [time, dot, icon, status]. Custom spacings:
    /// 8pt after time, 8pt after dot, 2pt after icon. Hidden trailing items are
    /// excluded automatically by UIStackView so the badge shrinks to just the
    /// time label when no status is shown.
    private let textStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        return stack
    }()

    // Vertical line between time badge and content
    private let verticalLineView: UIView = {
        let lineView = UIView()
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.backgroundColor = ColorSet.lineWeak.uiColor
        return lineView
    }()
    

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupView() {
        addSubview(containerView)
        addSubview(verticalLineView)
        containerView.addSubview(orderLabel)
        containerView.addSubview(textStack)

        textStack.addArrangedSubview(timeLabel)
        textStack.addArrangedSubview(dotLabel)
        textStack.addArrangedSubview(warningIconView)
        textStack.addArrangedSubview(statusLabel)
        textStack.setCustomSpacing(8, after: timeLabel)
        textStack.setCustomSpacing(8, after: dotLabel)
        textStack.setCustomSpacing(2, after: warningIconView)

        NSLayoutConstraint.activate([
            // Container View
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 32),

            // Order Label
            orderLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 6),
            orderLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            orderLabel.widthAnchor.constraint(equalToConstant: 20),
            orderLabel.heightAnchor.constraint(equalToConstant: 20),

            // Text stack — sizes to its content (time + optional status row).
            textStack.leadingAnchor.constraint(equalTo: orderLabel.trailingAnchor, constant: 10),
            textStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            textStack.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            // Warning icon — fixed 16x16, vertically centered by the stack.
            warningIconView.widthAnchor.constraint(equalToConstant: 16),
            warningIconView.heightAnchor.constraint(equalToConstant: 16),

            verticalLineView.topAnchor.constraint(equalTo: containerView.bottomAnchor),
            verticalLineView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            verticalLineView.widthAnchor.constraint(equalToConstant: 0.5),
            verticalLineView.heightAnchor.constraint(equalToConstant: 24),
            verticalLineView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    // MARK: - Configuration

    /// Configures the time badge view with order number, time range, and optional conflict styling
    /// - Parameters:
    ///   - order: The order number to display in the badge
    ///   - startTime: Start time string (e.g., "09:00")
    ///   - endTime: End time string (e.g., "12:00")
    ///   - hasConflict: Whether this time slot has a conflict (applies warning styling)
    ///   - showTimeOverlapText: Whether to show "Time Overlap" text after the time range
    ///   - isAvailabilityExpired: Whether the provider no longer offers this activity's
    ///     time slot. When `true`, this overrides the conflict styling — the badge uses
    ///     the legacy red (errorBg / errorIcon) palette and the suffix becomes
    ///     "Not available" instead of "Time Overlap".
    func configure(order: Int, startTime: String, endTime: String,
                   hasConflict: Bool = false, showTimeOverlapText: Bool = false,
                   isAvailabilityExpired: Bool = false) {
        orderLabel.text = "\(order)"
        timeLabel.text = "\(startTime) - \(endTime)"

        // Status row (dot + warning icon + text). "Not available" wins over
        // "Time Overlap" when both apply.
        let statusText: String?
        if isAvailabilityExpired {
            statusText = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.notAvailable)
        } else if showTimeOverlapText {
            statusText = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.timeOverlap)
        } else {
            statusText = nil
        }
        let showStatus = statusText != nil
        dotLabel.isHidden = !showStatus
        warningIconView.isHidden = !showStatus
        statusLabel.isHidden = !showStatus
        statusLabel.text = statusText

        // Text color: status states (expired / conflict) use primaryText for
        // contrast against their tinted background; normal state uses fg.
        let textColor: UIColor = showStatus ? ColorSet.primaryText.uiColor : ColorSet.fg.uiColor
        timeLabel.textColor = textColor
        dotLabel.textColor = textColor
        statusLabel.textColor = textColor

        // State-specific styling: chip background, container background/border,
        // and warning icon tint. Availability-expired (red) wins over conflict
        // (yellow).
        if isAvailabilityExpired {
            // Legacy "Time Overlap" red palette — solid red border + light red
            // background, white-on-red order chip.
            orderLabel.backgroundColor = ColorSet.errorIcon.uiColor
            containerView.backgroundColor = ColorSet.errorBg.uiColor
            containerView.layer.borderColor = ColorSet.errorIcon.uiColor.cgColor
            warningIconView.tintColor = ColorSet.errorIcon.uiColor
        } else if hasConflict {
            // Warning styling — yellow border + light yellow background to
            // match the day-level conflict banner (warningBg + warningBorder).
            // Order chip stays in the orange family (civiOrange) for contrast
            // against the pale yellow background.
            orderLabel.backgroundColor = ColorSet.civiOrange.uiColor
            containerView.backgroundColor = ColorSet.warningBg.uiColor
            containerView.layer.borderColor = ColorSet.warningBorder.uiColor.cgColor
            warningIconView.tintColor = ColorSet.civiOrange.uiColor
        } else {
            // Normal styling
            orderLabel.backgroundColor = ColorSet.fg.uiColor
            containerView.backgroundColor = .clear
            containerView.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor
        }
        // Note: verticalLineView color stays unchanged (lineWeak) regardless of state
    }
}
