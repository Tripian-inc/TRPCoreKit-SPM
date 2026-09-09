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
        let row = TRPTimelineStepRowView(step: step, order: order)
        row.onTap = { [weak self] step in
            guard let self = self else { return }
            self.delegate?.recommendationsCellDidSelectStep(self, step: step)
        }
        row.onChangeTime = { [weak self] step in
            guard let self = self, !self.isPastDayMode else { return }
            self.delegate?.recommendationsCellDidTapChangeTime(self, step: step)
        }
        row.onRemove = { [weak self] step in
            guard let self = self, !self.isPastDayMode else { return }
            self.delegate?.recommendationsCellDidTapRemoveStep(self, step: step)
        }
        row.onReservation = { [weak self] step in
            guard let self = self, !self.isPastDayMode else { return }
            self.delegate?.recommendationsCellDidTapReservation(self, step: step)
        }
        stepReservationButtons.append(contentsOf: row.reservationButtons)
        stepActionButtons.append(contentsOf: row.actionButtons)
        return row
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
        iconImageView.tag = 2000 + index

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
    
    func updateDistance(at index: Int, routeInfo: TRPStepRouteInfo) {
        guard let distanceView = distanceViews[index] else { return }

        if let iconImageView = distanceView.viewWithTag(2000 + index) as? UIImageView {
            let iconName = routeInfo.isWalking ? "ic_walk" : "icon_car"
            iconImageView.image = TRPImageController().getImage(inFramework: iconName, inApp: nil)
        }

        if let distanceLabel = distanceView.viewWithTag(1000 + index) as? UILabel {
            let distanceString = String(format: "%.1f", routeInfo.distance).replacingOccurrences(of: ".", with: ",")
            distanceLabel.text = TimelineLocalizationKeys.formatDistance(minutes: routeInfo.time, kilometers: distanceString)
        }
    }

}

