//
//  TRPTimelineRouteSeparatorCell.swift
//  TRPCoreKit
//

import UIKit

/// Distance/duration leg between two consecutive rows of the flat timeline, with the
/// transport icon of the profile the leg was routed with.
final class TRPTimelineRouteSeparatorCell: UITableViewCell {

    static let reuseIdentifier = "TRPTimelineRouteSeparatorCell"

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(12)
        label.textColor = ColorSet.fgWeak.uiColor
        return label
    }()

    private let lineView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.lineWeak.uiColor
        view.layer.cornerRadius = 0.5
        return view
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
        contentView.addSubview(iconImageView)
        contentView.addSubview(distanceLabel)
        contentView.addSubview(lineView)

        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(equalToConstant: 24),

            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 13),
            iconImageView.heightAnchor.constraint(equalToConstant: 16),

            distanceLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 6),
            distanceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            lineView.leadingAnchor.constraint(equalTo: distanceLabel.trailingAnchor, constant: 4),
            lineView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            lineView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            lineView.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    func configure(with cellData: RouteSeparatorCellData) {
        let iconName = cellData.isWalking ? "ic_walk" : "icon_car"
        iconImageView.image = TRPImageController().getImage(inFramework: iconName, inApp: nil)

        let distanceString = String(format: "%.1f", cellData.distance).replacingOccurrences(of: ".", with: ",")
        distanceLabel.text = TimelineLocalizationKeys.formatDistance(minutes: cellData.minutes, kilometers: distanceString)
    }
}
