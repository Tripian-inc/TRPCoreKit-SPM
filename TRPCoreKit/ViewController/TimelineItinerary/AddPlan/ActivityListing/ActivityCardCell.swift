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

    // MARK: - Content Stack View (Vertical)

    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = FontSet.montserratSemiBold.font(16)
        label.textColor = ColorSet.primaryText.uiColor
        label.numberOfLines = 2
        return label
    }()

    // MARK: - Rating Stack View (Horizontal)

    private let ratingStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 2
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()

    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.font = FontSet.montserratBold.font(14)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()

    private let starImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = TRPImageController().getImage(inFramework: "ic_rating_star", inApp: nil)
        imageView.tintColor = ColorSet.primary.uiColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let reviewCountLabel: UILabel = {
        let label = UILabel()
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.fgWeak.uiColor
        return label
    }()

    // MARK: - Duration Stack View (Horizontal)

    private let durationStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()

    private let durationIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = TRPImageController().getImage(inFramework: "ic_duration", inApp: nil)
        imageView.tintColor = ColorSet.fgWeak.uiColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let durationLabel: UILabel = {
        let label = UILabel()
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()

    private let languageIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "bubble.left")
        imageView.tintColor = ColorSet.fgWeak.uiColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let languageLabel: UILabel = {
        let label = UILabel()
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()

    private let freeCancellationLabel: UILabel = {
        let label = UILabel()
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.freeCancellation)
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.fgGreen.uiColor
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
        let image = TRPImageController().getImage(inFramework: "ic_add_to_plan", inApp: nil)
        button.setImage(image, for: .normal)
        button.tintColor = ColorSet.primary.uiColor
        button.imageView?.contentMode = .scaleAspectFit
        // Center 20x20 image in 32x32 button (6px padding on each side)
        button.imageEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSet.lineWeak.uiColor
        view.translatesAutoresizingMaskIntoConstraints = false
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

        // Add main container
        contentView.addSubview(cardContainerView)

        // Add image view
        cardContainerView.addSubview(activityImageView)

        // Setup rating stack view
        ratingStackView.addArrangedSubview(ratingLabel)
        ratingStackView.addArrangedSubview(starImageView)
        ratingStackView.addArrangedSubview(reviewCountLabel)

        // Setup duration stack view
        durationStackView.addArrangedSubview(durationIconImageView)
        durationStackView.addArrangedSubview(durationLabel)
        durationStackView.addArrangedSubview(languageIconImageView)
        durationStackView.addArrangedSubview(languageLabel)

        // Setup content stack view
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(ratingStackView)
        contentStackView.addArrangedSubview(durationStackView)
        contentStackView.addArrangedSubview(freeCancellationLabel)

        // Add content stack view
        cardContainerView.addSubview(contentStackView)

        // Add button and price (outside stack view)
        cardContainerView.addSubview(addButton)
        cardContainerView.addSubview(priceLabel)
        cardContainerView.addSubview(separatorView)

        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            // Card container
            cardContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Activity image (fixed size, top-left aligned with 24px top padding)
            activityImageView.topAnchor.constraint(equalTo: cardContainerView.topAnchor, constant: 24),
            activityImageView.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor),
            activityImageView.widthAnchor.constraint(equalToConstant: 80),
            activityImageView.heightAnchor.constraint(equalToConstant: 80),

            // Add button (top-right with 24px top padding)
            addButton.topAnchor.constraint(equalTo: cardContainerView.topAnchor, constant: 24),
            addButton.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 32),
            addButton.heightAnchor.constraint(equalToConstant: 32),

            // Content stack view (between image and add button, with 24px top padding)
            contentStackView.topAnchor.constraint(equalTo: cardContainerView.topAnchor, constant: 24),
            contentStackView.leadingAnchor.constraint(equalTo: activityImageView.trailingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: addButton.leadingAnchor, constant: -8),

            // Star and duration icons size
            starImageView.widthAnchor.constraint(equalToConstant: 12),
            starImageView.heightAnchor.constraint(equalToConstant: 12),
            durationIconImageView.widthAnchor.constraint(equalToConstant: 16),
            durationIconImageView.heightAnchor.constraint(equalToConstant: 16),
            languageIconImageView.widthAnchor.constraint(equalToConstant: 16),
            languageIconImageView.heightAnchor.constraint(equalToConstant: 16),

            // Price label (bottom-right, above separator)
            priceLabel.topAnchor.constraint(equalTo: contentStackView.bottomAnchor, constant: 4),
            priceLabel.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor),

            // Separator (16px padding from left and right)
            separatorView.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 24),
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
            ratingStackView.isHidden = false
        } else {
            ratingStackView.isHidden = true
        }

        // Set duration
        if let duration = tour.duration {
            durationLabel.text = TimelineLocalizationKeys.formatDuration(minutes: duration)
            durationIconImageView.isHidden = false
            durationLabel.isHidden = false
            durationStackView.isHidden = false
        } else {
            durationStackView.isHidden = true
        }

        // Set language - hide for now as we don't have this data in TRPTourProduct
        languageIconImageView.isHidden = true
        languageLabel.isHidden = true

        // Free cancellation - show if tour is cancellable
        freeCancellationLabel.isHidden = !tour.isCancellable
        if tour.isCancellable {
            freeCancellationLabel.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.freeCancellation)
        }

        // Set price with attributed string
        if let price = tour.price {
            let fromText = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.from) + " "
            let priceText = "$\(price)"

            let attributedString = NSMutableAttributedString()
            attributedString.append(NSAttributedString(
                string: fromText,
                attributes: [
                    .font: FontSet.montserratMedium.font(14),
                    .foregroundColor: ColorSet.primaryText.uiColor
                ]
            ))
            attributedString.append(NSAttributedString(
                string: priceText,
                attributes: [
                    .font: FontSet.montserratBold.font(16),
                    .foregroundColor: ColorSet.primaryText.uiColor
                ]
            ))
            priceLabel.attributedText = attributedString
        } else {
            priceLabel.attributedText = nil
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
            ratingStackView.isHidden = false
        } else {
            ratingStackView.isHidden = true
        }

        // Duration - use from favoriteItem if available
        if let duration = favoriteItem.duration {
            durationLabel.text = TimelineLocalizationKeys.formatDuration(minutes: Int(duration))
            durationStackView.isHidden = false
        } else {
            durationStackView.isHidden = true
        }

        // Language not available
        languageIconImageView.isHidden = true
        languageLabel.isHidden = true

        // Free cancellation - show only if NOT non_refundable
        let isCancellable: Bool
        if let cancellation = favoriteItem.cancellation,
           !cancellation.isEmpty {
            isCancellable = cancellation.lowercased() != "non_refundable"
        } else {
            isCancellable = true // Default to cancellable if no cancellation info
        }
        freeCancellationLabel.isHidden = !isCancellable
        if isCancellable {
            freeCancellationLabel.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.freeCancellation)
        }

        // Set price with currency using attributed string
        if let price = favoriteItem.price {
            let currencySymbol = getCurrencySymbol(for: price.currency)
            let fromText = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.from) + " "
            let priceText = "\(currencySymbol)\(String(format: "%.2f", price.value))"

            let attributedString = NSMutableAttributedString()
            attributedString.append(NSAttributedString(
                string: fromText,
                attributes: [
                    .font: FontSet.montserratMedium.font(14),
                    .foregroundColor: ColorSet.primaryText.uiColor
                ]
            ))
            attributedString.append(NSAttributedString(
                string: priceText,
                attributes: [
                    .font: FontSet.montserratBold.font(16),
                    .foregroundColor: ColorSet.primaryText.uiColor
                ]
            ))
            priceLabel.attributedText = attributedString
        } else {
            priceLabel.attributedText = nil
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

    /// Configure separator visibility (hide for last cell)
    func setSeparatorHidden(_ hidden: Bool) {
        separatorView.isHidden = hidden
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
