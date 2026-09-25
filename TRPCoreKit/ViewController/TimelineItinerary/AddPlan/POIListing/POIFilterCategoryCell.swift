//
//  POIFilterCategoryCell.swift
//  TRPCoreKit
//
//  Created by Cem Caygoz on 26.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import UIKit
import TRPFoundationKit

// MARK: - POIFilterCategoryCell
public class POIFilterCategoryCell: UITableViewCell {

    public static let reuseIdentifier = "POIFilterCategoryCell"

    // MARK: - UI Components
    private let checkboxView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.borderWidth = 1
        view.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = TRPImageController().getImage(inFramework: "ic_check", inApp: nil)
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = FontSet.montserratRegular.font(16)
        label.textColor = ColorSet.primaryText.uiColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Initialization
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI() {
        selectionStyle = .none
        contentView.backgroundColor = .white

        contentView.addSubview(checkboxView)
        checkboxView.addSubview(checkmarkImageView)
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            checkboxView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            checkboxView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkboxView.widthAnchor.constraint(equalToConstant: 24),
            checkboxView.heightAnchor.constraint(equalToConstant: 24),

            checkmarkImageView.centerXAnchor.constraint(equalTo: checkboxView.centerXAnchor),
            checkmarkImageView.centerYAnchor.constraint(equalTo: checkboxView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 14),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 14),

            titleLabel.leadingAnchor.constraint(equalTo: checkboxView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    // MARK: - Configuration
    public func configure(title: String, isSelected: Bool) {
        titleLabel.text = title

        if isSelected {
            checkboxView.backgroundColor = ColorSet.primary.uiColor
            checkboxView.layer.borderColor = ColorSet.primary.uiColor.cgColor
            checkmarkImageView.isHidden = false
        } else {
            checkboxView.backgroundColor = .clear
            checkboxView.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor
            checkmarkImageView.isHidden = true
        }
    }
}
