//
//  TRPTimelineSectionFooterView.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 03.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit

class TRPTimelineSectionFooterView: UITableViewHeaderFooterView {

    static let reuseIdentifier = "TRPTimelineSectionFooterView"

    // MARK: - UI Components
    private let bandView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.neutral100.uiColor
        view.clipsToBounds = true
        return view
    }()

    /// Inner shadow at the top of the band — the city section above appears to sit on top of it.
    private let topShadowView = GradientView(
        colors: [UIColor.black.withAlphaComponent(0.18), .clear],
        startPoint: CGPoint(x: 0.5, y: 0),
        endPoint: CGPoint(x: 0.5, y: 1)
    )

    private let bottomLine: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.neutral200.uiColor
        return view
    }()

    // MARK: - Initialization
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupView() {
        contentView.backgroundColor = .clear

        contentView.addSubview(bandView)
        bandView.addSubview(topShadowView)
        bandView.addSubview(bottomLine)

        NSLayoutConstraint.activate([
            bandView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bandView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bandView.topAnchor.constraint(equalTo: contentView.topAnchor),
            bandView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            topShadowView.leadingAnchor.constraint(equalTo: bandView.leadingAnchor),
            topShadowView.trailingAnchor.constraint(equalTo: bandView.trailingAnchor),
            topShadowView.topAnchor.constraint(equalTo: bandView.topAnchor),
            topShadowView.heightAnchor.constraint(equalToConstant: 6),

            bottomLine.leadingAnchor.constraint(equalTo: bandView.leadingAnchor),
            bottomLine.trailingAnchor.constraint(equalTo: bandView.trailingAnchor),
            bottomLine.bottomAnchor.constraint(equalTo: bandView.bottomAnchor),
            bottomLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
}

// MARK: - Gradient View
private final class GradientView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    init(colors: [UIColor], startPoint: CGPoint, endPoint: CGPoint) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        guard let gradientLayer = layer as? CAGradientLayer else { return }
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
