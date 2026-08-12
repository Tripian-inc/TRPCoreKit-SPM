//
//  NexusTripCardCell.swift
//  TRPCoreKit
//
//  Trip card for the Nexus "My Plans" list: cover image with a bottom scrim,
//  city title + country overlaid on the image, a "X days until your trip" pill
//  (future trips only), and the date range below the image. Mirrors the Android
//  My Plans card.
//

import UIKit
import SDWebImage

final class NexusTripCardCell: UITableViewCell {

    static let reuseId = "NexusTripCardCell"

    var onDelete: (() -> Void)?

    private let cardView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        v.layer.cornerRadius = 12
        v.layer.masksToBounds = true
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor(white: 0.92, alpha: 1).cgColor
        return v
    }()

    private let coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0.90, alpha: 1)
        return iv
    }()

    private let scrimView = GradientView()

    private let daysPill: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = ColorSet.primary.uiColor
        v.layer.cornerRadius = 12
        v.layer.masksToBounds = true
        v.isHidden = true
        return v
    }()

    private let daysIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "clock"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let daysLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = FontSet.montserratSemiBold.font(12)
        l.textColor = .white
        return l
    }()

    private let deleteButton: UIButton = {
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.backgroundColor = .white
        b.tintColor = ColorSet.primary.uiColor
        let icon = TRPImageController().getImage(inFramework: "btn_delete_trip", inApp: nil)?
            .withRenderingMode(.alwaysTemplate)
        b.setImage(icon, for: .normal)
        b.contentHorizontalAlignment = .center
        b.layer.cornerRadius = 18
        b.layer.masksToBounds = true
        return b
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = FontSet.montserratBold.font(18)
        l.textColor = .white
        l.numberOfLines = 1
        return l
    }()

    private let countryIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "mappin.and.ellipse"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = .white
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let countryLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = FontSet.montserratRegular.font(13)
        l.textColor = .white
        l.numberOfLines = 1
        return l
    }()

    private let dateIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "calendar"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor = ColorSet.primaryText.uiColor
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = FontSet.montserratSemiBold.font(14)
        l.textColor = ColorSet.primaryText.uiColor
        l.numberOfLines = 1
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        setup()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setup() {
        contentView.addSubview(cardView)
        cardView.addSubview(coverImageView)
        coverImageView.addSubview(scrimView)
        cardView.addSubview(daysPill)
        daysPill.addSubview(daysIcon)
        daysPill.addSubview(daysLabel)
        cardView.addSubview(deleteButton)
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        cardView.addSubview(titleLabel)
        cardView.addSubview(countryIcon)
        cardView.addSubview(countryLabel)
        cardView.addSubview(dateIcon)
        cardView.addSubview(dateLabel)

        scrimView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            coverImageView.topAnchor.constraint(equalTo: cardView.topAnchor),
            coverImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            coverImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            coverImageView.heightAnchor.constraint(equalToConstant: 180),

            scrimView.leadingAnchor.constraint(equalTo: coverImageView.leadingAnchor),
            scrimView.trailingAnchor.constraint(equalTo: coverImageView.trailingAnchor),
            scrimView.bottomAnchor.constraint(equalTo: coverImageView.bottomAnchor),
            scrimView.heightAnchor.constraint(equalToConstant: 96),

            daysPill.topAnchor.constraint(equalTo: coverImageView.topAnchor, constant: 12),
            daysPill.leadingAnchor.constraint(equalTo: coverImageView.leadingAnchor, constant: 12),
            daysPill.heightAnchor.constraint(equalToConstant: 26),

            daysIcon.leadingAnchor.constraint(equalTo: daysPill.leadingAnchor, constant: 10),
            daysIcon.centerYAnchor.constraint(equalTo: daysPill.centerYAnchor),
            daysIcon.widthAnchor.constraint(equalToConstant: 13),
            daysIcon.heightAnchor.constraint(equalToConstant: 13),

            daysLabel.leadingAnchor.constraint(equalTo: daysIcon.trailingAnchor, constant: 5),
            daysLabel.trailingAnchor.constraint(equalTo: daysPill.trailingAnchor, constant: -10),
            daysLabel.centerYAnchor.constraint(equalTo: daysPill.centerYAnchor),

            deleteButton.topAnchor.constraint(equalTo: coverImageView.topAnchor, constant: 12),
            deleteButton.trailingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: -12),
            deleteButton.widthAnchor.constraint(equalToConstant: 36),
            deleteButton.heightAnchor.constraint(equalToConstant: 36),
            deleteButton.leadingAnchor.constraint(greaterThanOrEqualTo: daysPill.trailingAnchor, constant: 8),

            countryIcon.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            countryIcon.bottomAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: -12),
            countryIcon.widthAnchor.constraint(equalToConstant: 14),
            countryIcon.heightAnchor.constraint(equalToConstant: 14),

            countryLabel.leadingAnchor.constraint(equalTo: countryIcon.trailingAnchor, constant: 5),
            countryLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            countryLabel.centerYAnchor.constraint(equalTo: countryIcon.centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: countryIcon.topAnchor, constant: -4),

            dateIcon.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            dateIcon.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: 16),
            dateIcon.widthAnchor.constraint(equalToConstant: 16),
            dateIcon.heightAnchor.constraint(equalToConstant: 16),
            dateIcon.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),

            dateLabel.leadingAnchor.constraint(equalTo: dateIcon.trailingAnchor, constant: 6),
            dateLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            dateLabel.centerYAnchor.constraint(equalTo: dateIcon.centerYAnchor),
        ])
    }

    func configure(with timeline: TRPTimeline) {
        titleLabel.text = NexusTripDisplay.cityTitle(timeline)

        let country = NexusTripDisplay.country(timeline)
        countryLabel.text = country
        countryLabel.isHidden = country.isEmpty
        countryIcon.isHidden = country.isEmpty

        let range = NexusTripDisplay.dateRangeText(timeline)
        dateLabel.text = range
        dateLabel.isHidden = range.isEmpty
        dateIcon.isHidden = range.isEmpty

        if let days = NexusTripDisplay.daysUntil(timeline) {
            daysLabel.text = "\(days) \(NexusLocalizationKeys.localized(NexusLocalizationKeys.daysUntilTrip))"
            daysPill.isHidden = false
        } else {
            daysPill.isHidden = true
        }

        if let url = NexusTripDisplay.imageURL(timeline) {
            coverImageView.sd_setImage(with: url, placeholderImage: nil)
        } else {
            coverImageView.sd_cancelCurrentImageLoad()
            coverImageView.image = nil
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        coverImageView.sd_cancelCurrentImageLoad()
        coverImageView.image = nil
        daysPill.isHidden = true
        onDelete = nil
    }

    @objc private func deleteTapped() {
        onDelete?()
    }
}

/// A view that paints a bottom-anchored dark scrim so white text stays legible
/// over the cover image.
private final class GradientView: UIView {
    private let gradient = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        gradient.colors = [
            UIColor.black.withAlphaComponent(0.0).cgColor,
            UIColor.black.withAlphaComponent(0.25).cgColor,
            UIColor.black.withAlphaComponent(0.70).cgColor
        ]
        gradient.locations = [0.0, 0.5, 1.0]
        layer.addSublayer(gradient)
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }
}
