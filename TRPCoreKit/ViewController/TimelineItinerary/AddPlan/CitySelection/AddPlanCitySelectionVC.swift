//
//  AddPlanCitySelectionVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit
import TRPFoundationKit

@objc(SPMAddPlanCitySelectionVC)
public class AddPlanCitySelectionVC: TRPBaseUIViewController, DynamicHeightPresentable {

    // MARK: - Height Constants
    private let titleAreaHeight: CGFloat = 64  // top padding + title + gap
    private let rowHeight: CGFloat = 56
    private let sectionHeaderHeight: CGFloat = 32
    private let bottomPadding: CGFloat = 34

    // MARK: - Properties
    public var mappedCities: [TRPCity] = []   // Cities mapped to selected date
    public var otherCities: [TRPCity] = []    // Other available cities
    public var showSections: Bool = false     // Whether to show section headers
    public var selectedCity: TRPCity?
    public var onCitySelected: ((TRPCity) -> Void)?

    // MARK: - DynamicHeightPresentable
    public var preferredContentHeight: CGFloat {
        let totalCities = mappedCities.count + otherCities.count
        let rowsHeight = CGFloat(totalCities) * rowHeight

        var sectionsHeight: CGFloat = 0
        if showSections {
            if !mappedCities.isEmpty { sectionsHeight += sectionHeaderHeight }
            if !otherCities.isEmpty { sectionsHeight += sectionHeaderHeight }
        }

        let calculatedHeight = titleAreaHeight + rowsHeight + sectionsHeight + bottomPadding

        // Max height: 70% of screen
        let maxHeight = UIScreen.main.bounds.height * 0.7
        return min(calculatedHeight, maxHeight)
    }

    public func updateSheetHeight() {
        // No dynamic updates needed for city selection
    }

    // Backward compatibility
    public var cities: [TRPCity] {
        get { return mappedCities + otherCities }
        set {
            mappedCities = []
            otherCities = newValue
            showSections = false
        }
    }

    // MARK: - UI Components
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.selectCity)
        label.font = FontSet.montserratSemiBold.font(18)
        label.textColor = ColorSet.primaryText.uiColor
        label.textAlignment = .center
        return label
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("×", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 32, weight: .light)
        button.setTitleColor(ColorSet.primaryText.uiColor, for: .normal)
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()

    // MARK: - Lifecycle
    public override func setupViews() {
        super.setupViews()
        view.backgroundColor = .white

        view.addSubview(titleLabel)
        view.addSubview(closeButton)
        view.addSubview(contentStackView)

        setupConstraints()
        setupCityRows()
    }

    // MARK: - Setup
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Close Button
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),

            // Content StackView
            contentStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func setupCityRows() {
        // Clear existing
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if showSections {
            // Add mapped cities section
            if !mappedCities.isEmpty {
                addSectionHeader(AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.citiesForSelectedDate))
                mappedCities.forEach { addCityRow($0) }
            }

            // Add other cities section
            if !otherCities.isEmpty {
                addSectionHeader(AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.otherCities))
                otherCities.forEach { addCityRow($0) }
            }
        } else {
            // No sections - just add all cities
            (mappedCities + otherCities).forEach { addCityRow($0) }
        }
    }

    private func addSectionHeader(_ title: String) {
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = .white

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.font = FontSet.montserratMedium.font(12)
        label.textColor = ColorSet.primaryText.uiColor

        headerView.addSubview(label)

        NSLayoutConstraint.activate([
            headerView.heightAnchor.constraint(equalToConstant: sectionHeaderHeight),
            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 24),
            label.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
        ])

        contentStackView.addArrangedSubview(headerView)
    }

    private func addCityRow(_ city: TRPCity) {
        let rowView = CityRowView(city: city, isSelected: selectedCity?.id == city.id)
        rowView.translatesAutoresizingMaskIntoConstraints = false
        rowView.heightAnchor.constraint(equalToConstant: rowHeight).isActive = true
        rowView.onTap = { [weak self] in
            self?.onCitySelected?(city)
            self?.dismiss(animated: true)
        }
        contentStackView.addArrangedSubview(rowView)
    }

    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}

// MARK: - CityRowView
private class CityRowView: UIView {

    var onTap: (() -> Void)?

    private let cityLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratSemiBold.font(16)
        return label
    }()

    init(city: TRPCity, isSelected: Bool) {
        super.init(frame: .zero)
        setupView()
        configure(city: city, isSelected: isSelected)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = .white
        addSubview(cityLabel)

        NSLayoutConstraint.activate([
            cityLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            cityLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            cityLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }

    private func configure(city: TRPCity, isSelected: Bool) {
        cityLabel.text = city.name
        cityLabel.textColor = isSelected ? ColorSet.primary.uiColor : ColorSet.primaryText.uiColor
    }

    @objc private func handleTap() {
        onTap?()
    }
}
