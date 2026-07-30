//
//  TRPTimelineRecommendationsCell.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 02.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit
import SDWebImage
import TRPFoundationKit

protocol TRPTimelineRecommendationsCellDelegate: AnyObject {
    func recommendationsCellDidTapClose(_ cell: TRPTimelineRecommendationsCell, segment: TRPTimelineSegment?)
    func recommendationsCellDidTapToggle(_ cell: TRPTimelineRecommendationsCell, isExpanded: Bool)
    func recommendationsCellDidSelectStep(_ cell: TRPTimelineRecommendationsCell, step: TRPTimelineStep)
    func recommendationsCellDidTapChangeTime(_ cell: TRPTimelineRecommendationsCell, step: TRPTimelineStep)
    func recommendationsCellDidTapRemoveStep(_ cell: TRPTimelineRecommendationsCell, step: TRPTimelineStep)
    func recommendationsCellDidTapReservation(_ cell: TRPTimelineRecommendationsCell, step: TRPTimelineStep)
    func recommendationsCellNeedsRouteCalculation(_ cell: TRPTimelineRecommendationsCell, locations: [TRPLocation], cellIndexPath: IndexPath)
}

class TRPTimelineRecommendationsCell: UITableViewCell {

    static let reuseIdentifier = "TRPTimelineRecommendationsCell"

    weak var delegate: TRPTimelineRecommendationsCellDelegate?
    private var steps: [TRPTimelineStep] = []
    private var segment: TRPTimelineSegment?
    private var isExpanded: Bool = true
    private var distanceViews: [Int: UIView] = [:]
    private var startingOrder: Int = 1
    private var currentIndexPath: IndexPath?
    private var hasAccommodation: Bool = false

    /// Temporarily hide the starting-point row (accommodation / "City | City Center"). The leading
    /// distance to the first step is still shown and still computed in the route — only the row is
    /// hidden, so the list reads: distance → step 1 → … Flip back to `true` to restore the row.
    private let showsStartingPoint = false

    // MARK: - UI Components
    private let containerView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 24
        stack.alignment = .fill
        stack.distribution = .fill
        stack.backgroundColor = ColorSet.neutral100.uiColor
        stack.layer.borderWidth = 1
        stack.layer.borderColor = ColorSet.neutral200.uiColor.cgColor
        stack.layer.cornerRadius = 12
        stack.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 16, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true
        return stack
    }()

    private let headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratSemiBold.font(16)
        label.textColor = ColorSet.fg.uiColor
        return label
    }()
    
    private let chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = TRPImageController().getImage(inFramework: "ic_recom_arrow", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        imageView.tintColor = ColorSet.fgWeaker.uiColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(TRPImageController().getImage(inFramework: "ic_close", inApp: nil), for: .normal)
        button.tintColor = ColorSet.fg.uiColor
        button.backgroundColor = .white
        button.layer.borderWidth = 1
        button.layer.borderColor = ColorSet.neutral200.uiColor.cgColor
        button.layer.cornerRadius = 22
        return button
    }()

    private let recommendationsStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 24
        stack.isHidden = false
        return stack
    }()

    /// Per-step reservation CTAs, so `applyPastDayStyle()` can hide them all. Rebuilt every `configure`.
    private var stepReservationButtons: [UIButton] = []

    /// Per-step change-time / remove-step buttons, for past-day disabling. Rebuilt every `configure`.
    private var stepActionButtons: [UIButton] = []

    /// True on past days. Buttons stay enabled to consume taps; this flag short-circuits their handlers.
    private var isPastDayMode: Bool = false
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupCell() {
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(containerView)

        containerView.addArrangedSubview(headerView)
        containerView.addArrangedSubview(recommendationsStackView)

        headerView.addSubview(titleLabel)
        headerView.addSubview(chevronImageView)
        headerView.addSubview(closeButton)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

            headerView.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            chevronImageView.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 10),
            chevronImageView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 16),
            chevronImageView.heightAnchor.constraint(equalToConstant: 16),

            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
        ])

        setupActions()
    }
    
    private func setupActions() {
        let chevronTap = UITapGestureRecognizer(target: self, action: #selector(toggleTapped))
        headerView.addGestureRecognizer(chevronTap)

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        resetTextAndBorderDefaults()
        isPastDayMode = false
    }

    private func resetTextAndBorderDefaults() {
        // Static views only — dynamic rows are rebuilt by configure().
        titleLabel.textColor = ColorSet.fg.uiColor
        containerView.layer.borderColor = ColorSet.neutral200.uiColor.cgColor
        closeButton.layer.borderColor = ColorSet.neutral200.uiColor.cgColor
    }

    /// Past-day rendering: hide reservation CTAs, grey out action buttons (still tap-consuming). Must be called AFTER `configure(...)`.
    func applyPastDayStyle() {
        isPastDayMode = true
        for button in stepReservationButtons {
            button.isHidden = true
        }
        for button in stepActionButtons {
            button.setPastDayDisabled(true, originalTint: ColorSet.primary.uiColor)
        }
    }
    
    // MARK: - Actions
    @objc private func toggleTapped() {
        isExpanded.toggle()
        updateChevron(animated: true)

        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseInOut) {
            self.recommendationsStackView.isHidden = !self.isExpanded
            self.recommendationsStackView.alpha = self.isExpanded ? 1.0 : 0.0
            self.layoutIfNeeded()
        }

        delegate?.recommendationsCellDidTapToggle(self, isExpanded: isExpanded)
    }
    
    @objc private func closeTapped() {
        delegate?.recommendationsCellDidTapClose(self, segment: segment)
    }
    
    // MARK: - Updates
    private func updateChevron(animated: Bool = false) {
        let rotation: CGFloat = isExpanded ? 0 : .pi

        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
                self.chevronImageView.transform = CGAffineTransform(rotationAngle: rotation)
            }
        } else {
            chevronImageView.transform = CGAffineTransform(rotationAngle: rotation)
        }
    }
    
    // MARK: - Configuration
    func configure(with steps: [TRPTimelineStep], segment: TRPTimelineSegment?, isExpanded: Bool = true, startingOrder: Int = 1, indexPath: IndexPath, city: TRPCity? = nil) {
        self.steps = steps
        self.segment = segment
        self.isExpanded = isExpanded
        self.startingOrder = startingOrder
        self.currentIndexPath = indexPath

        titleLabel.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.recommendations)

        recommendationsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        distanceViews.removeAll()
        stepReservationButtons.removeAll()
        stepActionButtons.removeAll()

        var distanceIndex = 0

        // Starting point priority: accommodation > city parameter > segment.city
        var startingPointName: String?
        var startingPointCoordinate: TRPLocation?
        let effectiveCity = city ?? segment?.city

        if let accommodation = segment?.accommodation,
           accommodation.coordinate.lat != 0 || accommodation.coordinate.lon != 0 {
            startingPointName = accommodation.name ?? accommodation.address ?? "Starting Point"
            startingPointCoordinate = accommodation.coordinate
            hasAccommodation = true
        } else if let effectiveCity = effectiveCity {
            let cityCenter = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.cityCenter)
            startingPointName = "\(effectiveCity.name) | \(cityCenter)"
            hasAccommodation = false

            // Prefer cached coordinates over the (possibly stub) city object.
            if let cachedCity = TRPCityCache.shared.getCity(byId: effectiveCity.id),
               cachedCity.coordinate.lat != 0 || cachedCity.coordinate.lon != 0 {
                startingPointCoordinate = cachedCity.coordinate
            } else if effectiveCity.coordinate.lat != 0 || effectiveCity.coordinate.lon != 0 {
                startingPointCoordinate = effectiveCity.coordinate
            }
        }

        // Starting-point row is hidden for now (showsStartingPoint == false), but the leading
        // distance (starting point → first step) is still drawn and still computed in the route.
        if showsStartingPoint, let displayName = startingPointName {
            let startingPointView = createAccommodationView(name: displayName)
            recommendationsStackView.addArrangedSubview(startingPointView)
        }

        if !steps.isEmpty && startingPointCoordinate != nil {
            let distanceView = createDistanceView(for: distanceIndex)
            distanceViews[distanceIndex] = distanceView
            recommendationsStackView.addArrangedSubview(distanceView)
            distanceIndex += 1
        }

        for (index, step) in steps.enumerated() {
            let unifiedOrder = startingOrder + index
            let recommendationView = createRecommendationView(for: step, order: unifiedOrder)
            recommendationsStackView.addArrangedSubview(recommendationView)

            if index < steps.count - 1 {
                let distanceView = createDistanceView(for: distanceIndex)
                distanceViews[distanceIndex] = distanceView
                recommendationsStackView.addArrangedSubview(distanceView)
                distanceIndex += 1
            }
        }

        updateChevron()

        recommendationsStackView.isHidden = !isExpanded
        recommendationsStackView.alpha = isExpanded ? 1.0 : 0.0

        var locations: [TRPLocation] = []
        if let coord = startingPointCoordinate {
            locations.append(coord)
        }
        locations.append(contentsOf: steps.compactMap { $0.poi?.coordinate })

        if locations.count > 1 {
            delegate?.recommendationsCellNeedsRouteCalculation(self, locations: locations, cellIndexPath: indexPath)
        }
    }

    // MARK: - Configuration with Pre-computed Data

    func configure(with cellData: RecommendationsCellData, indexPath: IndexPath) {
        self.steps = cellData.steps
        self.segment = cellData.segment
        self.isExpanded = cellData.isExpanded
        self.startingOrder = cellData.startingOrder
        self.currentIndexPath = indexPath

        titleLabel.text = cellData.title

        recommendationsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        distanceViews.removeAll()
        stepReservationButtons.removeAll()
        stepActionButtons.removeAll()

        var distanceIndex = 0

        var startingPointName: String?
        var startingPointCoordinate: TRPLocation?

        if let accommodation = cellData.segment.accommodation,
           accommodation.coordinate.lat != 0 || accommodation.coordinate.lon != 0 {
            startingPointName = accommodation.name ?? accommodation.address ?? "Starting Point"
            startingPointCoordinate = accommodation.coordinate
            hasAccommodation = true
        } else if let city = cellData.city {
            let cityCenter = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.cityCenter)
            startingPointName = "\(city.name) | \(cityCenter)"
            hasAccommodation = false

            // Prefer cached coordinates over the (possibly stub) city object.
            if let cachedCity = TRPCityCache.shared.getCity(byId: city.id),
               cachedCity.coordinate.lat != 0 || cachedCity.coordinate.lon != 0 {
                startingPointCoordinate = cachedCity.coordinate
            } else if city.coordinate.lat != 0 || city.coordinate.lon != 0 {
                startingPointCoordinate = city.coordinate
            }
        }

        // Starting-point row is hidden for now (showsStartingPoint == false), but the leading
        // distance (starting point → first step) is still drawn and still computed in the route.
        if showsStartingPoint, let displayName = startingPointName {
            let startingPointView = createAccommodationView(name: displayName)
            recommendationsStackView.addArrangedSubview(startingPointView)
        }

        if !cellData.steps.isEmpty && startingPointCoordinate != nil {
            let distanceView = createDistanceView(for: distanceIndex)
            distanceViews[distanceIndex] = distanceView
            recommendationsStackView.addArrangedSubview(distanceView)
            distanceIndex += 1
        }

        for (index, step) in cellData.steps.enumerated() {
            let unifiedOrder = startingOrder + index
            let recommendationView = createRecommendationView(for: step, order: unifiedOrder)
            recommendationsStackView.addArrangedSubview(recommendationView)

            if index < cellData.steps.count - 1 {
                let distanceView = createDistanceView(for: distanceIndex)
                distanceViews[distanceIndex] = distanceView
                recommendationsStackView.addArrangedSubview(distanceView)
                distanceIndex += 1
            }
        }

        updateChevron()

        recommendationsStackView.isHidden = !cellData.isExpanded
        recommendationsStackView.alpha = cellData.isExpanded ? 1.0 : 0.0

        var locations: [TRPLocation] = []
        if let coord = startingPointCoordinate {
            locations.append(coord)
        }
        locations.append(contentsOf: cellData.steps.compactMap { $0.poi?.coordinate })

        if locations.count > 1 {
            delegate?.recommendationsCellNeedsRouteCalculation(self, locations: locations, cellIndexPath: indexPath)
        }
    }

    private func createRecommendationView(for step: TRPTimelineStep, order: Int) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear

        let isActivity = step.stepType == "activity"

        let timeBadgeView = TRPTimelineTimeBadgeView()
        timeBadgeView.translatesAutoresizingMaskIntoConstraints = false

        // Expired flag is always false for POI steps (only activities are swept); passing it unconditionally is safe.
        let isExpired = step.isAvailabilityExpired
        if let startTime = step.getStartTime(), let endTime = step.getEndTime() {
            timeBadgeView.configure(
                order: order,
                startTime: startTime,
                endTime: endTime,
                hasConflict: step.hasConflict,
                showTimeOverlapText: step.showTimeOverlapText,
                isAvailabilityExpired: isExpired
            )
        }

        let contentContainer = UIView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false

        // Desaturate to grayscale for expired activity steps.
        let poiImageView = UIImageView()
        poiImageView.translatesAutoresizingMaskIntoConstraints = false
        poiImageView.contentMode = .scaleAspectFill
        poiImageView.clipsToBounds = true
        poiImageView.layer.cornerRadius = 8
        poiImageView.backgroundColor = ColorSet.bgDisabled.uiColor

        if let poi = step.poi, let imageUrl = poi.image?.url, let url = URL(string: imageUrl) {
            poiImageView.sd_setImage(with: url, placeholderImage: nil) { [weak poiImageView] image, _, _, _ in
                guard let poiImageView = poiImageView, let image = image else { return }
                poiImageView.image = isExpired
                    ? (image.convertToGrayScale() ?? image)
                    : image
            }
        }

        let infoStackView = UIStackView()
        infoStackView.translatesAutoresizingMaskIntoConstraints = false
        infoStackView.axis = .vertical
        infoStackView.spacing = 8
        infoStackView.alignment = .leading
        infoStackView.distribution = .fill

        let titleRow = UIView()
        titleRow.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = FontSet.montserratSemiBold.font(16)
        titleLabel.textColor = ColorSet.primaryText.uiColor
        titleLabel.numberOfLines = 0
        titleLabel.text = step.poi?.name ?? ""

        let actionButtonsStack = UIStackView()
        actionButtonsStack.translatesAutoresizingMaskIntoConstraints = false
        actionButtonsStack.axis = .horizontal
        actionButtonsStack.spacing = 4
        actionButtonsStack.alignment = .center

        let changeTimeButton = UIButton(type: .custom)
        changeTimeButton.translatesAutoresizingMaskIntoConstraints = false
        let changeTimeIcon = TRPImageController().getImage(inFramework: "ic_change_time", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        changeTimeButton.setImage(changeTimeIcon, for: .normal)
        changeTimeButton.tintColor = ColorSet.primary.uiColor
        changeTimeButton.imageView?.contentMode = .scaleAspectFit
        changeTimeButton.contentVerticalAlignment = .center
        changeTimeButton.contentHorizontalAlignment = .trailing
        changeTimeButton.tag = steps.firstIndex(where: { $0.id == step.id }) ?? 0
        changeTimeButton.addTarget(self, action: #selector(changeTimeTapped(_:)), for: .touchUpInside)

        let removeStepButton = UIButton(type: .custom)
        removeStepButton.translatesAutoresizingMaskIntoConstraints = false
        let removeStepIcon = TRPImageController().getImage(inFramework: "ic_remove_step", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        removeStepButton.setImage(removeStepIcon, for: .normal)
        removeStepButton.tintColor = ColorSet.primary.uiColor
        removeStepButton.imageView?.contentMode = .scaleAspectFit
        removeStepButton.contentVerticalAlignment = .center
        removeStepButton.contentHorizontalAlignment = .center
        removeStepButton.tag = steps.firstIndex(where: { $0.id == step.id }) ?? 0
        removeStepButton.addTarget(self, action: #selector(removeStepTapped(_:)), for: .touchUpInside)

        actionButtonsStack.addArrangedSubview(changeTimeButton)
        actionButtonsStack.addArrangedSubview(removeStepButton)
        stepActionButtons.append(changeTimeButton)
        stepActionButtons.append(removeStepButton)

        titleRow.addSubview(titleLabel)
        titleRow.addSubview(actionButtonsStack)

        let ratingStack = UIStackView()
        ratingStack.translatesAutoresizingMaskIntoConstraints = false
        ratingStack.axis = .horizontal
        ratingStack.spacing = 0
        ratingStack.alignment = .center

        if isActivity, let poi = step.poi, let rating = poi.rating {
            let ratingLabel = UILabel()
            ratingLabel.font = FontSet.montserratBold.font(14)
            ratingLabel.textColor = ColorSet.primaryText.uiColor
            ratingLabel.text = String(format: "%.1f", rating).replacingOccurrences(of: ".", with: ",")

            let spacer1 = UIView()
            spacer1.translatesAutoresizingMaskIntoConstraints = false
            spacer1.widthAnchor.constraint(equalToConstant: 2).isActive = true

            let starIcon = UIImageView()
            starIcon.image = TRPImageController().getImage(inFramework: "ic_rating_star", inApp: nil)
            starIcon.tintColor = ColorSet.ratingStar.uiColor
            starIcon.translatesAutoresizingMaskIntoConstraints = false
            starIcon.contentMode = .scaleAspectFit
            starIcon.widthAnchor.constraint(equalToConstant: 14).isActive = true
            starIcon.heightAnchor.constraint(equalToConstant: 14).isActive = true

            let spacer2 = UIView()
            spacer2.translatesAutoresizingMaskIntoConstraints = false
            spacer2.widthAnchor.constraint(equalToConstant: 4).isActive = true

            let reviewLabel = UILabel()
            reviewLabel.font = FontSet.montserratRegular.font(14)
            reviewLabel.textColor = ColorSet.fgWeak.uiColor
            if let reviewCount = poi.ratingCount {
                let opinionsText = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.opinions)
                reviewLabel.text = "\(reviewCount.formattedWithSeparator) \(opinionsText)"
            }

            ratingStack.addArrangedSubview(ratingLabel)
            ratingStack.addArrangedSubview(spacer1)
            ratingStack.addArrangedSubview(starIcon)
            ratingStack.addArrangedSubview(spacer2)
            ratingStack.addArrangedSubview(reviewLabel)
        }

        let bookingProduct = step.poi?.bookings?.first?.firstProduct()

        let categoryBadge = UIView()
        categoryBadge.translatesAutoresizingMaskIntoConstraints = false
        categoryBadge.layer.cornerRadius = 4
        categoryBadge.clipsToBounds = true

        let categoryLabel = UILabel()
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryLabel.font = FontSet.montserratMedium.font(10)

        if isActivity {
            categoryBadge.backgroundColor = ColorSet.neutral200.uiColor
            categoryLabel.textColor = ColorSet.fgGray.uiColor
            categoryLabel.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.activityBadge)
        } else {
            categoryBadge.backgroundColor = ColorSet.neutral200.uiColor
            categoryLabel.textColor = ColorSet.fgGray.uiColor
            if let poi = step.poi, let firstCategory = poi.categories.first {
                categoryLabel.text = firstCategory.name
            } else {
                categoryLabel.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.pointOfInterest)
            }
        }

        categoryBadge.addSubview(categoryLabel)

        let durationStack = UIStackView()
        durationStack.translatesAutoresizingMaskIntoConstraints = false
        durationStack.axis = .horizontal
        durationStack.spacing = 4
        durationStack.alignment = .center
        durationStack.isHidden = true

        var hasDuration = false
        if isActivity {
            let durationIcon = UIImageView()
            durationIcon.translatesAutoresizingMaskIntoConstraints = false
            durationIcon.image = TRPImageController().getImage(inFramework: "ic_duration", inApp: nil)
            durationIcon.tintColor = ColorSet.fgWeak.uiColor
            durationIcon.contentMode = .scaleAspectFit

            let durationLabel = UILabel()
            durationLabel.font = FontSet.montserratMedium.font(14)
            durationLabel.textColor = ColorSet.fgWeak.uiColor

            var durationText: String? = nil
            if let duration = bookingProduct?.duration {
                durationText = duration
            } else if let poiDuration = step.poi?.duration {
                durationText = TimelineLocalizationKeys.formatDuration(minutes: poiDuration)
            }

            if let durationText = durationText {
                durationLabel.text = durationText
                durationStack.addArrangedSubview(durationIcon)
                durationStack.addArrangedSubview(durationLabel)
                durationStack.isHidden = false
                hasDuration = true

                NSLayoutConstraint.activate([
                    durationIcon.widthAnchor.constraint(equalToConstant: 16),
                    durationIcon.heightAnchor.constraint(equalToConstant: 16),
                ])
            }
        }

        let cancellationLabel = UILabel()
        cancellationLabel.translatesAutoresizingMaskIntoConstraints = false
        cancellationLabel.font = FontSet.montserratMedium.font(14)
        cancellationLabel.textColor = ColorSet.fgGreen.uiColor
        cancellationLabel.numberOfLines = 1
        cancellationLabel.isHidden = true

        var hasCancellation = false
        if isActivity {
            // Prefer the explicit `full_refundable` POI tag → standard "Free Cancellation" label.
            if let tags = step.poi?.tags,
               tags.contains(where: { $0.lowercased() == "full_refundable" }) {
                cancellationLabel.text = CommonLocalizationKeys.localized(CommonLocalizationKeys.freeCancellation)
                cancellationLabel.isHidden = false
                hasCancellation = true
            } else if let info = bookingProduct?.info, !info.isEmpty,
                      let cancellation = info.first(where: { $0.lowercased().contains("cancel") || $0.lowercased().contains("refund") }) {
                // Fallback: cancellation text carried in the booking product info.
                cancellationLabel.text = cancellation
                cancellationLabel.isHidden = false
                hasCancellation = true
            }
        }

        let priceRowContainer = UIView()
        priceRowContainer.translatesAutoresizingMaskIntoConstraints = false
        priceRowContainer.isHidden = true

        let priceRow = UIStackView()
        priceRow.translatesAutoresizingMaskIntoConstraints = false
        priceRow.axis = .horizontal
        priceRow.spacing = 4
        priceRow.alignment = .center

        if isActivity {
            let resolvedPrice: Double? = step.poi?.additionalData?.price
                ?? bookingProduct?.price
                ?? step.poi?.price.map { Double($0) }

            if let price = resolvedPrice, price > 0 {
                let currency = step.poi?.additionalData?.currency ?? bookingProduct?.currency ?? "EUR"

                let fromLabel = UILabel()
                fromLabel.font = FontSet.montserratMedium.font(14)
                fromLabel.textColor = ColorSet.primaryText.uiColor
                fromLabel.text = CommonLocalizationKeys.localized(CommonLocalizationKeys.from)

                let priceLabel = UILabel()
                priceLabel.font = FontSet.montserratBold.font(16)
                priceLabel.textColor = ColorSet.primaryText.uiColor
                priceLabel.text = TRPCurrencyHelper.formatPrice(price, currency: currency)

                priceRow.addArrangedSubview(fromLabel)
                priceRow.addArrangedSubview(priceLabel)
            } else {
                let freeLabel = UILabel()
                freeLabel.font = FontSet.montserratBold.font(16)
                freeLabel.textColor = ColorSet.primaryText.uiColor
                freeLabel.text = CommonLocalizationKeys.localized(CommonLocalizationKeys.free)

                priceRow.addArrangedSubview(freeLabel)
            }

            priceRowContainer.addSubview(priceRow)
            NSLayoutConstraint.activate([
                priceRow.topAnchor.constraint(equalTo: priceRowContainer.topAnchor),
                priceRow.bottomAnchor.constraint(equalTo: priceRowContainer.bottomAnchor),
                priceRow.trailingAnchor.constraint(equalTo: priceRowContainer.trailingAnchor),
            ])
            priceRowContainer.isHidden = false
        }

        let reservationButton = TRPButton(title: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.reservation), style: .primary, height: 40)
        reservationButton.translatesAutoresizingMaskIntoConstraints = false
        reservationButton.tag = steps.firstIndex(where: { $0.id == step.id }) ?? 0
        reservationButton.addTarget(self, action: #selector(reservationTapped(_:)), for: .touchUpInside)
        reservationButton.isHidden = !isActivity
        stepReservationButtons.append(reservationButton)

        containerView.addSubview(timeBadgeView)
        containerView.addSubview(contentContainer)
        contentContainer.addSubview(poiImageView)
        contentContainer.addSubview(infoStackView)

        infoStackView.addArrangedSubview(titleRow)
        if isActivity {
            infoStackView.addArrangedSubview(ratingStack)
        }
        infoStackView.addArrangedSubview(categoryBadge)

        if isActivity {
            if hasDuration {
                infoStackView.addArrangedSubview(durationStack)
            }
            if hasCancellation {
                infoStackView.addArrangedSubview(cancellationLabel)
            }
            infoStackView.addArrangedSubview(priceRowContainer)
            priceRowContainer.widthAnchor.constraint(equalTo: infoStackView.widthAnchor).isActive = true
        }

        if isActivity {
            infoStackView.addArrangedSubview(reservationButton)
            NSLayoutConstraint.activate([
                reservationButton.heightAnchor.constraint(equalToConstant: 40),
                reservationButton.widthAnchor.constraint(equalTo: infoStackView.widthAnchor)
            ])
        }

        NSLayoutConstraint.activate([
            timeBadgeView.topAnchor.constraint(equalTo: containerView.topAnchor),
            timeBadgeView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),

            contentContainer.topAnchor.constraint(equalTo: timeBadgeView.bottomAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            poiImageView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            poiImageView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            poiImageView.widthAnchor.constraint(equalToConstant: 80),
            poiImageView.heightAnchor.constraint(equalToConstant: 80),

            infoStackView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            infoStackView.leadingAnchor.constraint(equalTo: poiImageView.trailingAnchor, constant: 16),
            infoStackView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),

            titleRow.widthAnchor.constraint(equalTo: infoStackView.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: titleRow.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: titleRow.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: actionButtonsStack.leadingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(equalTo: titleRow.bottomAnchor),

            actionButtonsStack.topAnchor.constraint(equalTo: titleRow.topAnchor),
            actionButtonsStack.trailingAnchor.constraint(equalTo: titleRow.trailingAnchor, constant: 8),

            changeTimeButton.widthAnchor.constraint(equalToConstant: 36),
            changeTimeButton.heightAnchor.constraint(equalToConstant: 32),
            removeStepButton.widthAnchor.constraint(equalToConstant: 40),
            removeStepButton.heightAnchor.constraint(equalToConstant: 32),

            categoryLabel.topAnchor.constraint(equalTo: categoryBadge.topAnchor, constant: 4),
            categoryLabel.bottomAnchor.constraint(equalTo: categoryBadge.bottomAnchor, constant: -4),
            categoryLabel.leadingAnchor.constraint(equalTo: categoryBadge.leadingAnchor, constant: 8),
            categoryLabel.trailingAnchor.constraint(equalTo: categoryBadge.trailingAnchor, constant: -8),
        ])

        contentContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true

        // Grows to fit info stack when taller than image; doesn't pull it down when shorter.
        contentContainer.bottomAnchor.constraint(greaterThanOrEqualTo: infoStackView.bottomAnchor).isActive = true

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(recommendationTapped(_:)))
        tapGesture.delegate = TRPDisabledControlAwareTapDelegate.shared
        contentContainer.addGestureRecognizer(tapGesture)
        contentContainer.tag = steps.firstIndex(where: { $0.id == step.id }) ?? 0

        return containerView
    }
    
    @objc private func recommendationTapped(_ sender: UITapGestureRecognizer) {
        guard let tag = sender.view?.tag, tag < steps.count else { return }
        delegate?.recommendationsCellDidSelectStep(self, step: steps[tag])
    }

    @objc private func changeTimeTapped(_ sender: UIButton) {
        guard !isPastDayMode else { return }
        let tag = sender.tag
        guard tag < steps.count else { return }
        delegate?.recommendationsCellDidTapChangeTime(self, step: steps[tag])
    }

    @objc private func removeStepTapped(_ sender: UIButton) {
        guard !isPastDayMode else { return }
        let tag = sender.tag
        guard tag < steps.count else { return }
        delegate?.recommendationsCellDidTapRemoveStep(self, step: steps[tag])
    }

    @objc private func reservationTapped(_ sender: UIButton) {
        guard !isPastDayMode else { return }
        let tag = sender.tag
        guard tag < steps.count else { return }
        delegate?.recommendationsCellDidTapReservation(self, step: steps[tag])
    }

    // MARK: - Accommodation View
    private func createAccommodationView(name: String) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor
        containerView.layer.cornerRadius = 18

        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        if let pinIcon = TRPImageController().getImage(inFramework: "ic_pin", inApp: nil) {
            iconImageView.image = pinIcon.withRenderingMode(.alwaysTemplate)
        }
        iconImageView.tintColor = ColorSet.fg.uiColor
        iconImageView.contentMode = .scaleAspectFit

        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = FontSet.montserratMedium.font(14)
        nameLabel.textColor = ColorSet.primaryText.uiColor
        nameLabel.text = name
        nameLabel.numberOfLines = 0

        containerView.addSubview(iconImageView)
        containerView.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),

            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 13),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            nameLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),

            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        ])

        return containerView
    }

    // MARK: - Distance View
    private func createDistanceView(for index: Int) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear

        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = TRPImageController().getImage(inFramework: "ic_walk", inApp: nil)
        iconImageView.contentMode = .scaleAspectFit

        let distanceLabel = UILabel()
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.font = FontSet.montserratMedium.font(12)
        distanceLabel.textColor = ColorSet.fgWeak.uiColor
//        distanceLabel.text = "Calculating..."
        distanceLabel.tag = 1000 + index

        let horizontalLine = UIView()
        horizontalLine.translatesAutoresizingMaskIntoConstraints = false
        horizontalLine.backgroundColor = ColorSet.lineWeak.uiColor
        horizontalLine.layer.cornerRadius = 0.5
        
        containerView.addSubview(iconImageView)
        containerView.addSubview(distanceLabel)
        containerView.addSubview(horizontalLine)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 4),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 13),
            iconImageView.heightAnchor.constraint(equalToConstant: 16),

            distanceLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 6),
            distanceLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            horizontalLine.leadingAnchor.constraint(equalTo: distanceLabel.trailingAnchor, constant: 4),
            horizontalLine.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            horizontalLine.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            horizontalLine.heightAnchor.constraint(equalToConstant: 0.5),

            containerView.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        return containerView
    }
    
    public func updateDistance(at index: Int, distance: Float, time: Int) {
        guard let distanceView = distanceViews[index] else { return }

        if let distanceLabel = distanceView.viewWithTag(1000 + index) as? UILabel {
            let distanceString = String(format: "%.1f", distance).replacingOccurrences(of: ".", with: ",")
            distanceLabel.text = TimelineLocalizationKeys.formatDistance(minutes: time, kilometers: distanceString)
        }
    }

}

