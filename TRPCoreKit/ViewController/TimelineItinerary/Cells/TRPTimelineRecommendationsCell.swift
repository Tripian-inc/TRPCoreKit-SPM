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
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
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
    func configure(with steps: [TRPTimelineStep], segment: TRPTimelineSegment?, isExpanded: Bool = true) {
        self.steps = steps
        self.segment = segment
        self.isExpanded = isExpanded

        // Set segment title
        titleLabel.text = segment?.title ?? "Recommendations"

        // Clear existing views and distance views
        recommendationsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        distanceViews.removeAll()

        // Add recommendation views for each step with distance info between them
        for (index, step) in steps.enumerated() {
            let recommendationView = createRecommendationView(for: step)
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
    
    private func createRecommendationView(for step: TRPTimelineStep) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear

        // Check if this is an activity step
        let isActivity = step.stepType == "activity"

        // Time badge view
        let timeBadgeView = TRPTimelineTimeBadgeView()
        timeBadgeView.translatesAutoresizingMaskIntoConstraints = false

        if let startTime = step.getStartTime(), let endTime = step.getEndTime() {
            let style: TRPTimelineTimeBadgeStyle = isActivity ? .activity : .poi
            timeBadgeView.configure(order: step.order, startTime: startTime, endTime: endTime, style: style)
        }

        // Vertical line between time badge and content
        let verticalLineView = UIView()
        verticalLineView.translatesAutoresizingMaskIntoConstraints = false
        verticalLineView.backgroundColor = ColorSet.lineWeak.uiColor

        // Content container (horizontal layout: image | info)
        let contentContainer = UIView()
        contentContainer.translatesAutoresizingMaskIntoConstraints = false

        // POI Image
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

        // Title label
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = FontSet.montserratSemiBold.font(14)
        titleLabel.textColor = ColorSet.fg.uiColor
        titleLabel.numberOfLines = 2
        titleLabel.text = step.poi?.name ?? ""

        // Action buttons container (change time + remove step)
        let actionButtonsStack = UIStackView()
        actionButtonsStack.translatesAutoresizingMaskIntoConstraints = false
        actionButtonsStack.axis = .horizontal
        actionButtonsStack.spacing = 8
        actionButtonsStack.alignment = .center

        // Change time button (hidden for activity steps)
        let changeTimeButton = UIButton(type: .custom)
        changeTimeButton.translatesAutoresizingMaskIntoConstraints = false
        changeTimeButton.setImage(TRPImageController().getImage(inFramework: "ic_change_time", inApp: nil), for: .normal)
        changeTimeButton.tag = steps.firstIndex(where: { $0.id == step.id }) ?? 0
        changeTimeButton.addTarget(self, action: #selector(changeTimeTapped(_:)), for: .touchUpInside)
        changeTimeButton.isHidden = isActivity

        // Remove step button
        let removeStepButton = UIButton(type: .custom)
        removeStepButton.translatesAutoresizingMaskIntoConstraints = false
        removeStepButton.setImage(TRPImageController().getImage(inFramework: "ic_remove_step", inApp: nil), for: .normal)
        removeStepButton.tag = steps.firstIndex(where: { $0.id == step.id }) ?? 0
        removeStepButton.addTarget(self, action: #selector(removeStepTapped(_:)), for: .touchUpInside)

        actionButtonsStack.addArrangedSubview(changeTimeButton)
        actionButtonsStack.addArrangedSubview(removeStepButton)

        // Add to title row
        titleRow.addSubview(titleLabel)
        titleRow.addSubview(actionButtonsStack)

        // Rating stack
        let ratingStack = UIStackView()
        ratingStack.translatesAutoresizingMaskIntoConstraints = false
        ratingStack.axis = .horizontal
        ratingStack.spacing = 4
        ratingStack.alignment = .center

        if let poi = step.poi, let rating = poi.rating {
            let ratingLabel = UILabel()
            ratingLabel.font = FontSet.montserratBold.font(12)
            ratingLabel.textColor = ColorSet.fg.uiColor
            ratingLabel.text = String(format: "%.1f", rating).replacingOccurrences(of: ".", with: ",")

            let starIcon = UIImageView()
            starIcon.image = TRPImageController().getImage(inFramework: "ic_rating_star", inApp: nil)
            starIcon.tintColor = ColorSet.ratingStar.uiColor
            starIcon.translatesAutoresizingMaskIntoConstraints = false
            starIcon.widthAnchor.constraint(equalToConstant: 12).isActive = true
            starIcon.heightAnchor.constraint(equalToConstant: 12).isActive = true

            let reviewLabel = UILabel()
            reviewLabel.font = FontSet.montserratRegular.font(12)
            reviewLabel.textColor = ColorSet.fgWeak.uiColor
            if let reviewCount = poi.ratingCount {
                reviewLabel.text = "\(reviewCount.formattedWithSeparator) opiniones"
            }

            ratingStack.addArrangedSubview(ratingLabel)
            ratingStack.addArrangedSubview(starIcon)
            ratingStack.addArrangedSubview(reviewLabel)
        }

        // Get booking product for activity info
        let bookingProduct = step.poi?.bookings?.first?.firstProduct()

        // Duration view (for activity steps)
        let durationStack = UIStackView()
        durationStack.translatesAutoresizingMaskIntoConstraints = false
        durationStack.axis = .horizontal
        durationStack.spacing = 4
        durationStack.alignment = .center
        durationStack.isHidden = !isActivity

        if isActivity {
            let durationIcon = UIImageView()
            durationIcon.translatesAutoresizingMaskIntoConstraints = false
            durationIcon.image = UIImage(systemName: "clock")
            durationIcon.tintColor = ColorSet.fgWeak.uiColor
            durationIcon.contentMode = .scaleAspectFit

            let durationLabel = UILabel()
            durationLabel.font = FontSet.montserratRegular.font(12)
            durationLabel.textColor = ColorSet.fgWeak.uiColor

            // Get duration from booking product or POI
            if let duration = bookingProduct?.duration {
                durationLabel.text = duration
                durationStack.isHidden = false
            } else if let poiDuration = step.poi?.duration {
                let hours = poiDuration / 60
                let minutes = poiDuration % 60
                if hours > 0 && minutes > 0 {
                    durationLabel.text = "\(hours)h \(minutes)m"
                } else if hours > 0 {
                    durationLabel.text = "\(hours)h"
                } else {
                    durationLabel.text = "\(minutes)m"
                }
                durationStack.isHidden = false
            } else {
                durationStack.isHidden = true
            }

            durationStack.addArrangedSubview(durationIcon)
            durationStack.addArrangedSubview(durationLabel)

            NSLayoutConstraint.activate([
                durationIcon.widthAnchor.constraint(equalToConstant: 14),
                durationIcon.heightAnchor.constraint(equalToConstant: 14),
            ])
        }

        // Cancellation view (for activity steps)
        let cancellationStack = UIStackView()
        cancellationStack.translatesAutoresizingMaskIntoConstraints = false
        cancellationStack.axis = .horizontal
        cancellationStack.spacing = 4
        cancellationStack.alignment = .center
        cancellationStack.isHidden = true

        if isActivity, let info = bookingProduct?.info, !info.isEmpty {
            // Look for cancellation info in the info array
            let cancellationInfo = info.first { $0.lowercased().contains("cancel") || $0.lowercased().contains("refund") }
            if let cancellation = cancellationInfo ?? info.first {
                let cancellationIcon = UIImageView()
                cancellationIcon.translatesAutoresizingMaskIntoConstraints = false
                cancellationIcon.image = UIImage(systemName: "checkmark.circle")
                cancellationIcon.tintColor = ColorSet.fgGreen.uiColor
                cancellationIcon.contentMode = .scaleAspectFit

                let cancellationLabel = UILabel()
                cancellationLabel.font = FontSet.montserratRegular.font(12)
                cancellationLabel.textColor = ColorSet.fgGreen.uiColor
                cancellationLabel.text = cancellation
                cancellationLabel.numberOfLines = 1

                cancellationStack.addArrangedSubview(cancellationIcon)
                cancellationStack.addArrangedSubview(cancellationLabel)
                cancellationStack.isHidden = false

                NSLayoutConstraint.activate([
                    cancellationIcon.widthAnchor.constraint(equalToConstant: 14),
                    cancellationIcon.heightAnchor.constraint(equalToConstant: 14),
                ])
            }
        }

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
            categoryLabel.text = "Activity"
        } else {
            categoryBadge.backgroundColor = ColorSet.bgBlue.uiColor
            categoryLabel.textColor = ColorSet.fgBlue.uiColor
            if let poi = step.poi, let firstCategory = poi.categories.first {
                categoryLabel.text = firstCategory.name
            } else {
                categoryLabel.text = "Punto de interés"
            }
        }

        categoryBadge.addSubview(categoryLabel)
        let priceRow = UIView()
        priceRow.translatesAutoresizingMaskIntoConstraints = false

        // Price label (for activity steps - bottom right)
        let priceLabel = UILabel()
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.font = FontSet.montserratBold.font(16)
        priceLabel.textColor = ColorSet.fg.uiColor
        priceLabel.textAlignment = .right

        if isActivity {
            // First priority: POI additionalData (from API response for activity steps)
            if let price = step.poi?.additionalData?.price, let currency = step.poi?.additionalData?.currency {
                let priceString = String(format: "%.2f", price).replacingOccurrences(of: ".", with: ",")
                priceLabel.text = "\(priceString) \(currency)"
            }
            // Second priority: booking product price
            else if let price = bookingProduct?.price, let currency = bookingProduct?.currency {
                let priceString = String(format: "%.2f", price).replacingOccurrences(of: ".", with: ",")
                priceLabel.text = "\(priceString) \(currency)"
            }
            // Third priority: POI price
            else if let poiPrice = step.poi?.price, poiPrice > 0 {
                priceLabel.text = "\(poiPrice) €"
            }
        }

        // Category + Price row
        let categoryPriceRow = UIView()
        categoryPriceRow.translatesAutoresizingMaskIntoConstraints = false
        categoryPriceRow.addSubview(categoryBadge)
        categoryPriceRow.addSubview(priceLabel)

        // Reservation button (TRPButton primary for activity steps)
        let reservationButton = TRPButton(title: "Reservation", style: .primary, height: 40)
        reservationButton.tag = steps.firstIndex(where: { $0.id == step.id }) ?? 0
        reservationButton.addTarget(self, action: #selector(reservationTapped(_:)), for: .touchUpInside)
        reservationButton.isHidden = !isActivity

        // Add all subviews
        containerView.addSubview(timeBadgeView)
        containerView.addSubview(verticalLineView)
        containerView.addSubview(contentContainer)
        contentContainer.addSubview(poiImageView)
        contentContainer.addSubview(infoStackView)

        // Build info stack view
        infoStackView.addArrangedSubview(titleRow)
        infoStackView.addArrangedSubview(ratingStack)
        infoStackView.addArrangedSubview(durationStack)
        infoStackView.addArrangedSubview(cancellationStack)
        infoStackView.addArrangedSubview(categoryPriceRow)
        infoStackView.addArrangedSubview(reservationButton)

        // Constraints
        NSLayoutConstraint.activate([
            // Time badge
            timeBadgeView.topAnchor.constraint(equalTo: containerView.topAnchor),
            timeBadgeView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),

            // Vertical line (between time badge and content)
            verticalLineView.topAnchor.constraint(equalTo: timeBadgeView.bottomAnchor),
            verticalLineView.leadingAnchor.constraint(equalTo: timeBadgeView.leadingAnchor, constant: 25),
            verticalLineView.widthAnchor.constraint(equalToConstant: 0.5),
            verticalLineView.bottomAnchor.constraint(equalTo: contentContainer.topAnchor),

            // Content container
            contentContainer.topAnchor.constraint(equalTo: timeBadgeView.bottomAnchor, constant: 24),
            contentContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            contentContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),

            // POI Image
            poiImageView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            poiImageView.bottomAnchor.constraint(greaterThanOrEqualTo: contentContainer.bottomAnchor),
            poiImageView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            poiImageView.widthAnchor.constraint(equalToConstant: 80),
            poiImageView.heightAnchor.constraint(equalToConstant: 80),

            // Info stack view
            infoStackView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            infoStackView.leadingAnchor.constraint(equalTo: poiImageView.trailingAnchor, constant: 12),
            infoStackView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            infoStackView.bottomAnchor.constraint(greaterThanOrEqualTo: contentContainer.bottomAnchor),

            // Title row - full width
            titleRow.widthAnchor.constraint(equalTo: infoStackView.widthAnchor),

            // Title label inside title row
            titleLabel.topAnchor.constraint(equalTo: titleRow.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: titleRow.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: actionButtonsStack.leadingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(equalTo: titleRow.bottomAnchor),

            // Action buttons stack inside title row
            actionButtonsStack.topAnchor.constraint(equalTo: titleRow.topAnchor),
            actionButtonsStack.trailingAnchor.constraint(equalTo: titleRow.trailingAnchor),

            // Button sizes
            changeTimeButton.widthAnchor.constraint(equalToConstant: 28),
            changeTimeButton.heightAnchor.constraint(equalToConstant: 28),
            removeStepButton.widthAnchor.constraint(equalToConstant: 28),
            removeStepButton.heightAnchor.constraint(equalToConstant: 28),

            // Category + Price row - full width
            categoryPriceRow.widthAnchor.constraint(equalTo: infoStackView.widthAnchor),

            // Category badge inside category price row
            categoryBadge.topAnchor.constraint(equalTo: categoryPriceRow.topAnchor),
            categoryBadge.leadingAnchor.constraint(equalTo: categoryPriceRow.leadingAnchor),
            categoryBadge.bottomAnchor.constraint(equalTo: categoryPriceRow.bottomAnchor),

            // Category label inside badge
            categoryLabel.topAnchor.constraint(equalTo: categoryBadge.topAnchor, constant: 4),
            categoryLabel.bottomAnchor.constraint(equalTo: categoryBadge.bottomAnchor, constant: -4),
            categoryLabel.leadingAnchor.constraint(equalTo: categoryBadge.leadingAnchor, constant: 8),
            categoryLabel.trailingAnchor.constraint(equalTo: categoryBadge.trailingAnchor, constant: -8),

            // Price label inside category price row (right side)
            priceLabel.centerYAnchor.constraint(equalTo: categoryBadge.centerYAnchor),
            priceLabel.trailingAnchor.constraint(equalTo: categoryPriceRow.trailingAnchor),
            priceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: categoryBadge.trailingAnchor, constant: 8),

            // Reservation button - full width
            reservationButton.widthAnchor.constraint(equalTo: infoStackView.widthAnchor),
        ])

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
            distanceLabel.text = "\(time) min (\(distanceString) km)"
        }
    }
}

