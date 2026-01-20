//
//  TimelinePoiDetailViewController+Setup.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - Setup methods extracted from TimelinePoiDetailViewController
//

import UIKit
import TRPFoundationKit
import MapboxMaps

// MARK: - Setup Methods

extension TimelinePoiDetailViewController {

    // MARK: - Main Setup

    func setupUI() {
        view.backgroundColor = .white

        // Add ScrollView
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(contentStackView)

        // Add Image Gallery (outside stack, fixed at top)
        contentView.addSubview(imageCollectionView)
        view.addSubview(pageControl)
        view.addSubview(backButton)

        // Add all sections to stack view
        setupContentStack()

        setupConstraints()
    }

    func setupContentStack() {
        // Create section views
        basicInfoSectionView = BasicInfoSectionView(
            cityLabel: cityLabel,
            poiNameLabel: poiNameLabel,
            ratingContainerView: ratingContainerView,
            descriptionLabel: descriptionLabel,
            readMoreButton: readMoreButton,
            onReadMoreTapped: { [weak self] in
                self?.readMoreTapped()
            }
        )

        productsSectionView = ProductsSectionView(
            headerView: activitiesHeaderView,
            collectionView: activitiesCollectionView
        )

        keyDataSectionView = KeyDataSectionView(
            headerLabel: keyDataHeaderLabel,
            phoneStack: phoneStackView,
            hoursStack: openingHoursStackView
        )

        addressSectionView = AddressSectionView(
            headerLabel: meetingPointHeaderLabel,
            mapContainer: mapContainerView,
            locationStack: locationStackView,
            viewMapButton: viewMapButton
        )

        featuresSectionView = FeaturesSectionView(
            headerLabel: featuresHeaderLabel,
            tags: viewModel.getFeatures()
        )

        // Create separators
        separator1 = createSeparator()
        separator2 = createSeparator()
        separator3 = createSeparator()
        separator4 = createSeparator()

        // Add sections to stack
        contentStackView.addArrangedSubview(basicInfoSectionView)
        contentStackView.addArrangedSubview(separator1)
        contentStackView.addArrangedSubview(productsSectionView)
        contentStackView.addArrangedSubview(separator2)
        contentStackView.addArrangedSubview(keyDataSectionView)
        contentStackView.addArrangedSubview(separator3)
        contentStackView.addArrangedSubview(addressSectionView)
        contentStackView.addArrangedSubview(separator4)
        contentStackView.addArrangedSubview(featuresSectionView)

        // Setup subcomponents
        setupRatingContainer()
        setupActivitiesHeader()
        setupPhoneStack()
        setupHoursStack()
        setupLocationStack()
    }

    func createSeparator() -> UIView {
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = ColorSet.neutral200.uiColor
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return separator
    }

    // MARK: - Component Setup

    func setupRatingContainer() {
        ratingContainerView.addSubview(ratingLabel)
        ratingContainerView.addSubview(starImageView)
        ratingContainerView.addSubview(reviewCountLabel)

        NSLayoutConstraint.activate([
            ratingLabel.leadingAnchor.constraint(equalTo: ratingContainerView.leadingAnchor),
            ratingLabel.centerYAnchor.constraint(equalTo: ratingContainerView.centerYAnchor),
            starImageView.leadingAnchor.constraint(equalTo: ratingLabel.trailingAnchor, constant: 4),
            starImageView.centerYAnchor.constraint(equalTo: ratingContainerView.centerYAnchor),
            starImageView.widthAnchor.constraint(equalToConstant: 16),
            starImageView.heightAnchor.constraint(equalToConstant: 16),
            reviewCountLabel.leadingAnchor.constraint(equalTo: starImageView.trailingAnchor, constant: 8),
            reviewCountLabel.trailingAnchor.constraint(equalTo: ratingContainerView.trailingAnchor),
            reviewCountLabel.centerYAnchor.constraint(equalTo: ratingContainerView.centerYAnchor)
        ])
    }

    func setupActivitiesHeader() {
        activitiesHeaderView.addSubview(activitiesLabel)
        activitiesHeaderView.addSubview(seeMoreButton)

        NSLayoutConstraint.activate([
            activitiesLabel.leadingAnchor.constraint(equalTo: activitiesHeaderView.leadingAnchor),
            activitiesLabel.centerYAnchor.constraint(equalTo: activitiesHeaderView.centerYAnchor),
            seeMoreButton.trailingAnchor.constraint(equalTo: activitiesHeaderView.trailingAnchor),
            seeMoreButton.centerYAnchor.constraint(equalTo: activitiesHeaderView.centerYAnchor),
            activitiesHeaderView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    func setupPhoneStack() {
        phoneStackView.addArrangedSubview(phoneIconContainerView)
        phoneStackView.addArrangedSubview(phoneValueLabel)

        NSLayoutConstraint.activate([
            phoneIconContainerView.widthAnchor.constraint(equalToConstant: 40),
            phoneIconContainerView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    func setupHoursStack() {
        // Header stack: icon + title (centered vertically)
        hoursHeaderStack.addArrangedSubview(hoursIconContainerView)
        hoursHeaderStack.addArrangedSubview(hoursTitleLabel)

        // Create container for hours list with left padding (aligned with title)
        let hoursListContainer = UIView()
        hoursListContainer.translatesAutoresizingMaskIntoConstraints = false
        hoursListContainer.addSubview(hoursListStackView)

        // Main stack: header + hours list container (vertical)
        openingHoursStackView.addArrangedSubview(hoursHeaderStack)
        openingHoursStackView.addArrangedSubview(hoursListContainer)

        NSLayoutConstraint.activate([
            hoursIconContainerView.widthAnchor.constraint(equalToConstant: 40),
            hoursIconContainerView.heightAnchor.constraint(equalToConstant: 40),

            // Hours list with left padding (40px icon + 12px spacing = 52px)
            hoursListStackView.topAnchor.constraint(equalTo: hoursListContainer.topAnchor),
            hoursListStackView.leadingAnchor.constraint(equalTo: hoursListContainer.leadingAnchor, constant: 52),
            hoursListStackView.trailingAnchor.constraint(equalTo: hoursListContainer.trailingAnchor),
            hoursListStackView.bottomAnchor.constraint(equalTo: hoursListContainer.bottomAnchor)
        ])
    }

    func createHoursRowView(day: String, hours: String) -> UIView {
        let rowStack = UIStackView()
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        rowStack.axis = .horizontal
        rowStack.spacing = 14
        rowStack.alignment = .center

        let dayLabel = UILabel()
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        dayLabel.text = day
        dayLabel.font = FontSet.montserratMedium.font(16)
        dayLabel.textColor = ColorSet.fgWeak.uiColor

        let hoursLabel = UILabel()
        hoursLabel.translatesAutoresizingMaskIntoConstraints = false
        hoursLabel.text = hours
        hoursLabel.font = FontSet.montserratMedium.font(16)
        hoursLabel.textColor = ColorSet.fgWeak.uiColor

        rowStack.addArrangedSubview(dayLabel)
        rowStack.addArrangedSubview(hoursLabel)

        // Fixed width for day label to ensure alignment
        dayLabel.widthAnchor.constraint(equalToConstant: 42).isActive = true

        return rowStack
    }

    func setupLocationStack() {
        locationStackView.addArrangedSubview(locationIconView)
        locationStackView.addArrangedSubview(locationContentStack)
        locationContentStack.addArrangedSubview(locationValueLabel)

        NSLayoutConstraint.activate([
            locationIconView.widthAnchor.constraint(equalToConstant: 24),
            locationIconView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    // MARK: - Constraints

    func setupConstraints() {
        let screenWidth = UIScreen.main.bounds.width
        let imageHeight = screenWidth // 1:1 ratio

        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            // Image Gallery (1:1 ratio, fixed at top)
            imageCollectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageCollectionView.heightAnchor.constraint(equalToConstant: imageHeight),

            // Page Control
            pageControl.bottomAnchor.constraint(equalTo: imageCollectionView.bottomAnchor, constant: -16),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Back Button
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),

            // Content Stack (below image gallery)
            contentStackView.topAnchor.constraint(equalTo: imageCollectionView.bottomAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    // MARK: - Content Configuration

    func configureContent() {
        let poi = viewModel.poi

        // Configure Images
        let images = viewModel.getImageUrls()
        pageControl.numberOfPages = max(images.count, 1)
        pageControl.currentPage = 0
        pageControl.isHidden = images.count <= 1
        imageCollectionView.reloadData()

        // Configure Labels
        let cityName = viewModel.getCityName()
        cityLabel.text = cityName.isEmpty ? TimelineLocalizationKeys.localized(TimelineLocalizationKeys.unknownLocation) : cityName
        cityLabel.isHidden = cityName.isEmpty

        poiNameLabel.text = poi.name

        // Configure Rating
        if let rating = poi.rating, rating > 0 {
            ratingLabel.text = String(format: "%.1f", rating)

            let reviewCount = poi.ratingCount ?? 0
            let opinionsText = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.opinions)
            reviewCountLabel.text = "\(reviewCount) \(opinionsText)"

            ratingContainerView.isHidden = false
        } else {
            ratingContainerView.isHidden = true
        }

        // Configure Description
        configureDescription(poi: poi)

        // Configure Products Section
        configureProductsSection()

        // Configure Key Data Section
        configureKeyDataSection()

        // Configure Address Section
        configureAddressSection()

        // Configure Features Section
        configureFeaturesSection()

        // Control separator visibility
        configureSeparators()
    }

    private func configureDescription(poi: TRPPoi) {
        if let description = poi.description, !description.isEmpty {
            // Create attributed string with line height
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 8 // 24 line height - 16 font size = 8
            paragraphStyle.alignment = .center

            let attributedString = NSMutableAttributedString(string: description)
            attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: description.count))
            attributedString.addAttribute(.font, value: FontSet.montserratMedium.font(16), range: NSRange(location: 0, length: description.count))
            attributedString.addAttribute(.foregroundColor, value: ColorSet.fg.uiColor, range: NSRange(location: 0, length: description.count))

            descriptionLabel.attributedText = attributedString
            descriptionLabel.isHidden = false

            // Force full layout before checking truncation
            view.setNeedsLayout()
            view.layoutIfNeeded()

            // Check if description needs "Read More" button
            let isTruncated = descriptionLabel.isTruncated()
            readMoreButton.isHidden = !isTruncated

            print("[POI Detail] Description truncated: \(isTruncated)")
        } else {
            descriptionLabel.isHidden = true
            readMoreButton.isHidden = true
        }
    }

    private func configureProductsSection() {
        let hasProducts = viewModel.hasProducts()
        productsSectionView.isHidden = !hasProducts

        if hasProducts {
            activitiesHeaderView.isHidden = false
            activitiesCollectionView.isHidden = false
            activitiesCollectionView.reloadData()
        }
    }

    private func configureKeyDataSection() {
        let hasKeyData = viewModel.hasKeyData()
        keyDataSectionView.isHidden = !hasKeyData

        if hasKeyData {
            keyDataHeaderLabel.isHidden = false

            // Phone is only shown for restaurant, cafe, or nightlife categories
            let hasPhone = viewModel.getPhone() != nil && viewModel.isRestaurantCafeOrNightlife()
            let hasHours = viewModel.getOpeningHoursList() != nil

            phoneStackView.isHidden = !hasPhone
            openingHoursStackView.isHidden = !hasHours

            if hasPhone, let phoneValue = viewModel.getPhone() {
                let phoneTitle = PoiDetailLocalizationKeys.localized(PoiDetailLocalizationKeys.phone) + ": "
                let attributedString = NSMutableAttributedString()

                // "Phone: " part - regular 16px primaryText
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: FontSet.montserratRegular.font(16),
                    .foregroundColor: ColorSet.primaryText.uiColor
                ]
                attributedString.append(NSAttributedString(string: phoneTitle, attributes: titleAttributes))

                // Phone value part - medium 16px fgWeak
                let valueAttributes: [NSAttributedString.Key: Any] = [
                    .font: FontSet.montserratMedium.font(16),
                    .foregroundColor: ColorSet.fgWeak.uiColor
                ]
                attributedString.append(NSAttributedString(string: phoneValue, attributes: valueAttributes))

                phoneValueLabel.attributedText = attributedString
            }

            if hasHours, let hoursList = viewModel.getOpeningHoursList() {
                // Clear previous rows
                hoursListStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

                // Add row for each day
                for item in hoursList {
                    let rowView = createHoursRowView(day: item.day, hours: item.hours)
                    hoursListStackView.addArrangedSubview(rowView)
                }
            }
        }
    }

    private func configureAddressSection() {
        let hasMeetingPoint = viewModel.hasMeetingPoint()
        addressSectionView.isHidden = !hasMeetingPoint

        if hasMeetingPoint {
            meetingPointHeaderLabel.isHidden = false
            mapContainerView.isHidden = false
            locationStackView.isHidden = false
            viewMapButton.isHidden = false

            // Setup MapView
            setupMapView()

            // Set address
            if let address = viewModel.getAddress() {
                locationValueLabel.text = address
            }
        }
    }

    private func configureFeaturesSection() {
        let hasFeatures = viewModel.hasFeatures()
        featuresSectionView.isHidden = !hasFeatures

        if hasFeatures {
            featuresHeaderLabel.isHidden = false
            featuresSectionView.updateTags(viewModel.getFeatures())
        }
    }

    private func configureSeparators() {
        // separator1: before products section
        separator1.isHidden = productsSectionView.isHidden

        // separator2: before key data section
        separator2.isHidden = keyDataSectionView.isHidden

        // separator3: before address section
        separator3.isHidden = addressSectionView.isHidden

        // separator4: before features section
        separator4.isHidden = featuresSectionView.isHidden

        // Note: UIStackView automatically handles layout when arrangedSubviews are hidden
    }

    // MARK: - Map Setup

    func setupMapView() {
        // Remove existing map if any
        mapView?.removeFromSuperview()

        guard let coordinate = viewModel.getCoordinate() else { return }
        let center = CLLocationCoordinate2D(latitude: coordinate.lat, longitude: coordinate.lon)
        let camera = CameraOptions(center: center, zoom: 15)
        let options = MapInitOptions(cameraOptions: camera)
        let newMapView = MapView(frame: .zero, mapInitOptions: options)

        // Create point annotation with ic_civi_point
        var pointAnnotation = PointAnnotation(coordinate: center)
        if let civiPointImage = TRPImageController().getImage(inFramework: "ic_civi_point", inApp: nil) {
            pointAnnotation.image = .init(image: civiPointImage, name: "ic_civi_point")
        }

        // Create annotation manager
        let pointAnnotationManager = newMapView.annotations.makePointAnnotationManager()
        pointAnnotationManager.annotations = [pointAnnotation]

        newMapView.gestures.options.pinchZoomEnabled = true
        newMapView.gestures.options.quickZoomEnabled = true
        newMapView.translatesAutoresizingMaskIntoConstraints = false

        mapContainerView.addSubview(newMapView)
        NSLayoutConstraint.activate([
            newMapView.topAnchor.constraint(equalTo: mapContainerView.topAnchor),
            newMapView.leadingAnchor.constraint(equalTo: mapContainerView.leadingAnchor),
            newMapView.trailingAnchor.constraint(equalTo: mapContainerView.trailingAnchor),
            newMapView.bottomAnchor.constraint(equalTo: mapContainerView.bottomAnchor)
        ])

        newMapView.layer.cornerRadius = 12
        newMapView.clipsToBounds = true

        mapView = newMapView
    }
}
