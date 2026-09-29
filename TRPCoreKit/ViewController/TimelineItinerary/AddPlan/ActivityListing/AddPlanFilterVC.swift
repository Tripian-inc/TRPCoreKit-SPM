//
//  AddPlanFilterVC.swift
//  TRPCoreKit
//
//  Created by Cem Caygoz on 06.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//

import UIKit
import TRPFoundationKit

// MARK: - Filter Data Model
public struct FilterData {
    public var minPrice: Double?
    public var maxPrice: Double?
    public var minDuration: Int?
    public var maxDuration: Int?
    /// Lowest rating, out of five, an activity needs to be listed.
    public var minRating: Double?

    public init(minPrice: Double? = nil, maxPrice: Double? = nil, minDuration: Int? = nil, maxDuration: Int? = nil, minRating: Double? = nil) {
        self.minPrice = minPrice
        self.maxPrice = maxPrice
        self.minDuration = minDuration
        self.maxDuration = maxDuration
        self.minRating = minRating
    }

    public var isEmpty: Bool {
        return minPrice == nil && maxPrice == nil && minDuration == nil && maxDuration == nil && minRating == nil
    }

    public var activeFilterCount: Int {
        var count = 0
        if minPrice != nil || maxPrice != nil {
            count += 1
        }
        if minDuration != nil || maxDuration != nil {
            count += 1
        }
        if minRating != nil {
            count += 1
        }
        return count
    }
}

// MARK: - AddPlanFilterVC
public class AddPlanFilterVC: TRPBaseUIViewController, DynamicHeightPresentable {

    // MARK: - DynamicHeightPresentable
    public var preferredContentHeight: CGFloat {
        let ratingSectionHeight: CGFloat = offersRatingFilter ? 104 : 0
        return 56 + 252 + ratingSectionHeight + 80
    }

    /// Ratings offered as a lower bound, out of five; the first chip clears the bound.
    static let minimumRatingOptions: [Double] = [3.0, 3.5, 4.0, 4.5]

    // MARK: - Properties
    private var filterData: FilterData
    public var onFilterApplied: ((FilterData) -> Void)?

    public var priceRangeFacet: TRPTourPriceRangeFacet?
    public var durationRangeFacet: TRPTourDurationRangeFacet?

    private let priceFallbackMin: Double = 0
    private let priceFallbackMax: Double = 1500
    private let durationFallbackMin: Double = 0
    private let durationFallbackMax: Double = 1440

    private var priceMinValue: Double = 0
    private var priceMaxValue: Double = 1500
    private var durationMinValue: Double = 0
    private var durationMaxValue: Double = 1440

    private let offersRatingFilter = TRPCoreKit.shared.provider.offersActivityRatingFilter
    private var selectedMinRating: Double?
    private var ratingChips: [(rating: Double?, button: RatingChipButton)] = []

    // MARK: - UI Components
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.filters)
        label.font = FontSet.montserratSemiBold.font(18)
        label.textColor = ColorSet.primaryText.uiColor
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: "xmark")
        button.setImage(image, for: .normal)
        button.tintColor = ColorSet.primaryText.uiColor
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var clearButton: TRPButton = {
        let button = TRPButton(
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.clearSelection),
            style: .secondary
        )
        return button
    }()

    private let buttonContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let priceTitleLabel: UILabel = {
        let label = UILabel()
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.filterPrice)
        label.font = FontSet.montserratSemiBold.font(16)
        label.textColor = ColorSet.primaryText.uiColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let priceSlider: TRPRangeSlider = {
        let slider = TRPRangeSlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()

    private let durationTitleLabel: UILabel = {
        let label = UILabel()
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.filterDuration)
        label.font = FontSet.montserratSemiBold.font(16)
        label.textColor = ColorSet.primaryText.uiColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let durationSlider: TRPRangeSlider = {
        let slider = TRPRangeSlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()

    private let ratingTitleLabel: UILabel = {
        let label = UILabel()
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.filterRating)
        label.font = FontSet.montserratSemiBold.font(16)
        label.textColor = ColorSet.primaryText.uiColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let ratingStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private lazy var comfitmButton: TRPButton = {
        let button = TRPButton(
            title: CommonLocalizationKeys.localized(CommonLocalizationKeys.confirm),
            style: .primary
        )
        return button
    }()

    // MARK: - Initialization
    public init(filterData: FilterData = FilterData()) {
        self.filterData = filterData
        self.selectedMinRating = filterData.minRating
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSliders()
        setupRatingChips()
    }

    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(closeButton)

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(priceTitleLabel)
        contentView.addSubview(priceSlider)
        contentView.addSubview(durationTitleLabel)
        contentView.addSubview(durationSlider)

        view.addSubview(buttonContainerView)
        buttonContainerView.addSubview(clearButton)
        buttonContainerView.addSubview(comfitmButton)

        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(clearButtonTapped), for: .touchUpInside)
        comfitmButton.addTarget(self, action: #selector(applyButtonTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 56),

            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: buttonContainerView.topAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            priceTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            priceTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            priceSlider.topAnchor.constraint(equalTo: priceTitleLabel.bottomAnchor, constant: 16),
            priceSlider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            priceSlider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            priceSlider.heightAnchor.constraint(equalToConstant: 50),

            durationTitleLabel.topAnchor.constraint(equalTo: priceSlider.bottomAnchor, constant: 32),
            durationTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            durationSlider.topAnchor.constraint(equalTo: durationTitleLabel.bottomAnchor, constant: 16),
            durationSlider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            durationSlider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            durationSlider.heightAnchor.constraint(equalToConstant: 50),

            buttonContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            buttonContainerView.heightAnchor.constraint(equalToConstant: 80),

            clearButton.leadingAnchor.constraint(equalTo: buttonContainerView.leadingAnchor, constant: 16),
            clearButton.topAnchor.constraint(equalTo: buttonContainerView.topAnchor, constant: 16),

            comfitmButton.leadingAnchor.constraint(equalTo: clearButton.trailingAnchor, constant: 16),
            comfitmButton.trailingAnchor.constraint(equalTo: buttonContainerView.trailingAnchor, constant: -16),
            comfitmButton.topAnchor.constraint(equalTo: buttonContainerView.topAnchor, constant: 16),
            comfitmButton.widthAnchor.constraint(equalTo: clearButton.widthAnchor)
        ])

        guard offersRatingFilter else {
            durationSlider.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24).isActive = true
            return
        }
        contentView.addSubview(ratingTitleLabel)
        contentView.addSubview(ratingStackView)
        NSLayoutConstraint.activate([
            ratingTitleLabel.topAnchor.constraint(equalTo: durationSlider.bottomAnchor, constant: 32),
            ratingTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            ratingStackView.topAnchor.constraint(equalTo: ratingTitleLabel.bottomAnchor, constant: 16),
            ratingStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            ratingStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            ratingStackView.heightAnchor.constraint(equalToConstant: 36),
            ratingStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    private func setupRatingChips() {
        guard offersRatingFilter else { return }
        let options: [Double?] = [nil] + Self.minimumRatingOptions
        ratingChips = options.map { rating in
            let button = RatingChipButton(title: rating.map(Self.ratingChipTitle) ?? AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.filterRatingAny),
                                          showsStar: rating != nil)
            button.addTarget(self, action: #selector(ratingChipTapped(_:)), for: .touchUpInside)
            ratingStackView.addArrangedSubview(button)
            return (rating, button)
        }
        updateRatingChips()
    }

    private func updateRatingChips() {
        ratingChips.forEach { $0.button.isChosen = $0.rating == selectedMinRating }
    }

    /// "4.5+" in the device's number format.
    static func ratingChipTitle(for rating: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return (formatter.string(from: NSNumber(value: rating)) ?? "\(rating)") + "+"
    }

    private func setupSliders() {
        priceMinValue = priceRangeFacet?.minAmount ?? priceFallbackMin
        priceMaxValue = priceRangeFacet?.maxAmount ?? priceFallbackMax
        if priceMaxValue <= priceMinValue {
            priceMinValue = priceFallbackMin
            priceMaxValue = priceFallbackMax
        }

        durationMinValue = durationRangeFacet.map { Double($0.minMinutes) } ?? durationFallbackMin
        durationMaxValue = durationRangeFacet.map { Double($0.maxMinutes) } ?? durationFallbackMax
        if durationMaxValue <= durationMinValue {
            durationMinValue = durationFallbackMin
            durationMaxValue = durationFallbackMax
        }

        let labelPlacement = TRPCoreKit.shared.provider.rangeSliderValueLabelPlacement
        priceSlider.valueLabelPlacement = labelPlacement
        durationSlider.valueLabelPlacement = labelPlacement

        priceSlider.minimumValue = priceMinValue
        priceSlider.maximumValue = priceMaxValue
        let persistedMinPrice = filterData.minPrice ?? priceMinValue
        let persistedMaxPrice = filterData.maxPrice ?? priceMaxValue
        priceSlider.lowerValue = min(max(persistedMinPrice, priceMinValue), priceMaxValue)
        priceSlider.upperValue = min(max(persistedMaxPrice, priceMinValue), priceMaxValue)
        priceSlider.valueLabelFormatter = { value in
            let intValue = Int(value)
            if intValue == 0 {
                return AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.filterFree)
            }
            return "\(intValue)€"
        }

        durationSlider.minimumValue = durationMinValue
        durationSlider.maximumValue = durationMaxValue
        let persistedMinDuration = Double(filterData.minDuration ?? Int(durationMinValue))
        let persistedMaxDuration = Double(filterData.maxDuration ?? Int(durationMaxValue))
        durationSlider.lowerValue = min(max(persistedMinDuration, durationMinValue), durationMaxValue)
        durationSlider.upperValue = min(max(persistedMaxDuration, durationMinValue), durationMaxValue)
        durationSlider.valueLabelFormatter = { [weak self] value in
            return self?.formatDuration(minutes: Int(value)) ?? "\(Int(value))m"
        }
    }

    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }

    @objc private func clearButtonTapped() {
        priceSlider.lowerValue = priceMinValue
        priceSlider.upperValue = priceMaxValue
        durationSlider.lowerValue = durationMinValue
        durationSlider.upperValue = durationMaxValue
        selectedMinRating = nil
        updateRatingChips()
    }

    @objc private func ratingChipTapped(_ sender: RatingChipButton) {
        guard let chip = ratingChips.first(where: { $0.button === sender }) else { return }
        selectedMinRating = chip.rating
        updateRatingChips()
    }

    @objc private func applyButtonTapped() {
        var newFilterData = FilterData()

        if priceSlider.lowerValue > priceMinValue {
            newFilterData.minPrice = priceSlider.lowerValue
        }
        if priceSlider.upperValue < priceMaxValue {
            newFilterData.maxPrice = priceSlider.upperValue
        }

        if durationSlider.lowerValue > durationMinValue {
            newFilterData.minDuration = Int(durationSlider.lowerValue)
        }
        if durationSlider.upperValue < durationMaxValue {
            newFilterData.maxDuration = Int(durationSlider.upperValue)
        }

        if offersRatingFilter {
            newFilterData.minRating = selectedMinRating
        }

        onFilterApplied?(newFilterData)
        dismiss(animated: true)
    }

    // MARK: - Helpers
    private func formatDuration(minutes: Int) -> String {
        if minutes == 0 {
            return "0h"
        }

        let days = minutes / 1440
        let hours = (minutes % 1440) / 60
        let mins = minutes % 60

        if days > 0 {
            if hours > 0 {
                return "\(days)d \(hours)h"
            }
            return "\(days) " + AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.filterDays)
        } else if hours > 0 {
            if mins > 0 {
                return "\(hours)h \(mins)m"
            }
            return "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }
}

// MARK: - RatingChipButton
/// A pill offering one lower rating bound, filled while it is the chosen one.
private final class RatingChipButton: UIButton {

    var isChosen = false {
        didSet { applyStyle() }
    }

    private let title: String
    private let showsStar: Bool

    init(title: String, showsStar: Bool) {
        self.title = title
        self.showsStar = showsStar
        super.init(frame: .zero)
        layer.cornerRadius = 18
        layer.borderWidth = 1
        clipsToBounds = true
        applyStyle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func applyStyle() {
        let foreground: UIColor = isChosen ? .white : ColorSet.primaryText.uiColor
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)
        configuration.imagePadding = 4
        configuration.attributedTitle = AttributedString(title, attributes: AttributeContainer([
            .font: FontSet.montserratMedium.font(14),
            .foregroundColor: foreground
        ]))
        if showsStar {
            configuration.image = UIImage(systemName: "star.fill")?
                .withConfiguration(UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold))
            let starColor: UIColor = isChosen ? .white : ColorSet.ratingStar.uiColor
            configuration.imageColorTransformer = UIConfigurationColorTransformer { _ in starColor }
        }
        self.configuration = configuration
        backgroundColor = isChosen ? ColorSet.primary.uiColor : .white
        layer.borderColor = (isChosen ? ColorSet.primary.uiColor : ColorSet.lineWeak.uiColor).cgColor
    }
}
