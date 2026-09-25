//
//  TRPCityMarkerAnnotationView.swift
//  TRPCoreKit
//
//  Created by Claude on 11.04.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit

/// Annotation view for city markers on multi-destination days
/// Shows the ic_map_city_marker image instead of numbered badges
class TRPCityMarkerAnnotationView: UIView {

    var onTapHandler: ((String) -> Void)?
    var cityId: String?

    private static let viewSize: CGFloat = 40

    private lazy var markerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "ic_map_city_marker", in: Bundle.module, compatibleWith: nil)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    // MARK: - Intrinsic Content Size

    override var intrinsicContentSize: CGSize {
        return CGSize(width: Self.viewSize, height: Self.viewSize)
    }

    // MARK: - Initialization

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: Self.viewSize, height: Self.viewSize))
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        // Set content hugging to prevent expansion
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)

        // Add marker image
        addSubview(markerImageView)

        NSLayoutConstraint.activate([
            markerImageView.topAnchor.constraint(equalTo: topAnchor),
            markerImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            markerImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            markerImageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }

    // MARK: - Actions

    @objc private func handleTap() {
        onTapHandler?(cityId ?? "")
    }
}
