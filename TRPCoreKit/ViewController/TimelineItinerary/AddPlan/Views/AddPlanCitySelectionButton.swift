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
        button.backgroundColor = .clear
        button.layer.cornerRadius = 4
        button.layer.borderWidth = 1
        button.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor
        button.contentHorizontalAlignment = .left
        button.titleLabel?.font = FontSet.montserratLight.font(16)
        button.setTitleColor(ColorSet.fgWeak.uiColor, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 30)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var nextImageView: UIImageView = {
        let imageView = UIImageView(image: TRPImageController().getImage(inFramework: "ic_next", inApp: nil)?.withRenderingMode(.alwaysTemplate))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = ColorSet.fgWeak.uiColor
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
        cityButton.addSubview(nextImageView)

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

            // Next Icon
            nextImageView.centerYAnchor.constraint(equalTo: cityButton.centerYAnchor),
            nextImageView.trailingAnchor.constraint(equalTo: cityButton.trailingAnchor, constant: -16),
            nextImageView.widthAnchor.constraint(equalToConstant: 16),
            nextImageView.heightAnchor.constraint(equalToConstant: 16),
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
