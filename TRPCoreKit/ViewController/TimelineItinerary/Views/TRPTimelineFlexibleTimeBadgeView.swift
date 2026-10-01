//
//  TRPTimelineFlexibleTimeBadgeView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 07.05.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import UIKit

class TRPTimelineFlexibleTimeBadgeView: UIView {

    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 20
        view.backgroundColor = .clear
        return view
    }()

    private let dashedBorderLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = ColorSet.lineWeak.uiColor.cgColor
        layer.lineWidth = 1.0
        layer.lineDashPattern = [4, 3]
        return layer
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
        // U+2212 MINUS SIGN sits at the math axis so it centers in the digit-sized chip; ASCII hyphen looked dropped.
        label.text = "\u{2212}"
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratSemiBold.font(14)
        label.textColor = ColorSet.fg.uiColor
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(11)
        label.textColor = ColorSet.fg.uiColor
        return label
    }()

    private let dotLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(14)
        label.text = "·"
        label.textColor = ColorSet.primaryText.uiColor
        label.isHidden = true
        return label
    }()

    private let warningIconView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = TRPImageController().getImage(inFramework: "ic_warning", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        iv.contentMode = .scaleAspectFit
        iv.tintColor = ColorSet.errorIcon.uiColor
        iv.isHidden = true
        return iv
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.primaryText.uiColor
        label.isHidden = true
        return label
    }()

    private let textStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .firstBaseline
        stack.spacing = 6
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
        containerView.layer.addSublayer(dashedBorderLayer)
        containerView.addSubview(orderLabel)
        containerView.addSubview(textStack)
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)
        textStack.addArrangedSubview(dotLabel)
        textStack.addArrangedSubview(warningIconView)
        textStack.addArrangedSubview(statusLabel)
        textStack.setCustomSpacing(2, after: warningIconView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 32),

            orderLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            orderLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            orderLabel.widthAnchor.constraint(equalToConstant: 20),
            orderLabel.heightAnchor.constraint(equalToConstant: 20),

            textStack.leadingAnchor.constraint(equalTo: orderLabel.trailingAnchor, constant: 10),
            textStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            textStack.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            warningIconView.widthAnchor.constraint(equalToConstant: 16),
            warningIconView.heightAnchor.constraint(equalToConstant: 16),

            verticalLineView.topAnchor.constraint(equalTo: containerView.bottomAnchor),
            verticalLineView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            verticalLineView.widthAnchor.constraint(equalToConstant: 0.5),
            verticalLineView.heightAnchor.constraint(equalToConstant: 24),
            verticalLineView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        configure(
            title: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.flexibleEntryTitle),
            subtitle: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.flexibleEntrySubtitle)
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = UIBezierPath(
            roundedRect: containerView.bounds,
            cornerRadius: containerView.layer.cornerRadius
        )
        dashedBorderLayer.path = path.cgPath
        dashedBorderLayer.frame = containerView.bounds
    }

    // MARK: - Configuration

    /// An expired availability swaps the subtitle for a red "Not available" status, matching the timed badge.
    func configure(title: String, subtitle: String, isAvailabilityExpired: Bool = false) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        statusLabel.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.notAvailable)
        applyAvailabilityStyle(isExpired: isAvailabilityExpired)
    }

    private func applyAvailabilityStyle(isExpired: Bool) {
        subtitleLabel.isHidden = isExpired
        dotLabel.isHidden = !isExpired
        warningIconView.isHidden = !isExpired
        statusLabel.isHidden = !isExpired

        textStack.alignment = isExpired ? .center : .firstBaseline
        textStack.spacing = isExpired ? 8 : 6
        titleLabel.font = isExpired ? FontSet.montserratMedium.font(14) : FontSet.montserratSemiBold.font(14)
        titleLabel.textColor = isExpired ? ColorSet.primaryText.uiColor : ColorSet.fg.uiColor

        containerView.backgroundColor = isExpired ? ColorSet.errorBg.uiColor : .clear
        dashedBorderLayer.strokeColor = isExpired ? ColorSet.errorIcon.uiColor.cgColor : ColorSet.lineWeak.uiColor.cgColor
        dashedBorderLayer.lineDashPattern = isExpired ? nil : [4, 3]
        orderLabel.backgroundColor = isExpired ? ColorSet.errorIcon.uiColor : ColorSet.fg.uiColor
    }

    /// Past-day recolor: `trp_recolorLabelsAndBorders` skips CAShapeLayer.strokeColor, so set it here.
    func applyMutedStyle(color: UIColor) {
        titleLabel.textColor = color
        subtitleLabel.textColor = color
        orderLabel.backgroundColor = color
        dashedBorderLayer.strokeColor = color.cgColor
        verticalLineView.backgroundColor = color
    }

    /// Reset all colors to default styling (used in cell.prepareForReuse).
    func resetStyle() {
        applyAvailabilityStyle(isExpired: false)
        subtitleLabel.textColor = ColorSet.fg.uiColor
        verticalLineView.backgroundColor = ColorSet.lineWeak.uiColor
    }
}
