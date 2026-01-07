//
//  TRPButton.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 27.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit

public enum TRPButtonStyle {
    case primary
    case secondary
    case outlined
}

public class TRPButton: UIButton {

    // MARK: - Properties
    private var style: TRPButtonStyle
    private var buttonHeight: CGFloat

    // MARK: - Initialization
    public init(title: String, style: TRPButtonStyle = .primary, height: CGFloat = 48) {
        self.style = style
        self.buttonHeight = height
        super.init(frame: .zero)

        setupButton(title: title)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupButton(title: String) {
        translatesAutoresizingMaskIntoConstraints = false

        setTitle(title, for: .normal)
        heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true

        switch style {
        case .primary:
            setupPrimaryStyle()
        case .secondary:
            setupSecondaryStyle()
        case .outlined:
            setupOutlinedStyle()
        }
    }

    private func setupPrimaryStyle() {
        // Primary button: filled background with white text
        setTitleColor(.white, for: .normal)
        setTitleColor(.white, for: .disabled)
        titleLabel?.font = FontSet.montserratMedium.font(16)
        backgroundColor = ColorSet.primary.uiColor
        layer.cornerRadius = buttonHeight / 2
        clipsToBounds = true
    }

    private func setupSecondaryStyle() {
        // Secondary button: transparent background with colored text
        setTitleColor(ColorSet.fg.uiColor, for: .normal)
        titleLabel?.font = FontSet.montserratRegular.font(14)
        backgroundColor = .clear
    }

    private func setupOutlinedStyle() {
        // Outlined button: white background with primary border and text
        setTitleColor(ColorSet.primary.uiColor, for: .normal)
        titleLabel?.font = FontSet.montserratSemiBold.font(16)
        backgroundColor = .white
        layer.borderWidth = 1
        layer.borderColor = ColorSet.primary.uiColor.cgColor
        layer.cornerRadius = buttonHeight / 2
        clipsToBounds = true
    }

    // MARK: - Public Methods
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled

        if style == .primary {
            backgroundColor = enabled ? ColorSet.primary.uiColor : ColorSet.bgDisabled.uiColor
        }
    }

    public func updateTitle(_ title: String) {
        setTitle(title, for: .normal)
    }
}
