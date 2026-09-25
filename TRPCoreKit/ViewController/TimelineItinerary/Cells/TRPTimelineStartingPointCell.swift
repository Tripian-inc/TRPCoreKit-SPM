//
//  TRPTimelineStartingPointCell.swift
//  TRPCoreKit
//

import UIKit

/// Single-row starting point of the flat timeline (accommodation or city centre), drawn as an outlined pill.
final class TRPTimelineStartingPointCell: UITableViewCell {

    static let reuseIdentifier = "TRPTimelineStartingPointCell"

    private let pillView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.layer.borderWidth = 1
        view.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor
        view.layer.cornerRadius = 18
        return view
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = TRPImageController().getImage(inFramework: "ic_pin", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = ColorSet.fg.uiColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.primaryText.uiColor
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        setupCell()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupCell() {
        contentView.addSubview(pillView)
        pillView.addSubview(iconImageView)
        pillView.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            pillView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            pillView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            pillView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            pillView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            pillView.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),

            iconImageView.leadingAnchor.constraint(equalTo: pillView.leadingAnchor, constant: 12),
            iconImageView.centerYAnchor.constraint(equalTo: pillView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),

            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 13),
            nameLabel.trailingAnchor.constraint(equalTo: pillView.trailingAnchor, constant: -12),
            nameLabel.topAnchor.constraint(equalTo: pillView.topAnchor, constant: 8),
            nameLabel.bottomAnchor.constraint(equalTo: pillView.bottomAnchor, constant: -8)
        ])
    }

    func configure(with cellData: StartingPointCellData) {
        nameLabel.text = cellData.name
    }
}
