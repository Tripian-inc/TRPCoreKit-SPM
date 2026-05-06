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
    private static let skeletonAnimationKey = "shimmer"

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
        label.text = CommonLocalizationKeys.localized(CommonLocalizationKeys.freeCancellation)
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
        // Visual icon stays 20×20 anchored at the trailing 6pt of a 40×32 hit area.
        // The extra 8pt of width on the leading side enlarges the tap target without
        // shifting the icon — the title/content stack now butts up directly against it.
        button.imageEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 6)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    /// Transparent button that fills the empty gap between `addButton` and `priceLabel` on
    /// the trailing edge. Absorbs taps in that region so the cell's `didSelectRowAt`
    /// (activity detail navigation) does not fire when the user taps near the add button.
    private let tapBlockerButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        return button
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSet.lineWeak.uiColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Skeleton Placeholders

    private let imageSkeletonView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSet.lineWeak.uiColor
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private let titleSkeletonView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSet.lineWeak.uiColor
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private let subtitleSkeletonView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSet.lineWeak.uiColor
        view.layer.cornerRadius = 3
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private let priceSkeletonView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorSet.lineWeak.uiColor
        view.layer.cornerRadius = 3
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
        cardContainerView.addSubview(tapBlockerButton)

        // Skeleton placeholders (overlay; hidden by default)
        cardContainerView.addSubview(imageSkeletonView)
        cardContainerView.addSubview(titleSkeletonView)
        cardContainerView.addSubview(subtitleSkeletonView)
        cardContainerView.addSubview(priceSkeletonView)

        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        tapBlockerButton.addTarget(self, action: #selector(tapBlockerTapped), for: .touchUpInside)

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

            // Add button (top-right with 24px top padding). Hit area is 40×32: the icon
            // visually occupies the right 32×32 (matching the original look) but the extra
            // 8pt to the left enlarges the tap target.
            addButton.topAnchor.constraint(equalTo: cardContainerView.topAnchor, constant: 24),
            addButton.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 40),
            addButton.heightAnchor.constraint(equalToConstant: 32),

            // Content stack view (between image and add button, with 24px top padding).
            // Butts up against the add button's leading edge — the previous 8pt gap is now
            // absorbed into the add button's tap area.
            contentStackView.topAnchor.constraint(equalTo: cardContainerView.topAnchor, constant: 24),
            contentStackView.leadingAnchor.constraint(equalTo: activityImageView.trailingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: addButton.leadingAnchor),

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

            // Separator (16px padding from left and right). Bottom is upper-bounded by
            // the card container so that — in skeleton mode where real content collapses —
            // the skeleton-driven greaterThanOrEqualTo constraints below can grow the card
            // without conflicting with the separator chain.
            separatorView.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 14),
            separatorView.leadingAnchor.constraint(equalTo: cardContainerView.leadingAnchor),
            separatorView.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor),
            separatorView.bottomAnchor.constraint(lessThanOrEqualTo: cardContainerView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5),

            // Tap blocker — fills the gap between the add button and the price label on the
            // trailing column. Width is aligned to addButton so the rest of the cell still
            // routes taps to the cell's didSelectRowAt for the detail navigation.
            tapBlockerButton.topAnchor.constraint(equalTo: addButton.bottomAnchor),
            tapBlockerButton.bottomAnchor.constraint(equalTo: priceLabel.topAnchor),
            tapBlockerButton.leadingAnchor.constraint(equalTo: addButton.leadingAnchor),
            tapBlockerButton.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor),

            // Skeleton: image placeholder over real image
            imageSkeletonView.topAnchor.constraint(equalTo: activityImageView.topAnchor),
            imageSkeletonView.leadingAnchor.constraint(equalTo: activityImageView.leadingAnchor),
            imageSkeletonView.widthAnchor.constraint(equalTo: activityImageView.widthAnchor),
            imageSkeletonView.heightAnchor.constraint(equalTo: activityImageView.heightAnchor),

            // Skeleton: title bar — full width next to image
            titleSkeletonView.topAnchor.constraint(equalTo: cardContainerView.topAnchor, constant: 28),
            titleSkeletonView.leadingAnchor.constraint(equalTo: activityImageView.trailingAnchor, constant: 16),
            titleSkeletonView.trailingAnchor.constraint(equalTo: addButton.leadingAnchor, constant: -8),
            titleSkeletonView.heightAnchor.constraint(equalToConstant: 14),

            // Skeleton: subtitle bar — half width
            subtitleSkeletonView.topAnchor.constraint(equalTo: titleSkeletonView.bottomAnchor, constant: 10),
            subtitleSkeletonView.leadingAnchor.constraint(equalTo: activityImageView.trailingAnchor, constant: 16),
            subtitleSkeletonView.widthAnchor.constraint(equalToConstant: 120),
            subtitleSkeletonView.heightAnchor.constraint(equalToConstant: 10),

            // Skeleton: price bar — bottom right
            priceSkeletonView.topAnchor.constraint(equalTo: subtitleSkeletonView.bottomAnchor, constant: 18),
            priceSkeletonView.trailingAnchor.constraint(equalTo: cardContainerView.trailingAnchor),
            priceSkeletonView.widthAnchor.constraint(equalToConstant: 60),
            priceSkeletonView.heightAnchor.constraint(equalToConstant: 10),

            // Force the card to stay tall enough to contain skeleton overlays even when
            // the real content (which normally drives cell height via the separator chain)
            // is hidden and collapses to 0.
            cardContainerView.bottomAnchor.constraint(greaterThanOrEqualTo: imageSkeletonView.bottomAnchor, constant: 16),
            cardContainerView.bottomAnchor.constraint(greaterThanOrEqualTo: priceSkeletonView.bottomAnchor, constant: 16)
        ])
    }

    // MARK: - Actions

    @objc private func addButtonTapped() {
        guard let tour = tour else { return }
        delegate?.activityCardCellDidTapAdd(self, tour: tour)
    }

    @objc private func tapBlockerTapped() {
        // Intentional no-op: this button exists only to absorb taps in the gap between
        // the add button and the price label so they don't propagate to the cell's
        // didSelectRowAt and trigger activity detail navigation.
    }

    // MARK: - Private Helpers

    private func updateRating(rating: Float?, ratingCount: Int?) {
        if let rating = rating, let count = ratingCount, count > 0 {
            ratingLabel.text = String(format: "%.1f", rating)
            reviewCountLabel.text = "\(count.formattedWithSeparator) " +
                AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.opinions)
            ratingStackView.isHidden = false
        } else {
            ratingStackView.isHidden = true
        }
    }

    private func updateDuration(minutes: Int?) {
        if let minutes = minutes, minutes > 0 {
            durationLabel.text = TimelineLocalizationKeys.formatDuration(minutes: minutes)
            durationStackView.isHidden = false
        } else {
            durationStackView.isHidden = true
        }
    }

    private func updateCancellation(isCancellable: Bool) {
        freeCancellationLabel.isHidden = !isCancellable
        if isCancellable {
            freeCancellationLabel.text = CommonLocalizationKeys.localized(CommonLocalizationKeys.freeCancellation)
        }
    }

    private func updatePrice(value: Double?, currency: String, convertFromCents: Bool = false) {
        guard let value = value else {
            priceLabel.attributedText = nil
            return
        }

        let displayValue = convertFromCents ? value / 100.0 : value

        // Show "FREE" for zero price
        if displayValue == 0 {
            priceLabel.attributedText = NSAttributedString(
                string: CommonLocalizationKeys.localized(CommonLocalizationKeys.free),
                attributes: [
                    .font: FontSet.montserratBold.font(16),
                    .foregroundColor: ColorSet.primaryText.uiColor
                ]
            )
            return
        }

        let fromText = CommonLocalizationKeys.localized(CommonLocalizationKeys.from) + " "
        let priceText = TRPCurrencyHelper.formatPrice(displayValue, currency: currency)

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
    }

    private func updateImage(urlString: String?) {
        if let urlString = urlString, let url = URL(string: urlString) {
            activityImageView.sd_setImage(with: url, placeholderImage: nil)
        } else {
            activityImageView.image = nil
            activityImageView.backgroundColor = ColorSet.neutral100.uiColor
        }
    }

    private func hideLanguageLabels() {
        languageIconImageView.isHidden = true
        languageLabel.isHidden = true
    }

    // MARK: - Configuration

    func configure(with tour: TRPTourProduct) {
        exitSkeletonMode()

        self.tour = tour
        titleLabel.text = tour.name

        updateRating(rating: tour.rating, ratingCount: tour.ratingCount)
        updateDuration(minutes: tour.duration)
        hideLanguageLabels()
        updateCancellation(isCancellable: tour.isCancellable)
        updatePrice(value: tour.price.map { Double($0) }, currency: tour.currency ?? "EUR")
        updateImage(urlString: tour.image?.url)
    }

    /// Render the cell as a shimmering skeleton — used while a search is in flight.
    func configureSkeleton() {
        self.tour = nil
        isUserInteractionEnabled = false

        // Hide real content
        activityImageView.isHidden = true
        titleLabel.isHidden = true
        ratingStackView.isHidden = true
        durationStackView.isHidden = true
        freeCancellationLabel.isHidden = true
        priceLabel.isHidden = true
        addButton.isHidden = true
        separatorView.isHidden = true

        // Show skeletons
        imageSkeletonView.isHidden = false
        titleSkeletonView.isHidden = false
        subtitleSkeletonView.isHidden = false
        priceSkeletonView.isHidden = false

        startSkeletonAnimation()
    }

    private func exitSkeletonMode() {
        stopSkeletonAnimation()
        isUserInteractionEnabled = true

        imageSkeletonView.isHidden = true
        titleSkeletonView.isHidden = true
        subtitleSkeletonView.isHidden = true
        priceSkeletonView.isHidden = true

        activityImageView.isHidden = false
        titleLabel.isHidden = false
        priceLabel.isHidden = false
        addButton.isHidden = false
        separatorView.isHidden = false
        // ratingStackView / durationStackView / freeCancellationLabel visibility is content-driven
        // and re-set inside updateRating / updateDuration / updateCancellation below.
    }

    private func startSkeletonAnimation() {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.4
        animation.toValue = 1.0
        animation.duration = 0.8
        animation.autoreverses = true
        animation.repeatCount = .infinity
        for view in [imageSkeletonView, titleSkeletonView, subtitleSkeletonView, priceSkeletonView] {
            view.layer.add(animation, forKey: Self.skeletonAnimationKey)
        }
    }

    private func stopSkeletonAnimation() {
        for view in [imageSkeletonView, titleSkeletonView, subtitleSkeletonView, priceSkeletonView] {
            view.layer.removeAnimation(forKey: Self.skeletonAnimationKey)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopSkeletonAnimation()
    }

    /// Configure cell with TRPSegmentFavoriteItem (for saved plans)
    func configure(with favoriteItem: TRPSegmentFavoriteItem, tourProduct: TRPTourProduct) {
        self.tour = tourProduct
        titleLabel.text = favoriteItem.title

        updateRating(rating: favoriteItem.rating, ratingCount: favoriteItem.ratingCount)
        updateDuration(minutes: favoriteItem.duration.map { Int($0) })
        hideLanguageLabels()

        // Cancellation logic for favorite items
        let isCancellable: Bool
        if let cancellation = favoriteItem.cancellation, !cancellation.isEmpty {
            isCancellable = cancellation.lowercased() != "non_refundable"
        } else {
            isCancellable = true
        }
        updateCancellation(isCancellable: isCancellable)

        // Price from cents (convertFromCents: true)
        updatePrice(
            value: favoriteItem.price?.value,
            currency: favoriteItem.price?.currency ?? "EUR",
            convertFromCents: true
        )

        updateImage(urlString: favoriteItem.photoUrl)
        separatorView.isHidden = true
    }

    /// Configure separator visibility (hide for last cell)
    func setSeparatorHidden(_ hidden: Bool) {
        separatorView.isHidden = hidden
    }

}
