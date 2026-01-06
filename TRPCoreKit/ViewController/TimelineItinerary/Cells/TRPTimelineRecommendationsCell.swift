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
    func recommendationsCellNeedsRouteCalculation(_ cell: TRPTimelineRecommendationsCell, from: TRPLocation, to: TRPLocation, index: Int)
}

class TRPTimelineRecommendationsCell: UITableViewCell {

    static let reuseIdentifier = "TRPTimelineRecommendationsCell"

    weak var delegate: TRPTimelineRecommendationsCellDelegate?
    private var steps: [TRPTimelineStep] = []
    private var segment: TRPTimelineSegment?
    private var isExpanded: Bool = true
    private var distanceViews: [Int: UIView] = [:] // Track distance views by index
    private var startingOrder: Int = 1 // Unified day order for first step
    
    // MARK: - UI Components
    private let containerView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 12
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
    
    // Header components
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
    
    private let chevronButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(TRPImageController().getImage(inFramework: "ic_recom_arrow", inApp: nil), for: .normal)
        button.tintColor = ColorSet.fg.uiColor
        return button
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(TRPImageController().getImage(inFramework: "ic_close", inApp: nil), for: .normal)
        button.tintColor = ColorSet.fg.uiColor
        button.backgroundColor = .white
        button.layer.borderWidth = 1
        button.layer.borderColor = ColorSet.neutral200.uiColor.cgColor
        button.layer.cornerRadius = 20
        return button
    }()
    
    // Recommendations stack
    private let recommendationsStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16
        stack.isHidden = false
        return stack
    }()
    
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

        // Add views to container stack view
        containerView.addArrangedSubview(headerView)
        containerView.addArrangedSubview(recommendationsStackView)

        headerView.addSubview(titleLabel)
        headerView.addSubview(chevronButton)
        headerView.addSubview(closeButton)

        NSLayoutConstraint.activate([
            // Container View
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            // Header View
            headerView.heightAnchor.constraint(equalToConstant: 44),

            // Title Label
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            // Chevron Button
            chevronButton.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 10),
            chevronButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            chevronButton.widthAnchor.constraint(equalToConstant: 16),
            chevronButton.heightAnchor.constraint(equalToConstant: 16),

            // Close Button
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),
        ])

        setupActions()
    }
    
    private func setupActions() {
        let chevronTap = UITapGestureRecognizer(target: self, action: #selector(toggleTapped))
        headerView.addGestureRecognizer(chevronTap)

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func toggleTapped() {
        isExpanded.toggle()
        updateChevron(animated: true)

        // Animate the collapse/expand using UIStackView's automatic hiding
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
        let rotation: CGFloat = isExpanded ? 0 : .pi // 0° for expanded (down), 180° for collapsed (up)

        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
                self.chevronButton.transform = CGAffineTransform(rotationAngle: rotation)
            }
        } else {
            chevronButton.transform = CGAffineTransform(rotationAngle: rotation)
        }
    }
    
    // MARK: - Configuration
    func configure(with steps: [TRPTimelineStep], segment: TRPTimelineSegment?, isExpanded: Bool = true, startingOrder: Int = 1) {
        self.steps = steps
        self.segment = segment
        self.isExpanded = isExpanded
        self.startingOrder = startingOrder

        // Set segment title
        titleLabel.text = segment?.title ?? TimelineLocalizationKeys.localized(TimelineLocalizationKeys.recommendations)

        // Clear existing views and distance views
        recommendationsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        distanceViews.removeAll()

        // Add recommendation views for each step with distance info between them
        for (index, step) in steps.enumerated() {
            // Calculate unified order: startingOrder + index (0-based)
            let unifiedOrder = startingOrder + index
            let recommendationView = createRecommendationView(for: step, order: unifiedOrder)
            recommendationsStackView.addArrangedSubview(recommendationView)

            // Add distance view between POIs (except after the last one)
            if index < steps.count - 1 {
                let distanceView = createDistanceView(for: index)
                distanceViews[index] = distanceView
                recommendationsStackView.addArrangedSubview(distanceView)

                // Request route calculation if both POIs have coordinates
                if let fromCoordinate = step.poi?.coordinate, let toCoordinate = steps[index + 1].poi?.coordinate {
                    delegate?.recommendationsCellNeedsRouteCalculation(self,
                                                                       from: fromCoordinate,
                                                                       to: toCoordinate,
                                                                       index: index)
                }
            }
        }

        updateChevron()

        // Set UI based on collapse state - UIStackView handles layout automatically
        recommendationsStackView.isHidden = !isExpanded
        recommendationsStackView.alpha = isExpanded ? 1.0 : 0.0
    }

    // MARK: - Configuration with Pre-computed Data

    /// Configure cell with pre-computed RecommendationsCellData
    func configure(with cellData: RecommendationsCellData) {
        self.steps = cellData.steps
        self.segment = cellData.segment
        self.isExpanded = cellData.isExpanded
        self.startingOrder = cellData.startingOrder

        // Title (pre-computed)
        titleLabel.text = cellData.title

        // Clear existing views and distance views
        recommendationsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        distanceViews.removeAll()

        // Add recommendation views for each step with distance info between them
        for (index, step) in cellData.steps.enumerated() {
            // Calculate unified order: startingOrder + index (0-based)
            let unifiedOrder = startingOrder + index
            let recommendationView = createRecommendationView(for: step, order: unifiedOrder)
            recommendationsStackView.addArrangedSubview(recommendationView)

            // Add distance view between POIs (except after the last one)
            if index < cellData.steps.count - 1 {
                let distanceView = createDistanceView(for: index)
                distanceViews[index] = distanceView
                recommendationsStackView.addArrangedSubview(distanceView)

                // Request route calculation if both POIs have coordinates
                if let fromCoordinate = step.poi?.coordinate,
                   let toCoordinate = cellData.steps[index + 1].poi?.coordinate {
                    delegate?.recommendationsCellNeedsRouteCalculation(
                        self,
                        from: fromCoordinate,
                        to: toCoordinate,
                        index: index
                    )
                }
            }
        }

        updateChevron()

        // Set UI based on collapse state
        recommendationsStackView.isHidden = !cellData.isExpanded
        recommendationsStackView.alpha = cellData.isExpanded ? 1.0 : 0.0
    }

    private func createRecommendationView(for step: TRPTimelineStep, order: Int) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear

        // Check if this is an activity step
        let isActivity = step.stepType == "activity"

        // Time badge view
        let timeBadgeView = TRPTimelineTimeBadgeView()
        timeBadgeView.translatesAutoresizingMaskIntoConstraints = false

        if let startTime = step.getStartTime(), let endTime = step.getEndTime() {
            // Use unified order (startingOrder + index) instead of step.order
            timeBadgeView.configure(order: order, startTime: startTime, endTime: endTime)
        }

        // Content container (horizontal layout: image | info)
        let contentContainer = UIView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false

        // POI Image - 80x80
        let poiImageView = UIImageView()
        poiImageView.translatesAutoresizingMaskIntoConstraints = false
        poiImageView.contentMode = .scaleAspectFill
        poiImageView.clipsToBounds = true
        poiImageView.layer.cornerRadius = 8
        poiImageView.backgroundColor = ColorSet.bgDisabled.uiColor

        if let poi = step.poi, let imageUrl = poi.image?.url {
            poiImageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: nil)
        }

        // Right side info container - using stack view for auto height adjustment
        let infoStackView = UIStackView()
        infoStackView.translatesAutoresizingMaskIntoConstraints = false
        infoStackView.axis = .vertical
        infoStackView.spacing = 4
        infoStackView.alignment = .leading
        infoStackView.distribution = .fill

        // Title row (title + action buttons)
        let titleRow = UIView()
        titleRow.translatesAutoresizingMaskIntoConstraints = false

        // Title label - semibold 16px, numberOfLines 0
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = FontSet.montserratSemiBold.font(16)
        titleLabel.textColor = ColorSet.primaryText.uiColor
        titleLabel.numberOfLines = 0
        titleLabel.text = step.poi?.name ?? ""

        // Action buttons container (change time + remove step) - spacing 2, right margin 12
        let actionButtonsStack = UIStackView()
        actionButtonsStack.translatesAutoresizingMaskIntoConstraints = false
        actionButtonsStack.axis = .horizontal
        actionButtonsStack.spacing = 2
        actionButtonsStack.alignment = .center

        // Change time button - 32x32, icon 20x20 (hidden for activity steps)
        let changeTimeButton = UIButton(type: .custom)
        changeTimeButton.translatesAutoresizingMaskIntoConstraints = false
        let changeTimeIcon = TRPImageController().getImage(inFramework: "ic_change_time", inApp: nil)?.withRenderingMode(.alwaysTemplate)
        changeTimeButton.setImage(changeTimeIcon, for: .normal)
        changeTimeButton.tintColor = ColorSet.primary.uiColor
        changeTimeButton.imageView?.contentMode = .scaleAspectFit
        changeTimeButton.contentVerticalAlignment = .center
        changeTimeButton.contentHorizontalAlignment = .center
        changeTimeButton.tag = steps.firstIndex(where: { $0.id == step.id }) ?? 0
        changeTimeButton.addTarget(self, action: #selector(changeTimeTapped(_:)), for: .touchUpInside)
        changeTimeButton.isHidden = isActivity

        // Remove step button - 32x32, icon 20x20
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

        // Add to title row
        titleRow.addSubview(titleLabel)
        titleRow.addSubview(actionButtonsStack)

        // Rating stack - bold 14px for rating, light 14px for reviewCount
        let ratingStack = UIStackView()
        ratingStack.translatesAutoresizingMaskIntoConstraints = false
        ratingStack.axis = .horizontal
        ratingStack.spacing = 0 // We'll use custom spacing
        ratingStack.alignment = .center

        if let poi = step.poi, let rating = poi.rating {
            // Rating label - bold 14px primaryText
            let ratingLabel = UILabel()
            ratingLabel.font = FontSet.montserratBold.font(14)
            ratingLabel.textColor = ColorSet.primaryText.uiColor
            ratingLabel.text = String(format: "%.1f", rating).replacingOccurrences(of: ".", with: ",")

            // Spacer view for 2px margin between rating and star
            let spacer1 = UIView()
            spacer1.translatesAutoresizingMaskIntoConstraints = false
            spacer1.widthAnchor.constraint(equalToConstant: 2).isActive = true

            // Star icon
            let starIcon = UIImageView()
            starIcon.image = TRPImageController().getImage(inFramework: "ic_rating_star", inApp: nil)
            starIcon.tintColor = ColorSet.ratingStar.uiColor
            starIcon.translatesAutoresizingMaskIntoConstraints = false
            starIcon.contentMode = .scaleAspectFit
            starIcon.widthAnchor.constraint(equalToConstant: 14).isActive = true
            starIcon.heightAnchor.constraint(equalToConstant: 14).isActive = true

            // Spacer view for 4px margin between star and reviewCount
            let spacer2 = UIView()
            spacer2.translatesAutoresizingMaskIntoConstraints = false
            spacer2.widthAnchor.constraint(equalToConstant: 4).isActive = true

            // Review count label - light 14px fgWeak
            let reviewLabel = UILabel()
            reviewLabel.font = FontSet.montserratLight.font(14)
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

        // Get booking product for activity info
        let bookingProduct = step.poi?.bookings?.first?.firstProduct()

        // Category badge
        let categoryBadge = UIView()
        categoryBadge.translatesAutoresizingMaskIntoConstraints = false
        categoryBadge.layer.cornerRadius = 4
        categoryBadge.clipsToBounds = true

        let categoryLabel = UILabel()
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryLabel.font = FontSet.montserratMedium.font(10)

        if isActivity {
            categoryBadge.backgroundColor = ColorSet.bgGreen.uiColor
            categoryLabel.textColor = ColorSet.fgGreen.uiColor
            categoryLabel.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.activityBadge)
        } else {
            categoryBadge.backgroundColor = ColorSet.bgBlue.uiColor
            categoryLabel.textColor = ColorSet.fgBlue.uiColor
            if let poi = step.poi, let firstCategory = poi.categories.first {
                categoryLabel.text = firstCategory.name
            } else {
                categoryLabel.text = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.pointOfInterest)
            }
        }

        categoryBadge.addSubview(categoryLabel)

        // Duration stack (for activity steps) - icon + duration text
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
            durationIcon.image = UIImage(systemName: "clock")
            durationIcon.tintColor = ColorSet.fgWeak.uiColor
            durationIcon.contentMode = .scaleAspectFit

            let durationLabel = UILabel()
            durationLabel.font = FontSet.montserratMedium.font(14)
            durationLabel.textColor = ColorSet.fgWeak.uiColor

            // Get duration from booking product or POI
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

        // Cancellation label (for activity steps) - medium 14px fgGreen
        let cancellationLabel = UILabel()
        cancellationLabel.translatesAutoresizingMaskIntoConstraints = false
        cancellationLabel.font = FontSet.montserratMedium.font(14)
        cancellationLabel.textColor = ColorSet.fgGreen.uiColor
        cancellationLabel.numberOfLines = 1
        cancellationLabel.isHidden = true

        var hasCancellation = false
        if isActivity, let info = bookingProduct?.info, !info.isEmpty {
            let cancellationInfo = info.first { $0.lowercased().contains("cancel") || $0.lowercased().contains("refund") }
            if let cancellation = cancellationInfo {
                cancellationLabel.text = cancellation
                cancellationLabel.isHidden = false
                hasCancellation = true
            }
        }

        // Price row container (for activity steps) - right aligned
        let priceRowContainer = UIView()
        priceRowContainer.translatesAutoresizingMaskIntoConstraints = false
        priceRowContainer.isHidden = true

        // Price row - "From" medium 14px + price bold 16px
        let priceRow = UIStackView()
        priceRow.translatesAutoresizingMaskIntoConstraints = false
        priceRow.axis = .horizontal
        priceRow.spacing = 4
        priceRow.alignment = .center

        if isActivity {
            // "From" label - medium 14px primaryText
            let fromLabel = UILabel()
            fromLabel.font = FontSet.montserratMedium.font(14)
            fromLabel.textColor = ColorSet.primaryText.uiColor
            fromLabel.text = CommonLocalizationKeys.localized(CommonLocalizationKeys.from)

            // Price label - bold 16px primaryText
            let priceLabel = UILabel()
            priceLabel.font = FontSet.montserratBold.font(16)
            priceLabel.textColor = ColorSet.primaryText.uiColor

            // Get price from additionalData or booking product
            var priceText: String? = nil
            if let price = step.poi?.additionalData?.price, let currency = step.poi?.additionalData?.currency {
                let priceString = String(format: "%.2f", price).replacingOccurrences(of: ".", with: ",")
                priceText = "\(priceString) \(currency)"
            } else if let price = bookingProduct?.price, let currency = bookingProduct?.currency {
                let priceString = String(format: "%.2f", price).replacingOccurrences(of: ".", with: ",")
                priceText = "\(priceString) \(currency)"
            } else if let poiPrice = step.poi?.price, poiPrice > 0 {
                priceText = "\(poiPrice) €"
            }

            if let priceText = priceText {
                priceLabel.text = priceText
                priceRow.addArrangedSubview(fromLabel)
                priceRow.addArrangedSubview(priceLabel)

                // Add priceRow to container, aligned to right
                priceRowContainer.addSubview(priceRow)
                NSLayoutConstraint.activate([
                    priceRow.topAnchor.constraint(equalTo: priceRowContainer.topAnchor),
                    priceRow.bottomAnchor.constraint(equalTo: priceRowContainer.bottomAnchor),
                    priceRow.trailingAnchor.constraint(equalTo: priceRowContainer.trailingAnchor),
                ])
                priceRowContainer.isHidden = false
            }
        }

        // Reservation button (TRPButton primary for activity steps) - height 40
        let reservationButton = TRPButton(title: "Reservation", style: .primary, height: 40)
        reservationButton.translatesAutoresizingMaskIntoConstraints = false
        reservationButton.tag = steps.firstIndex(where: { $0.id == step.id }) ?? 0
        reservationButton.addTarget(self, action: #selector(reservationTapped(_:)), for: .touchUpInside)
        reservationButton.isHidden = !isActivity

        // Add all subviews
        containerView.addSubview(timeBadgeView)
        containerView.addSubview(contentContainer)
        contentContainer.addSubview(poiImageView)
        contentContainer.addSubview(infoStackView)

        // Build info stack view
        infoStackView.addArrangedSubview(titleRow)
        infoStackView.addArrangedSubview(ratingStack)
        infoStackView.addArrangedSubview(categoryBadge)

        // For activity: add duration (if exists), cancellation (if exists), then price, then button
        if isActivity {
            if hasDuration {
                infoStackView.addArrangedSubview(durationStack)
            }
            if hasCancellation {
                infoStackView.addArrangedSubview(cancellationLabel)
            }
            infoStackView.addArrangedSubview(priceRowContainer)
            // Price row container needs full width for right alignment
            priceRowContainer.widthAnchor.constraint(equalTo: infoStackView.widthAnchor).isActive = true
        }

        // Add reservation button for activity steps - full width
        if isActivity {
            infoStackView.addArrangedSubview(reservationButton)
            NSLayoutConstraint.activate([
                reservationButton.heightAnchor.constraint(equalToConstant: 40),
                reservationButton.widthAnchor.constraint(equalTo: infoStackView.widthAnchor)
            ])
        }

        // Constraints
        NSLayoutConstraint.activate([
            // Time badge
            timeBadgeView.topAnchor.constraint(equalTo: containerView.topAnchor),
            timeBadgeView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),

            // Content container
            contentContainer.topAnchor.constraint(equalTo: timeBadgeView.bottomAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            // POI Image - 80x80
            poiImageView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            poiImageView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            poiImageView.widthAnchor.constraint(equalToConstant: 80),
            poiImageView.heightAnchor.constraint(equalToConstant: 80),

            // Info stack view - 16px from imageView, 12px from right
            infoStackView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            infoStackView.leadingAnchor.constraint(equalTo: poiImageView.trailingAnchor, constant: 16),
            infoStackView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -12),

            // Title row - full width
            titleRow.widthAnchor.constraint(equalTo: infoStackView.widthAnchor),

            // Title label inside title row - 8px margin to buttons
            titleLabel.topAnchor.constraint(equalTo: titleRow.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: titleRow.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: actionButtonsStack.leadingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(equalTo: titleRow.bottomAnchor),

            // Action buttons stack inside title row
            actionButtonsStack.topAnchor.constraint(equalTo: titleRow.topAnchor),
            actionButtonsStack.trailingAnchor.constraint(equalTo: titleRow.trailingAnchor),

            // Button sizes - 32x32
            changeTimeButton.widthAnchor.constraint(equalToConstant: 32),
            changeTimeButton.heightAnchor.constraint(equalToConstant: 32),
            removeStepButton.widthAnchor.constraint(equalToConstant: 32),
            removeStepButton.heightAnchor.constraint(equalToConstant: 32),

            // Category label inside badge
            categoryLabel.topAnchor.constraint(equalTo: categoryBadge.topAnchor, constant: 4),
            categoryLabel.bottomAnchor.constraint(equalTo: categoryBadge.bottomAnchor, constant: -4),
            categoryLabel.leadingAnchor.constraint(equalTo: categoryBadge.leadingAnchor, constant: 8),
            categoryLabel.trailingAnchor.constraint(equalTo: categoryBadge.trailingAnchor, constant: -8),
        ])

        // Dynamic height constraints - content container expands to fit the taller of imageView or infoStackView
        // Minimum height constraint (80px for imageView)
        contentContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true

        // Info stack bottom constraint - when info is taller than 80px, it defines the height
        let infoBottomConstraint = infoStackView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        infoBottomConstraint.priority = UILayoutPriority(999)
        infoBottomConstraint.isActive = true

        // Add tap gesture for selection
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(recommendationTapped(_:)))
        contentContainer.addGestureRecognizer(tapGesture)
        contentContainer.tag = steps.firstIndex(where: { $0.id == step.id }) ?? 0

        return containerView
    }
    
    @objc private func recommendationTapped(_ sender: UITapGestureRecognizer) {
        guard let tag = sender.view?.tag, tag < steps.count else { return }
        delegate?.recommendationsCellDidSelectStep(self, step: steps[tag])
    }

    @objc private func changeTimeTapped(_ sender: UIButton) {
        let tag = sender.tag
        guard tag < steps.count else { return }
        delegate?.recommendationsCellDidTapChangeTime(self, step: steps[tag])
    }

    @objc private func removeStepTapped(_ sender: UIButton) {
        let tag = sender.tag
        guard tag < steps.count else { return }
        delegate?.recommendationsCellDidTapRemoveStep(self, step: steps[tag])
    }

    @objc private func reservationTapped(_ sender: UIButton) {
        let tag = sender.tag
        guard tag < steps.count else { return }
        delegate?.recommendationsCellDidTapReservation(self, step: steps[tag])
    }

    // MARK: - Distance View
    private func createDistanceView(for index: Int) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear
        
        // Icon
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.image = UIImage(systemName: "figure.walk")
        iconImageView.tintColor = ColorSet.fgWeak.uiColor
        iconImageView.contentMode = .scaleAspectFit
        
        // Distance label
        let distanceLabel = UILabel()
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.font = FontSet.montserratRegular.font(14)
        distanceLabel.textColor = ColorSet.fgWeak.uiColor
//        distanceLabel.text = "Calculating..."
        distanceLabel.tag = 1000 + index // Tag to identify label for updates
        
        // Horizontal line
        let horizontalLine = UIView()
        horizontalLine.translatesAutoresizingMaskIntoConstraints = false
        horizontalLine.backgroundColor = ColorSet.lineWeak.uiColor
        horizontalLine.layer.cornerRadius = 0.5
        
        containerView.addSubview(iconImageView)
        containerView.addSubview(distanceLabel)
        containerView.addSubview(horizontalLine)
        
        NSLayoutConstraint.activate([
            // Icon
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            // Distance label
            distanceLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            distanceLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            // Horizontal line
            horizontalLine.leadingAnchor.constraint(equalTo: distanceLabel.trailingAnchor, constant: 12),
            horizontalLine.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            horizontalLine.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            horizontalLine.heightAnchor.constraint(equalToConstant: 1),
            
            // Container height
            containerView.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        return containerView
    }
    
    // Update distance info after route calculation
    public func updateDistance(at index: Int, distance: Float, time: Int) {
        guard let distanceView = distanceViews[index] else { return }
        
        // Find the distance label using tag
        if let distanceLabel = distanceView.viewWithTag(1000 + index) as? UILabel {
            // Format distance with comma as decimal separator (e.g., "1,2 km")
            let distanceString = String(format: "%.1f", distance).replacingOccurrences(of: ".", with: ",")
            distanceLabel.text = TimelineLocalizationKeys.formatDistance(minutes: time, kilometers: distanceString)
        }
    }
}

