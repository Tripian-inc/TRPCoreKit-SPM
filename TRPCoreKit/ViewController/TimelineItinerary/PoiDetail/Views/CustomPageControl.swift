//
//  CustomPageControl.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - Custom page control extracted from TimelinePoiDetailViewController
//

import UIKit
import TRPFoundationKit

class CustomPageControl: UIView {

    var numberOfPages: Int = 0 {
        didSet {
            setupIndicators()
        }
    }

    var currentPage: Int = 0 {
        didSet {
            updateIndicators()
        }
    }

    var currentPageIndicatorTintColor: UIColor = .white
    var pageIndicatorTintColor: UIColor = UIColor.white

    private var indicators: [UIView] = []
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.distribution = .fill
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setupIndicators() {
        // Remove old indicators
        indicators.forEach { $0.removeFromSuperview() }
        indicators.removeAll()

        // Create new indicators
        for index in 0..<numberOfPages {
            let indicator = UIView()
            indicator.translatesAutoresizingMaskIntoConstraints = false
            indicator.layer.cornerRadius = 5
            indicator.clipsToBounds = true

            // Set initial size (small dot)
            NSLayoutConstraint.activate([
                indicator.widthAnchor.constraint(equalToConstant: 8),
                indicator.heightAnchor.constraint(equalToConstant: 8)
            ])

            indicator.backgroundColor = index == currentPage ? currentPageIndicatorTintColor : pageIndicatorTintColor

            stackView.addArrangedSubview(indicator)
            indicators.append(indicator)
        }

        updateIndicators()
    }

    private func updateIndicators() {
        for (index, indicator) in indicators.enumerated() {
            let isSelected = index == currentPage

            // Remove old constraints
            indicator.constraints.forEach { constraint in
                if constraint.firstAttribute == .width || constraint.firstAttribute == .height {
                    constraint.isActive = false
                }
            }

            UIView.animate(withDuration: 0.3) {
                if isSelected {
                    // Pill shape (wide)
                    indicator.backgroundColor = self.currentPageIndicatorTintColor
                    NSLayoutConstraint.activate([
                        indicator.widthAnchor.constraint(equalToConstant: 14),
                        indicator.heightAnchor.constraint(equalToConstant: 8)
                    ])
                } else {
                    // Small dot
                    indicator.backgroundColor = self.pageIndicatorTintColor
                    NSLayoutConstraint.activate([
                        indicator.widthAnchor.constraint(equalToConstant: 8),
                        indicator.heightAnchor.constraint(equalToConstant: 8)
                    ])
                }

                self.layoutIfNeeded()
            }
        }
    }
}
