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
        label.textAlignment = .right
        label.textColor = ColorSet.fg.uiColor
        return label
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
        containerView.addSubview(timeLabel)

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

            // Time Label
            timeLabel.leadingAnchor.constraint(equalTo: orderLabel.trailingAnchor, constant: 10),
            timeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            timeLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
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

        // Build time text. "Not available" wins over "Time Overlap" when both apply.
        var timeText = "\(startTime) - \(endTime)"
        if isAvailabilityExpired {
            let notAvailableText = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.notAvailable)
            timeText += " \(notAvailableText)"
        } else if showTimeOverlapText {
            let overlapText = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.timeOverlap)
            timeText += " \(overlapText)"
        }
        timeLabel.text = timeText

        // Apply styling. Availability-expired (red) wins over conflict (yellow).
        if isAvailabilityExpired {
            // Legacy "Time Overlap" red palette — solid red border + light red
            // background, white-on-red order chip.
            orderLabel.backgroundColor = ColorSet.errorIcon.uiColor
            containerView.backgroundColor = ColorSet.errorBg.uiColor
            containerView.layer.borderColor = ColorSet.errorIcon.uiColor.cgColor
            timeLabel.textColor = ColorSet.primaryText.uiColor
        } else if hasConflict {
            // Warning styling — yellow border + light yellow background to
            // match the day-level conflict banner (warningBg + warningBorder).
            // Order chip stays in the orange family (civiOrange) for contrast
            // against the pale yellow background.
            orderLabel.backgroundColor = ColorSet.civiOrange.uiColor
            containerView.backgroundColor = ColorSet.warningBg.uiColor
            containerView.layer.borderColor = ColorSet.warningBorder.uiColor.cgColor
            timeLabel.textColor = ColorSet.primaryText.uiColor
        } else {
            // Normal styling
            orderLabel.backgroundColor = ColorSet.fg.uiColor
            containerView.backgroundColor = .clear
            containerView.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor
            timeLabel.textColor = ColorSet.fg.uiColor
        }
        // Note: verticalLineView color stays unchanged (lineWeak) regardless of state
    }
}
