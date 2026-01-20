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
    public var minPrice: Int?
    public var maxPrice: Int?
    public var minDuration: Int?  // in minutes
    public var maxDuration: Int?  // in minutes

    public init(minPrice: Int? = nil, maxPrice: Int? = nil, minDuration: Int? = nil, maxDuration: Int? = nil) {
        self.minPrice = minPrice
        self.maxPrice = maxPrice
        self.minDuration = minDuration
        self.maxDuration = maxDuration
    }

    public var isEmpty: Bool {
        return minPrice == nil && maxPrice == nil && minDuration == nil && maxDuration == nil
    }

    /// Returns the count of active filter types (price = 1, duration = 1, max = 2)
    public var activeFilterCount: Int {
        var count = 0
        if minPrice != nil || maxPrice != nil {
            count += 1
        }
        if minDuration != nil || maxDuration != nil {
            count += 1
        }
        return count
    }
}

// MARK: - AddPlanFilterVC
public class AddPlanFilterVC: UIViewController {

    // MARK: - Properties
    private var filterData: FilterData
    public var onFilterApplied: ((FilterData) -> Void)?

    // Price range constants
    private let priceMinValue: Double = 0
    private let priceMaxValue: Double = 1500

    // Duration range constants (in minutes)
    private let durationMinValue: Double = 0
    private let durationMaxValue: Double = 1440 // 4 days in minutes

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

    // Price Section
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

    // Duration Section
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

    // Apply Button
    private lazy var applyButton: TRPButton = {
        let button = TRPButton(
            title: CommonLocalizationKeys.localized(CommonLocalizationKeys.confirm),
            style: .primary
        )
        return button
    }()

    // MARK: - Initialization
    public init(filterData: FilterData = FilterData()) {
        self.filterData = filterData
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
        buttonContainerView.addSubview(applyButton)

        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(clearButtonTapped), for: .touchUpInside)
        applyButton.addTarget(self, action: #selector(applyButtonTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            // Header view
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 56),

            // Title label (centered)
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            // Close button (right side)
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),

            // Scroll view
            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: buttonContainerView.topAnchor),

            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Price section
            priceTitleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            priceTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            priceSlider.topAnchor.constraint(equalTo: priceTitleLabel.bottomAnchor, constant: 16),
            priceSlider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            priceSlider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            priceSlider.heightAnchor.constraint(equalToConstant: 50),

            // Duration section
            durationTitleLabel.topAnchor.constraint(equalTo: priceSlider.bottomAnchor, constant: 32),
            durationTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),

            durationSlider.topAnchor.constraint(equalTo: durationTitleLabel.bottomAnchor, constant: 16),
            durationSlider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            durationSlider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            durationSlider.heightAnchor.constraint(equalToConstant: 50),
            durationSlider.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),

            // Button container view
            buttonContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            buttonContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            buttonContainerView.heightAnchor.constraint(equalToConstant: 80),

            // Clear button (left)
            clearButton.leadingAnchor.constraint(equalTo: buttonContainerView.leadingAnchor, constant: 16),
            clearButton.topAnchor.constraint(equalTo: buttonContainerView.topAnchor, constant: 16),

            // Apply button (right)
            applyButton.leadingAnchor.constraint(equalTo: clearButton.trailingAnchor, constant: 16),
            applyButton.trailingAnchor.constraint(equalTo: buttonContainerView.trailingAnchor, constant: -16),
            applyButton.topAnchor.constraint(equalTo: buttonContainerView.topAnchor, constant: 16),
            applyButton.widthAnchor.constraint(equalTo: clearButton.widthAnchor)
        ])
    }

    private func setupSliders() {
        // Price slider
        priceSlider.minimumValue = priceMinValue
        priceSlider.maximumValue = priceMaxValue
        priceSlider.lowerValue = Double(filterData.minPrice ?? Int(priceMinValue))
        priceSlider.upperValue = Double(filterData.maxPrice ?? Int(priceMaxValue))
        priceSlider.valueLabelFormatter = { value in
            let intValue = Int(value)
            if intValue == 0 {
                return AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.filterFree)
            }
            return "\(intValue)€"
        }

        // Duration slider
        durationSlider.minimumValue = durationMinValue
        durationSlider.maximumValue = durationMaxValue
        durationSlider.lowerValue = Double(filterData.minDuration ?? Int(durationMinValue))
        durationSlider.upperValue = Double(filterData.maxDuration ?? Int(durationMaxValue))
        durationSlider.valueLabelFormatter = { [weak self] value in
            return self?.formatDuration(minutes: Int(value)) ?? "\(Int(value))m"
        }
    }

    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }

    @objc private func clearButtonTapped() {
        // Reset sliders to full range
        priceSlider.lowerValue = priceMinValue
        priceSlider.upperValue = priceMaxValue
        durationSlider.lowerValue = durationMinValue
        durationSlider.upperValue = durationMaxValue
    }

    @objc private func applyButtonTapped() {
        // Build filter data
        var newFilterData = FilterData()

        // Only set price filter if not at full range
        if priceSlider.lowerValue > priceMinValue {
            newFilterData.minPrice = Int(priceSlider.lowerValue)
        }
        if priceSlider.upperValue < priceMaxValue {
            newFilterData.maxPrice = Int(priceSlider.upperValue)
        }

        // Only set duration filter if not at full range
        if durationSlider.lowerValue > durationMinValue {
            newFilterData.minDuration = Int(durationSlider.lowerValue)
        }
        if durationSlider.upperValue < durationMaxValue {
            newFilterData.maxDuration = Int(durationSlider.upperValue)
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
