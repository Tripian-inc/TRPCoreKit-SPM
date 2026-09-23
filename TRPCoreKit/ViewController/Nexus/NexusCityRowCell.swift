//
//  NexusCityRowCell.swift
//  TRPCoreKit
//
//  A single destination row for the Nexus city-selection list: a pin icon,
//  the city name and country, and a checkmark when selected.
//

import UIKit

final class NexusCityRowCell: UITableViewCell {

    static let reuseId = "NexusCityRowCell"

    private let iconView: UIImageView = {
        let iv = UIImageView(image: TRPImageController().getImage(inFramework: "ic_pin", inApp: nil)?.withRenderingMode(.alwaysTemplate))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = ColorSet.primaryText.uiColor
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = FontSet.montserratSemiBold.font(15)
        l.textColor = ColorSet.primaryText.uiColor
        l.numberOfLines = 1
        return l
    }()

    private let countryLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = FontSet.montserratRegular.font(13)
        l.textColor = UIColor(white: 0.45, alpha: 1)
        l.numberOfLines = 1
        return l
    }()

    private let checkView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = ColorSet.primary.uiColor
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(iconView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(countryLabel)
        contentView.addSubview(checkView)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: checkView.leadingAnchor, constant: -12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),

            countryLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            countryLabel.trailingAnchor.constraint(lessThanOrEqualTo: checkView.leadingAnchor, constant: -12),
            countryLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            countryLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),

            checkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            checkView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkView.widthAnchor.constraint(equalToConstant: 24),
            checkView.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(city: TRPCity, isSelected: Bool) {
        nameLabel.text = city.name
        countryLabel.text = city.countryName
        countryLabel.isHidden = city.countryName.isEmpty
        checkView.isHidden = !isSelected
    }
}
