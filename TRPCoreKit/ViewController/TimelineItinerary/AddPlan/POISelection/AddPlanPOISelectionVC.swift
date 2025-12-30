//
//  AddPlanPOISelectionVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit
import TRPFoundationKit
import CoreLocation
import TRPRestKit

@objc(SPMAddPlanPOISelectionVC)
public class AddPlanPOISelectionVC: TRPBaseUIViewController {

    // MARK: - Properties
    public var viewModel: AddPlanPOISelectionViewModel!
    public var onLocationSelected: ((TRPLocation, String, TRPAccommodation?) -> Void)?

    private let locationManager = CLLocationManager()
    private var isSearchActive = false

    // MARK: - UI Components

    // Navigation Area
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let image = TRPImageController().getImage(inFramework: "ic_back", inApp: nil)
        button.setImage(image, for: .normal)
        button.tintColor = ColorSet.primaryText.uiColor
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var searchBar: TRPSearchBar = {
        let searchBar = TRPSearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.searchPOI)
        searchBar.delegate = self
        return searchBar
    }()

    // Default Content View (shown when not searching)
    private lazy var defaultContentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()

    private lazy var nearMeButton: UIView = {
        let view = createOptionRow(
            icon: "ic_near_me",
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.nearMe)
        )
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(nearMeButtonTapped))
        view.addGestureRecognizer(tapGesture)
        return view
    }()

    private lazy var cityCenterButton: UIView = {
        let view = createOptionRow(
            icon: "ic_city_center",
            title: "" // Will be set dynamically
        )
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cityCenterButtonTapped))
        view.addGestureRecognizer(tapGesture)
        return view
    }()

    private lazy var sectionTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.savedActivities)
        label.font = FontSet.montserratSemiBold.font(16)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()

    private lazy var activitiesTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tag = 1 // Tag to identify this table
        tableView.register(POISelectionCell.self, forCellReuseIdentifier: "POISelectionCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        return tableView
    }()

    // Search Results View (shown when searching)
    private lazy var searchResultsTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tag = 2 // Tag to identify this table
        tableView.register(POISelectionCell.self, forCellReuseIdentifier: "POISelectionCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        tableView.isHidden = true
        return tableView
    }()

    // MARK: - Lifecycle
    public override func setupViews() {
        super.setupViews()
        view.backgroundColor = .white

        setupNavigationArea()
        setupDefaultContentView()
        setupSearchResultsView()
        setupLocationManager()

        viewModel.delegate = self
        updateCityCenterButton()
    }

    // MARK: - Setup
    private func setupNavigationArea() {
        view.addSubview(backButton)
        view.addSubview(searchBar)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            searchBar.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            searchBar.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }

    private func setupDefaultContentView() {
        view.addSubview(defaultContentView)

        defaultContentView.addSubview(nearMeButton)
        defaultContentView.addSubview(cityCenterButton)
        defaultContentView.addSubview(sectionTitleLabel)
        defaultContentView.addSubview(activitiesTableView)

        NSLayoutConstraint.activate([
            defaultContentView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
            defaultContentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            defaultContentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            defaultContentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            nearMeButton.topAnchor.constraint(equalTo: defaultContentView.topAnchor),
            nearMeButton.leadingAnchor.constraint(equalTo: defaultContentView.leadingAnchor, constant: 16),
            nearMeButton.trailingAnchor.constraint(equalTo: defaultContentView.trailingAnchor, constant: -16),
            nearMeButton.heightAnchor.constraint(equalToConstant: 48),

            cityCenterButton.topAnchor.constraint(equalTo: nearMeButton.bottomAnchor),
            cityCenterButton.leadingAnchor.constraint(equalTo: defaultContentView.leadingAnchor, constant: 16),
            cityCenterButton.trailingAnchor.constraint(equalTo: defaultContentView.trailingAnchor, constant: -16),
            cityCenterButton.heightAnchor.constraint(equalToConstant: 48),

            sectionTitleLabel.topAnchor.constraint(equalTo: cityCenterButton.bottomAnchor, constant: 24),
            sectionTitleLabel.leadingAnchor.constraint(equalTo: defaultContentView.leadingAnchor, constant: 16),
            sectionTitleLabel.trailingAnchor.constraint(equalTo: defaultContentView.trailingAnchor, constant: -16),

            activitiesTableView.topAnchor.constraint(equalTo: sectionTitleLabel.bottomAnchor, constant: 8),
            activitiesTableView.leadingAnchor.constraint(equalTo: defaultContentView.leadingAnchor),
            activitiesTableView.trailingAnchor.constraint(equalTo: defaultContentView.trailingAnchor),
            activitiesTableView.bottomAnchor.constraint(equalTo: defaultContentView.bottomAnchor),
        ])
    }

    private func setupSearchResultsView() {
        view.addSubview(searchResultsTableView)

        NSLayoutConstraint.activate([
            searchResultsTableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
            searchResultsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchResultsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchResultsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    private func createOptionRow(icon: String, title: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .white
        container.isUserInteractionEnabled = true

        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.tintColor = ColorSet.primaryText.uiColor
        iconImageView.contentMode = .scaleAspectFit

        if let customImage = TRPImageController().getImage(inFramework: icon, inApp: nil) {
            iconImageView.image = customImage.withRenderingMode(.alwaysTemplate)
        } else if let systemImage = UIImage(systemName: "location.fill") {
            iconImageView.image = systemImage
        }

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = FontSet.montserratRegular.font(16)
        titleLabel.textColor = ColorSet.primaryText.uiColor
        titleLabel.tag = 100 // Tag to find it later for updates

        container.addSubview(iconImageView)
        container.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor),
        ])

        return container
    }

    private func updateCityCenterButton() {
        if let displayName = viewModel.getCityCenterDisplayName() {
            if let label = cityCenterButton.viewWithTag(100) as? UILabel {
                label.text = displayName
            }
        }
    }

    // MARK: - State Management
    private func showDefaultContent() {
        isSearchActive = false
        defaultContentView.isHidden = false
        searchResultsTableView.isHidden = true
    }

    private func showSearchResults() {
        isSearchActive = true
        defaultContentView.isHidden = true
        searchResultsTableView.isHidden = false
    }

    // MARK: - Actions
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }

    @objc private func nearMeButtonTapped() {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            showLocationPermissionAlert()
        @unknown default:
            break
        }
    }

    @objc private func cityCenterButtonTapped() {
        if let coordinate = viewModel.getCityCenterLocation(),
           let name = viewModel.getCityCenterDisplayName() {
            onLocationSelected?(coordinate, name, nil)
            dismiss(animated: true)
        }
    }

    private func showLocationPermissionAlert() {
        let alert = UIAlertController(
            title: "Location Access Required",
            message: "Please enable location access in Settings to use Near Me feature.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension AddPlanPOISelectionVC: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.tag == 1 {
            // Activities table
            return viewModel.getBookedActivitiesCount()
        } else {
            // Search results table
            return viewModel.getSearchResultsCount()
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "POISelectionCell", for: indexPath) as? POISelectionCell else {
            return UITableViewCell()
        }

        if tableView.tag == 1 {
            // Activities table
            if let segment = viewModel.getBookedActivity(at: indexPath.row) {
                cell.configureWithSegment(segment)
            }
        } else {
            // Search results table
            if let place = viewModel.getSearchResult(at: indexPath.row) {
                cell.configureWithGooglePlace(place)
            }
        }

        return cell
    }
}

// MARK: - UITableViewDelegate
extension AddPlanPOISelectionVC: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if tableView.tag == 1 {
            // Activities table - use segment coordinate
            if let segment = viewModel.getBookedActivity(at: indexPath.row),
               let coordinate = segment.coordinate {
                let name = segment.title ?? segment.additionalData?.title ?? ""
                onLocationSelected?(coordinate, name, nil)
                dismiss(animated: true)
            }
        } else {
            // Search results table - fetch place details
            if let place = viewModel.getSearchResult(at: indexPath.row) {
                viewModel.searchPlace(withId: place.id)
            }
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
}

// MARK: - TRPSearchBarDelegate
extension AddPlanPOISelectionVC: TRPSearchBarDelegate {
    public func searchBar(_ searchBar: TRPSearchBar, textDidChange text: String) {
        if text.isEmpty {
            showDefaultContent()
            viewModel.clearSearchResults()
        } else {
            showSearchResults()
            viewModel.searchAddress(text: text)
        }
    }

    public func searchBarDidBeginEditing(_ searchBar: TRPSearchBar) {
        // Optional: Handle focus
    }

    public func searchBarDidEndEditing(_ searchBar: TRPSearchBar) {
        // Optional: Handle blur
    }

    public func searchBarSearchButtonClicked(_ searchBar: TRPSearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - AddPlanPOISelectionViewModelDelegate
extension AddPlanPOISelectionVC: AddPlanPOISelectionViewModelDelegate {
    public func searchResultsDidUpdate() {
        searchResultsTableView.reloadData()
    }

    public func placeDetailDidLoad(accommodation: TRPAccommodation) {
        onLocationSelected?(accommodation.coordinate, accommodation.name ?? "", accommodation)
        dismiss(animated: true)
    }

    public func searchDidFail(error: Error) {
        // Show error if needed
    }
}

// MARK: - CLLocationManagerDelegate
extension AddPlanPOISelectionVC: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }

        let trpLocation = TRPLocation(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
        let name = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.nearMe)
        onLocationSelected?(trpLocation, name, nil)
        dismiss(animated: true)
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Handle location error
    }

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }
}

// MARK: - POISelectionCell
private class POISelectionCell: UITableViewCell {

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = ColorSet.primaryText.uiColor
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratSemiBold.font(16)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()

    private let locationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratRegular.font(14)
        label.textColor = ColorSet.fgWeak.uiColor
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(locationLabel)

        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),

            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            locationLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            locationLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            locationLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
        ])
    }

    func configureWithSegment(_ segment: TRPTimelineSegment) {
        // Set icon
        if let customImage = TRPImageController().getImage(inFramework: "ic_pin", inApp: nil) {
            iconImageView.image = customImage.withRenderingMode(.alwaysTemplate)
        } else {
            iconImageView.image = UIImage(systemName: "mappin.circle.fill")
        }

        // Set title
        nameLabel.text = segment.title ?? segment.additionalData?.title ?? ""

        // Set location
        locationLabel.text = segment.city?.name ?? ""
    }

    func configureWithGooglePlace(_ place: TRPGooglePlace) {
        // Set icon
        if let customImage = TRPImageController().getImage(inFramework: "ic_pin", inApp: nil) {
            iconImageView.image = customImage.withRenderingMode(.alwaysTemplate)
        } else {
            iconImageView.image = UIImage(systemName: "mappin.circle.fill")
        }

        // Set title and location
        nameLabel.text = place.mainAddress
        locationLabel.text = place.secondaryAddress
    }
}
