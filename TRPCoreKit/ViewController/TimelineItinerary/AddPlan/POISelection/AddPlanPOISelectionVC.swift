//
//  AddPlanPOISelectionVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit
import TRPFoundationKit

@objc(SPMAddPlanPOISelectionVC)
public class AddPlanPOISelectionVC: TRPBaseUIViewController {
    
    // MARK: - Properties
    public var viewModel: AddPlanPOISelectionViewModel!
    public var onLocationSelected: ((TRPLocation, String) -> Void)?
    
    // MARK: - UI Components
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.searchPOI)
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        return searchBar
    }()
    
    private lazy var nearMeButton: UIButton = {
        let button = createQuickOptionButton(
            icon: "ic_near_me",
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.nearMe)
        )
        button.addTarget(self, action: #selector(nearMeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var cityCenterButton: UIButton = {
        let button = createQuickOptionButton(
            icon: "ic_city_center",
            title: "" // Will be set dynamically
        )
        button.addTarget(self, action: #selector(cityCenterButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var sectionTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.savedActivities)
        label.font = FontSet.montserratSemiBold.font(18)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(POISelectionCell.self, forCellReuseIdentifier: "POISelectionCell")
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = ColorSet.neutral200.uiColor
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 64, bottom: 0, right: 0)
        tableView.backgroundColor = .white
        return tableView
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
    
    // MARK: - Lifecycle
    public override func setupViews() {
        super.setupViews()
        view.backgroundColor = .white
        
        view.addSubview(searchBar)
        view.addSubview(closeButton)
        view.addSubview(nearMeButton)
        view.addSubview(cityCenterButton)
        view.addSubview(sectionTitleLabel)
        view.addSubview(tableView)
        
        setupConstraints()
        updateCityCenterButton()
    }
    
    // MARK: - Setup
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Close Button
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Search Bar
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            
            // Near Me Button
            nearMeButton.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
            nearMeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            nearMeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            nearMeButton.heightAnchor.constraint(equalToConstant: 48),
            
            // City Center Button
            cityCenterButton.topAnchor.constraint(equalTo: nearMeButton.bottomAnchor, constant: 12),
            cityCenterButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            cityCenterButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            cityCenterButton.heightAnchor.constraint(equalToConstant: 48),
            
            // Section Title
            sectionTitleLabel.topAnchor.constraint(equalTo: cityCenterButton.bottomAnchor, constant: 24),
            sectionTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            sectionTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            // Table View
            tableView.topAnchor.constraint(equalTo: sectionTitleLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    private func createQuickOptionButton(icon: String, title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .white
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = ColorSet.neutral200.uiColor.cgColor
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.tintColor = ColorSet.primaryText.uiColor
        iconImageView.contentMode = .scaleAspectFit
        
        // Try to load custom icon first, fallback to SF Symbol if not found
        if let customImage = UIImage(named: icon) {
            iconImageView.image = customImage.withRenderingMode(.alwaysTemplate)
        } else if let systemImage = UIImage(systemName: icon) {
            iconImageView.image = systemImage
        }
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = FontSet.montserratRegular.font(16)
        titleLabel.textColor = ColorSet.primaryText.uiColor
        
        button.addSubview(iconImageView)
        button.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: button.trailingAnchor, constant: -16),
        ])
        
        return button
    }
    
    private func updateCityCenterButton() {
        if let cityName = viewModel.getCityName() {
            // Update the title label inside the button
            for subview in cityCenterButton.subviews {
                if let label = subview as? UILabel {
                    label.text = "\(cityName) | \(AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.cityCenter))"
                }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func nearMeButtonTapped() {
        // TODO: Get user's current location and use as starting point
        print("Near me tapped")
    }
    
    @objc private func cityCenterButtonTapped() {
        if let coordinate = viewModel.getCityCenterLocation(),
           let name = viewModel.getCityCenterDisplayName() {
            onLocationSelected?(coordinate, name)
            dismiss(animated: true)
        }
    }
}

// MARK: - UITableViewDataSource
extension AddPlanPOISelectionVC: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getSavedPOIs().count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "POISelectionCell", for: indexPath) as? POISelectionCell else {
            return UITableViewCell()
        }
        
        let poi = viewModel.getSavedPOIs()[indexPath.row]
        cell.configure(with: poi)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension AddPlanPOISelectionVC: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let poi = viewModel.getSavedPOIs()[indexPath.row]
        onLocationSelected?(poi.coordinate, poi.name)
        dismiss(animated: true)
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
}

// MARK: - UISearchBarDelegate
extension AddPlanPOISelectionVC: UISearchBarDelegate {
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.searchPOIs(with: searchText)
        tableView.reloadData()
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - POISelectionCell
private class POISelectionCell: UITableViewCell {
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "mappin.circle.fill")
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
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),
            
            nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            locationLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            locationLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            locationLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
        ])
    }
    
    func configure(with poi: TRPPoi) {
        nameLabel.text = poi.name
        
        // Create location string from address or just show city ID for now
        if let address = poi.address, !address.isEmpty {
            locationLabel.text = address
        } else {
            locationLabel.text = ""
        }
    }
}
