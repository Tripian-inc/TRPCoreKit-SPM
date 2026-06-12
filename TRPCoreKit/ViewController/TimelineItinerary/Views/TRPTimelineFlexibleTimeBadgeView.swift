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

    func configure(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
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
        titleLabel.textColor = ColorSet.fg.uiColor
        subtitleLabel.textColor = ColorSet.fg.uiColor
        orderLabel.backgroundColor = ColorSet.fg.uiColor
        dashedBorderLayer.strokeColor = ColorSet.lineWeak.uiColor.cgColor
        verticalLineView.backgroundColor = ColorSet.lineWeak.uiColor
    }
}
