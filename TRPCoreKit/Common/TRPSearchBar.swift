//
//  TRPSearchBar.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 29.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit
import TRPFoundationKit

/// Delegate protocol for TRPSearchBar
public protocol TRPSearchBarDelegate: AnyObject {
    func searchBar(_ searchBar: TRPSearchBar, textDidChange text: String)
    func searchBarDidBeginEditing(_ searchBar: TRPSearchBar)
    func searchBarDidEndEditing(_ searchBar: TRPSearchBar)
    func searchBarSearchButtonClicked(_ searchBar: TRPSearchBar)
}

extension TRPSearchBarDelegate {
    public func searchBarDidBeginEditing(_ searchBar: TRPSearchBar) { }
    public func searchBarDidEndEditing(_ searchBar: TRPSearchBar) { }
}

/// Custom search bar component with consistent styling
public class TRPSearchBar: UIView {

    // MARK: - Properties
    public weak var delegate: TRPSearchBarDelegate?

    public var text: String? {
        get { return textField.text }
        set { textField.text = newValue }
    }

    public var placeholder: String? {
        get { return textField.placeholder }
        set {
            textField.attributedPlaceholder = NSAttributedString(
                string: newValue ?? "",
                attributes: [
                    .foregroundColor: ColorSet.primaryText.uiColor,
                    .font: FontSet.montserratLight.font(14)
                ]
            )
        }
    }

    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 24
        view.layer.borderWidth = 0.5
        view.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor

        return view
    }()

    private let searchIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = TRPImageController().getImage(inFramework: "search_black", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = ColorSet.fgWeak.uiColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.font = FontSet.montserratRegular.font(14)
        textField.textColor = ColorSet.primaryText.uiColor
        textField.backgroundColor = .clear
        textField.returnKeyType = .search
        textField.autocorrectionType = .no
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        return textField
    }()

    private lazy var clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(TRPImageController().getImage(inFramework: "ic_close", inApp: nil), for: .normal)
        button.tintColor = ColorSet.fgWeak.uiColor
        button.isHidden = true
        button.addTarget(self, action: #selector(clearButtonTapped), for: .touchUpInside)
        return button
    }()

    // Constraint references for dynamic layout
    private var textFieldLeadingToIconConstraint: NSLayoutConstraint?
    private var textFieldLeadingToContainerConstraint: NSLayoutConstraint?

    // MARK: - Initialization
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup
    private func setupView() {
        backgroundColor = .clear

        addSubview(containerView)
        containerView.addSubview(searchIconImageView)
        containerView.addSubview(textField)
        containerView.addSubview(clearButton)

        // Create constraint references for dynamic layout
        textFieldLeadingToIconConstraint = textField.leadingAnchor.constraint(equalTo: searchIconImageView.trailingAnchor, constant: 12)
        textFieldLeadingToContainerConstraint = textField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16)

        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 48),

            // Search Icon
            searchIconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            searchIconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            searchIconImageView.widthAnchor.constraint(equalToConstant: 20),
            searchIconImageView.heightAnchor.constraint(equalToConstant: 20),

            // Text Field - initially leading to icon
            textFieldLeadingToIconConstraint!,
            textField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor, constant: -8),

            // Clear Button
            clearButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            clearButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            clearButton.widthAnchor.constraint(equalToConstant: 20),
            clearButton.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    // MARK: - Actions
    @objc private func clearButtonTapped() {
        textField.text = ""
        clearButton.isHidden = true
        updateSearchIconVisibility(hasText: false)
        delegate?.searchBar(self, textDidChange: "")
        textField.resignFirstResponder()
    }

    @objc private func textFieldDidChange() {
        let text = textField.text ?? ""
        let hasText = !text.isEmpty
        clearButton.isHidden = !hasText
        updateSearchIconVisibility(hasText: hasText)
        delegate?.searchBar(self, textDidChange: text)
    }

    private func updateSearchIconVisibility(hasText: Bool) {
        searchIconImageView.isHidden = hasText

        // Update text field leading constraint
        textFieldLeadingToIconConstraint?.isActive = !hasText
        textFieldLeadingToContainerConstraint?.isActive = hasText

        // Animate the layout change
        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
    }

    // MARK: - Public Methods
    @discardableResult
    public override func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }

    @discardableResult
    public override func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }
}

// MARK: - UITextFieldDelegate
extension TRPSearchBar: UITextFieldDelegate {

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.searchBarDidBeginEditing(self)
    }

    public func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.searchBarDidEndEditing(self)
    }

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        delegate?.searchBarSearchButtonClicked(self)
        return true
    }
}
