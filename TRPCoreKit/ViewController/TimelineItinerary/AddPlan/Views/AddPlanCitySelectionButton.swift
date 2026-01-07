//
//  AddPlanCitySelectionButton.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 08.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import UIKit
import TRPFoundationKit

public protocol AddPlanCitySelectionButtonDelegate: AnyObject {
    func citySelectionButtonDidTap(_ view: AddPlanCitySelectionButton)
}

public class AddPlanCitySelectionButton: UIView {

    // MARK: - Properties
    public weak var delegate: AddPlanCitySelectionButtonDelegate?

    // MARK: - UI Components
    private lazy var cityLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.city)
        label.font = FontSet.montserratLight.font(12)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()

    private lazy var cityButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = ColorSet.neutral100.uiColor
        button.layer.cornerRadius = 4
        button.contentHorizontalAlignment = .left
        button.titleLabel?.font = FontSet.montserratMedium.font(14)
        button.setTitleColor(ColorSet.primaryText.uiColor, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 30)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var chevronImageView: UIImageView = {
        let imageView = UIImageView(image: TRPImageController().getImage(inFramework: "ic_chevron_down", inApp: nil)?.withRenderingMode(.alwaysTemplate))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = ColorSet.primaryText.uiColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

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
        addSubview(cityLabel)
        addSubview(cityButton)
        cityButton.addSubview(chevronImageView)

        NSLayoutConstraint.activate([
            // City Label - height 16
            cityLabel.topAnchor.constraint(equalTo: topAnchor),
            cityLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            cityLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            cityLabel.heightAnchor.constraint(equalToConstant: 16),

            // City Button - top 4, height 48
            cityButton.topAnchor.constraint(equalTo: cityLabel.bottomAnchor, constant: 4),
            cityButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            cityButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            cityButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            cityButton.heightAnchor.constraint(equalToConstant: 48),

            // Chevron Icon
            chevronImageView.centerYAnchor.constraint(equalTo: cityButton.centerYAnchor),
            chevronImageView.trailingAnchor.constraint(equalTo: cityButton.trailingAnchor, constant: -16),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 12),
        ])
    }

    // MARK: - Public Methods
    public func configure(cityName: String?) {
        cityButton.setTitle(cityName ?? CommonLocalizationKeys.localized(CommonLocalizationKeys.select), for: .normal)
    }

    // MARK: - Actions
    @objc private func buttonTapped() {
        delegate?.citySelectionButtonDidTap(self)
    }
}
