//
//  TRPFloatingActionButton.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 27.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit

public class TRPFloatingActionButton: UIButton {

    // MARK: - Properties
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()

    private var buttonSize: CGFloat

    // MARK: - Initialization
    public init(icon: UIImage?, backgroundColor: UIColor = ColorSet.primary.uiColor, size: CGFloat = 52) {
        self.buttonSize = size
        super.init(frame: .zero)

        setupButton(icon: icon, backgroundColor: backgroundColor)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupButton(icon: UIImage?, backgroundColor: UIColor) {
        translatesAutoresizingMaskIntoConstraints = false

        // Button styling
        self.backgroundColor = backgroundColor
        layer.cornerRadius = buttonSize / 2
        clipsToBounds = true

        // Shadow
        layer.shadowColor = ColorSet.fg.uiColor.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
        layer.shadowOpacity = 0.15
        layer.masksToBounds = false

        // Size constraints
        widthAnchor.constraint(equalToConstant: buttonSize).isActive = true
        heightAnchor.constraint(equalToConstant: buttonSize).isActive = true

        // Add icon
        iconImageView.image = icon
        addSubview(iconImageView)

        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    // MARK: - Public Methods
    public func updateIcon(_ icon: UIImage?) {
        iconImageView.image = icon
    }

    public func updateBackgroundColor(_ color: UIColor) {
        backgroundColor = color
    }
}
