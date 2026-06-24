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

    /// Middle-dot separator between the time range and the status row; hidden in normal state.
    private let dotLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(14)
        label.text = "·"
        label.textColor = ColorSet.fg.uiColor
        label.isHidden = true
        return label
    }()

    /// Warning icon shown in conflict (`civiOrange`) or availability-expired (`errorIcon`) states.
    private let warningIconView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = TRPImageController().getImage(inFramework: "ic_warning", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    /// "Time Overlap" / "Not available" text shown after the warning icon; hidden in normal state.
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.fg.uiColor
        label.isHidden = true
        return label
    }()

    /// Horizontal stack [time, dot, icon, status]; hidden trailing items collapse so the badge shrinks to just the time.
    private let textStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        return stack
    }()

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
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 32),

            orderLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 6),
            orderLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            orderLabel.widthAnchor.constraint(equalToConstant: 20),
            orderLabel.heightAnchor.constraint(equalToConstant: 20),

            textStack.leadingAnchor.constraint(equalTo: orderLabel.trailingAnchor, constant: 10),
            textStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            textStack.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

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

    /// `isAvailabilityExpired` overrides `hasConflict`: red palette + "Not available" suffix instead of yellow + "Time Overlap".
    func configure(order: Int, startTime: String, endTime: String,
                   hasConflict: Bool = false, showTimeOverlapText: Bool = false,
                   isAvailabilityExpired: Bool = false) {
        orderLabel.text = "\(order)"
        timeLabel.text = "\(startTime) - \(endTime)"

        // "Not available" wins over "Time Overlap" when both apply.
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

        // Status states use primaryText for contrast against their tinted background; normal uses fg.
        let textColor: UIColor = showStatus ? ColorSet.primaryText.uiColor : ColorSet.fg.uiColor
        timeLabel.textColor = textColor
        dotLabel.textColor = textColor
        statusLabel.textColor = textColor

        // Availability-expired (red) wins over conflict (yellow).
        if isAvailabilityExpired {
            orderLabel.backgroundColor = ColorSet.errorIcon.uiColor
            containerView.backgroundColor = ColorSet.errorBg.uiColor
            containerView.layer.borderColor = ColorSet.errorIcon.uiColor.cgColor
            warningIconView.tintColor = ColorSet.errorIcon.uiColor
        } else if hasConflict {
            orderLabel.backgroundColor = ColorSet.civiOrange.uiColor
            containerView.backgroundColor = ColorSet.warningBg.uiColor
            containerView.layer.borderColor = ColorSet.warningBorder.uiColor.cgColor
            warningIconView.tintColor = ColorSet.civiOrange.uiColor
        } else {
            orderLabel.backgroundColor = ColorSet.fg.uiColor
            containerView.backgroundColor = .clear
            containerView.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor
        }
    }
}
