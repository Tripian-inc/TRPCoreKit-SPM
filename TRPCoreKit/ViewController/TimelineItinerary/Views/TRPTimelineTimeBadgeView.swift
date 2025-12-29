//
//  TRPTimelineTimeBadgeView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 29.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit

enum TRPTimelineTimeBadgeStyle {
    case activity  // Green background with border
    case poi       // White background with border
}

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
        return label
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
        containerView.addSubview(orderLabel)
        containerView.addSubview(timeLabel)

        NSLayoutConstraint.activate([
            // Container View
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
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
        ])
    }

    // MARK: - Configuration
    func configure(order: Int, startTime: String, endTime: String, style: TRPTimelineTimeBadgeStyle = .activity) {
        orderLabel.text = "\(order)"
        timeLabel.text = "\(startTime) - \(endTime)"

        switch style {
        case .activity:
            // Activity style: green background with border
            containerView.backgroundColor = ColorSet.bgGreen.uiColor
            containerView.layer.borderColor = ColorSet.green250.uiColor.cgColor
            containerView.layer.borderWidth = 2
            timeLabel.textColor = ColorSet.fgGreen.uiColor

        case .poi:
            // POI style: white background with border
            containerView.backgroundColor = .white
            containerView.layer.borderColor = ColorSet.neutral200.uiColor.cgColor
            containerView.layer.borderWidth = 1
            timeLabel.textColor = ColorSet.fg.uiColor
        }
    }
}
