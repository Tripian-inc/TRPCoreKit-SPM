//
//  TRPSelectionField.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 16.02.2026.
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import UIKit
import TRPFoundationKit

/// Reusable selection field component with optional title label and next icon.
/// Used for starting point, time selection, city selection etc.
public class TRPSelectionField: UIView {

    // MARK: - Public Properties

    /// Placeholder text shown when no value is selected
    public var placeholder: String = CommonLocalizationKeys.localized(CommonLocalizationKeys.select) {
        didSet { updateDisplay() }
    }

    /// Optional title label shown above the button
    public var title: String? {
        didSet {
            titleLabel.text = title
            titleLabel.isHidden = title == nil
            updateConstraintsForTitle()
        }
    }

    /// Callback when the field is tapped
    public var onTap: (() -> Void)?

    // MARK: - UI Components

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratLight.font(12)
        label.textColor = ColorSet.primaryText.uiColor
        label.isHidden = true
        return label
    }()

    private lazy var selectionButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        button.layer.cornerRadius = 4
        button.layer.borderWidth = 1
        button.layer.borderColor = ColorSet.line.uiColor.cgColor
        button.contentHorizontalAlignment = .left
        button.titleLabel?.font = FontSet.montserratLight.font(16)
        button.setTitleColor(ColorSet.fgWeak.uiColor, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 40)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var nextIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = TRPImageController().getImage(inFramework: "ic_next", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = ColorSet.fgWeak.uiColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    // MARK: - Private Properties

    private var selectedValue: String?
    private var buttonTopConstraint: NSLayoutConstraint?

    // MARK: - Constants

    private enum Constants {
        static let buttonHeight: CGFloat = 40
        static let titleHeight: CGFloat = 16
        static let titleToButtonSpacing: CGFloat = 4
        static let iconSize: CGFloat = 24
        static let iconTrailingPadding: CGFloat = 8
    }

    // MARK: - Initialization

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        addSubview(titleLabel)
        addSubview(selectionButton)
        selectionButton.addSubview(nextIcon)

        setupConstraints()
        updateDisplay()
    }

    private func setupConstraints() {
        // Title label constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: Constants.titleHeight),
        ])

        // Button constraints - top anchor will be updated based on title visibility
        buttonTopConstraint = selectionButton.topAnchor.constraint(equalTo: topAnchor)

        NSLayoutConstraint.activate([
            buttonTopConstraint!,
            selectionButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            selectionButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            selectionButton.heightAnchor.constraint(equalToConstant: Constants.buttonHeight),
        ])

        // Next icon constraints
        NSLayoutConstraint.activate([
            nextIcon.centerYAnchor.constraint(equalTo: selectionButton.centerYAnchor),
            nextIcon.trailingAnchor.constraint(equalTo: selectionButton.trailingAnchor, constant: -Constants.iconTrailingPadding),
            nextIcon.widthAnchor.constraint(equalToConstant: Constants.iconSize),
            nextIcon.heightAnchor.constraint(equalToConstant: Constants.iconSize),
        ])
    }

    private func updateConstraintsForTitle() {
        if title != nil {
            buttonTopConstraint?.constant = Constants.titleHeight + Constants.titleToButtonSpacing
        } else {
            buttonTopConstraint?.constant = 0
        }
    }

    // MARK: - Public Methods

    /// Set the selected value and update display
    public func setValue(_ value: String?) {
        selectedValue = value
        updateDisplay()
    }

    /// Clear the selection and show placeholder
    public func clear() {
        selectedValue = nil
        updateDisplay()
    }

    /// Get the intrinsic content size based on title visibility
    public override var intrinsicContentSize: CGSize {
        let height: CGFloat
        if title != nil {
            height = Constants.titleHeight + Constants.titleToButtonSpacing + Constants.buttonHeight
        } else {
            height = Constants.buttonHeight
        }
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }

    // MARK: - Private Methods

    private func updateDisplay() {
        if let value = selectedValue {
            selectionButton.setTitle(value, for: .normal)
            selectionButton.setTitleColor(ColorSet.primaryText.uiColor, for: .normal)
        } else {
            selectionButton.setTitle(placeholder, for: .normal)
            selectionButton.setTitleColor(ColorSet.fgWeak.uiColor, for: .normal)
        }
    }

    // MARK: - Actions

    @objc private func buttonTapped() {
        onTap?()
    }
}
