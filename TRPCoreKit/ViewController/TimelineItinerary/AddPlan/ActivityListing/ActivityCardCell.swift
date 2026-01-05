//
//  ActivityCardCell.swift
//  TRPCoreKit
//
//  Generated from Figma Design
//  Adapted to TRPCoreKit Design System
//

import UIKit
import SDWebImage
import TRPFoundationKit

protocol ActivityCardCellDelegate: AnyObject {
    func activityCardCellDidTapAdd(_ cell: ActivityCardCell, tour: TRPTourProduct)
}

class ActivityCardCell: UITableViewCell {

    static let reuseIdentifier = "ActivityCardCell"

    weak var delegate: ActivityCardCellDelegate?
    private var tour: TRPTourProduct?

    // MARK: - UI Components

    private let cardContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let activityImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 4
        imageView.backgroundColor = ColorSet.neutral100.uiColor
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = FontSet.montserratSemiBold.font(16)
        label.textColor = ColorSet.primaryText.uiColor
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.font = FontSet.montserratBold.font(14)
        label.textColor = ColorSet.primaryText.uiColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let starImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = TRPImageController().getImage(inFramework: "ic_rating_star", inApp: nil)
        imageView.tintColor = ColorSet.primary.uiColor
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let reviewCountLabel: UILabel = {
        let label = UILabel()
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.fgWeak.uiColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let durationIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = TRPImageController().getImage(inFramework: "ic_duration", inApp: nil)
        imageView.tintColor = ColorSet.fgWeak.uiColor
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.primaryText.uiColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let languageIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "bubble.left")
        imageView.tintColor = ColorSet.fgWeak.uiColor
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let languageLabel: UILabel = {
        let label = UILabel()
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.primaryText.uiColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let freeCancellationLabel: UILabel = {
        let label = UILabel()
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.freeCancellation)
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.fgGreen.uiColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = FontSet.montserratBold.font(16)
        label.textColor = ColorSet.primaryText.uiColor
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let image = UIImage(systemName: "plus.circle", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = ColorSet.primary.uiColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSet.lineWeak.uiColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        contentView.backgroundColor = .white
        selectionStyle = .none

        contentView.addSubview(cardContainerView)
        cardContainerView.addSubview(activityImageView)
        cardContainerView.addSubview(titleLabel)
        cardContainerView.addSubview(ratingLabel)
        cardContainerView.addSubview(starImageView)
        cardContainerView.addSubview(reviewCountLabel)
        cardContainerView.addSubview(durationIconImageView)
        cardContainerView.addSubview(durationLabel)
        cardContainerView.addSubview(languageIconImageView)
        cardContainerView.addSubview(languageLabel)
        cardContainerView.addSubview(freeCancellationLabel)
        cardContainerView.addSubview(priceLabel)
        cardContainerView.addSubview(addButton)
        cardContainerView.addSubview(separatorView)

        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            // Card container
            cardContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Activity image
            activityImageView.topAnchor.constraint(equalTo: cardContainerView.topAnchor),
            activityImageView.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor),
            activityImageView.widthAnchor.constraint(equalToConstant: 80),
            activityImageView.heightAnchor.constraint(equalToConstant: 80),

            // Title label
            titleLabel.topAnchor.constraint(equalTo: cardContainerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: activityImageView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: addButton.leadingAnchor, constant: -8),

            // Add button
            addButton.topAnchor.constraint(equalTo: cardContainerView.topAnchor),
            addButton.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 32),
            addButton.heightAnchor.constraint(equalToConstant: 32),

            // Rating label
            ratingLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            ratingLabel.leadingAnchor.constraint(equalTo: activityImageView.trailingAnchor, constant: 16),

            // Star image
            starImageView.centerYAnchor.constraint(equalTo: ratingLabel.centerYAnchor),
            starImageView.leadingAnchor.constraint(equalTo: ratingLabel.trailingAnchor, constant: 2),
            starImageView.widthAnchor.constraint(equalToConstant: 12),
            starImageView.heightAnchor.constraint(equalToConstant: 12),

            // Review count label
            reviewCountLabel.centerYAnchor.constraint(equalTo: ratingLabel.centerYAnchor),
            reviewCountLabel.leadingAnchor.constraint(equalTo: starImageView.trailingAnchor, constant: 4),

            // Duration icon
            durationIconImageView.topAnchor.constraint(equalTo: ratingLabel.bottomAnchor, constant: 6),
            durationIconImageView.leadingAnchor.constraint(equalTo: activityImageView.trailingAnchor, constant: 16),
            durationIconImageView.widthAnchor.constraint(equalToConstant: 16),
            durationIconImageView.heightAnchor.constraint(equalToConstant: 16),

            // Duration label
            durationLabel.centerYAnchor.constraint(equalTo: durationIconImageView.centerYAnchor),
            durationLabel.leadingAnchor.constraint(equalTo: durationIconImageView.trailingAnchor, constant: 4),

            // Language icon
            languageIconImageView.centerYAnchor.constraint(equalTo: durationIconImageView.centerYAnchor),
            languageIconImageView.leadingAnchor.constraint(equalTo: durationLabel.trailingAnchor, constant: 8),
            languageIconImageView.widthAnchor.constraint(equalToConstant: 16),
            languageIconImageView.heightAnchor.constraint(equalToConstant: 16),

            // Language label
            languageLabel.centerYAnchor.constraint(equalTo: languageIconImageView.centerYAnchor),
            languageLabel.leadingAnchor.constraint(equalTo: languageIconImageView.trailingAnchor, constant: 4),

            // Free cancellation label
            freeCancellationLabel.topAnchor.constraint(equalTo: durationIconImageView.bottomAnchor, constant: 6),
            freeCancellationLabel.leadingAnchor.constraint(equalTo: activityImageView.trailingAnchor, constant: 16),

            // Price label
            priceLabel.topAnchor.constraint(equalTo: freeCancellationLabel.bottomAnchor, constant: 12),
            priceLabel.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor),
            priceLabel.bottomAnchor.constraint(lessThanOrEqualTo: cardContainerView.bottomAnchor, constant: -16),

            // Separator
            separatorView.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: cardContainerView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    // MARK: - Actions

    @objc private func addButtonTapped() {
        guard let tour = tour else { return }
        delegate?.activityCardCellDidTapAdd(self, tour: tour)
    }

    // MARK: - Configuration

    func configure(with tour: TRPTourProduct) {
        self.tour = tour
        titleLabel.text = tour.name

        // Set rating
        if tour.isRatingAvailable() {
            ratingLabel.text = String(format: "%.1f", tour.rating ?? 0)
            reviewCountLabel.text = "\(tour.ratingCount?.formattedWithSeparator ?? "0") " +
                                   AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.opinions)
            ratingLabel.isHidden = false
            starImageView.isHidden = false
            reviewCountLabel.isHidden = false
        } else {
            ratingLabel.isHidden = true
            starImageView.isHidden = true
            reviewCountLabel.isHidden = true
        }

        // Set duration
        if let duration = tour.duration {
            durationLabel.text = TimelineLocalizationKeys.formatDuration(minutes: duration)
            durationIconImageView.isHidden = false
            durationLabel.isHidden = false
        } else {
            durationIconImageView.isHidden = true
            durationLabel.isHidden = true
        }

        // Set language - hide for now as we don't have this data in TRPTourProduct
        languageIconImageView.isHidden = true
        languageLabel.isHidden = true

        // Free cancellation - hide for now as we don't have this data
        freeCancellationLabel.isHidden = true

        // Set price
        if let price = tour.price {
            priceLabel.text = "$\(price)"
        } else {
            priceLabel.text = ""
        }

        // Set activity image using SDWebImage
        if let imageUrl = tour.image?.url, let url = URL(string: imageUrl) {
            activityImageView.sd_setImage(with: url, placeholderImage: nil)
        } else {
            activityImageView.image = nil
            activityImageView.backgroundColor = ColorSet.neutral100.uiColor
        }
    }

    /// Configure cell with TRPSegmentFavoriteItem (for saved plans)
    func configure(with favoriteItem: TRPSegmentFavoriteItem, tourProduct: TRPTourProduct) {
        // Store tour product for delegate callback
        self.tour = tourProduct

        titleLabel.text = favoriteItem.title

        // Set rating
        if let rating = favoriteItem.rating, let ratingCount = favoriteItem.ratingCount, ratingCount > 0 {
            ratingLabel.text = String(format: "%.1f", rating)
            reviewCountLabel.text = "\(ratingCount.formattedWithSeparator) " +
                                   AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.opinions)
            ratingLabel.isHidden = false
            starImageView.isHidden = false
            reviewCountLabel.isHidden = false
        } else {
            ratingLabel.isHidden = true
            starImageView.isHidden = true
            reviewCountLabel.isHidden = true
        }

        // Duration not available in TRPSegmentFavoriteItem
        durationIconImageView.isHidden = true
        durationLabel.isHidden = true

        // Language not available
        languageIconImageView.isHidden = true
        languageLabel.isHidden = true

        // Free cancellation - show only if NOT non_refundable
        if let cancellation = favoriteItem.cancellation,
           !cancellation.isEmpty,
           cancellation.lowercased() != "non_refundable" {
            // Show localized "Free cancellation" text
            freeCancellationLabel.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.freeCancellation)
            freeCancellationLabel.isHidden = false
        } else {
            freeCancellationLabel.isHidden = true
        }

        // Set price with currency
        if let price = favoriteItem.price {
            let currencySymbol = getCurrencySymbol(for: price.currency)
            priceLabel.text = "\(currencySymbol)\(String(format: "%.2f", price.value))"
        } else {
            priceLabel.text = ""
        }

        // Hide separator for saved plans screen
        separatorView.isHidden = true

        // Set activity image using SDWebImage
        if let imageUrl = favoriteItem.photoUrl, let url = URL(string: imageUrl) {
            activityImageView.sd_setImage(with: url, placeholderImage: nil)
        } else {
            activityImageView.image = nil
            activityImageView.backgroundColor = ColorSet.neutral100.uiColor
        }
    }

    /// Get currency symbol for currency code
    private func getCurrencySymbol(for currencyCode: String) -> String {
        switch currencyCode.uppercased() {
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "TRY": return "₺"
        default: return currencyCode + " "
        }
    }
}
