//
//  AddPlanActivityListingVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit
import TRPFoundationKit

@objc(SPMAddPlanActivityListingVC)
public class AddPlanActivityListingVC: TRPBaseUIViewController {
    
    // MARK: - Properties
    public var viewModel: AddPlanActivityListingViewModel!
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        viewModel.delegate = self
        viewModel.performInitialSearch()
    }
    
    private func setupNavigationBar() {
        title = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.categoryActivities)
        navigationController?.navigationBar.prefersLargeTitles = false
        
        // Add back button
        let backButton = UIBarButtonItem(
            image: TRPImageController().getImage(inFramework: "ic_back", inApp: nil),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        backButton.tintColor = ColorSet.primaryText.uiColor // #333333
        navigationItem.leftBarButtonItem = backButton
        
        // Navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [
            .foregroundColor: ColorSet.primaryText.uiColor, // #333333
            .font: FontSet.montserratSemiBold.font(16)
        ]
        appearance.shadowColor = ColorSet.lineWeak.uiColor // #CFCFCF
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - UI Components
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.searchActivity)
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = .clear
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        
        // Customize search text field
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = .white
            textField.layer.cornerRadius = 24 // Rounded capsule shape
            textField.layer.borderWidth = 0.5
            textField.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor // #CFCFCF
            textField.textColor = ColorSet.primaryText.uiColor // #333333
            textField.font = FontSet.montserratRegular.font(16)
            
            // Placeholder text styling
            textField.attributedPlaceholder = NSAttributedString(
                string: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.searchActivity),
                attributes: [
                    .foregroundColor: ColorSet.fgWeak.uiColor,
                    .font: FontSet.montserratRegular.font(16)
                ]
            )
        }
        
        return searchBar
    }()
    
    private lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.filters), for: .normal)
        button.setTitleColor(ColorSet.primaryText.uiColor, for: .normal) // #333333
        button.titleLabel?.font = FontSet.montserratMedium.font(14)
        button.backgroundColor = .white
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 0.5
        button.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor // #CFCFCF
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)
        
        // Add filter icon
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let image = UIImage(systemName: "line.3.horizontal.decrease.circle", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = ColorSet.fgWeak.uiColor // #666666
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 8)
        
        return button
    }()
    
    private lazy var sortButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.sortBy), for: .normal)
        button.setTitleColor(ColorSet.primaryText.uiColor, for: .normal) // #333333
        button.titleLabel?.font = FontSet.montserratMedium.font(14)
        button.backgroundColor = .white
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 0.5
        button.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor // #CFCFCF
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 24, bottom: 6, right: 24)
        
        // Add sort icon
        let config = UIImage.SymbolConfiguration(pointSize: 10, weight: .medium)
        let image = UIImage(systemName: "arrow.up.arrow.down", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = ColorSet.fgWeak.uiColor // #666666
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)
        
        return button
    }()
    
    private lazy var categoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .white
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(CategoryFilterCell.self, forCellWithReuseIdentifier: CategoryFilterCell.reuseIdentifier)
        return collectionView
    }()
    
    private lazy var activityCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratRegular.font(14)
        label.textColor = ColorSet.primaryText.uiColor // #333333
        label.text = "0 actividades"
        return label
    }()
    
    private lazy var infoButton: UIButton = {
        let button = UIButton(type: .infoLight)
        button.tintColor = ColorSet.fgWeak.uiColor // #666666
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 120
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(ActivityCardCell.self, forCellReuseIdentifier: ActivityCardCell.reuseIdentifier)
        return tableView
    }()

    private lazy var loadingFooterView: UIView = {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 60))
        let activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = ColorSet.primary.uiColor
        activityIndicator.center = CGPoint(x: footerView.bounds.width / 2, y: footerView.bounds.height / 2)
        activityIndicator.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        activityIndicator.startAnimating()
        footerView.addSubview(activityIndicator)
        return footerView
    }()
    
    // MARK: - Lifecycle
    public override func setupViews() {
        super.setupViews()
        view.backgroundColor = .white
        
        view.addSubview(searchBar)
        view.addSubview(filterButton)
        view.addSubview(sortButton)
        view.addSubview(categoryCollectionView)
        view.addSubview(activityCountLabel)
        view.addSubview(infoButton)
        view.addSubview(tableView)
        
        // Customize search bar icon after view is added
        DispatchQueue.main.async { [weak self] in
            self?.customizeSearchBarIcon()
        }
        
        NSLayoutConstraint.activate([
            // Search Bar
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchBar.heightAnchor.constraint(equalToConstant: 48),
            
            // Filter and Sort Buttons
            filterButton.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
            filterButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filterButton.heightAnchor.constraint(equalToConstant: 40),
            
            sortButton.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
            sortButton.leadingAnchor.constraint(equalTo: filterButton.trailingAnchor, constant: 16),
            sortButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Category Collection View
            categoryCollectionView.topAnchor.constraint(equalTo: filterButton.bottomAnchor, constant: 16),
            categoryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoryCollectionView.heightAnchor.constraint(equalToConstant: 88),
            
            // Activity Count Label
            activityCountLabel.topAnchor.constraint(equalTo: categoryCollectionView.bottomAnchor, constant: 16),
            activityCountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            // Info Button
            infoButton.centerYAnchor.constraint(equalTo: activityCountLabel.centerYAnchor),
            infoButton.leadingAnchor.constraint(equalTo: activityCountLabel.trailingAnchor, constant: 4),
            
            // Table View
            tableView.topAnchor.constraint(equalTo: activityCountLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func customizeSearchBarIcon() {
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            if let leftView = textField.leftView as? UIImageView {
                leftView.tintColor = ColorSet.primaryText.uiColor // #333333
            }
        }
    }
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegateFlowLayout
extension AddPlanActivityListingVC: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.getCategoryNames().count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryFilterCell.reuseIdentifier, for: indexPath) as? CategoryFilterCell else {
            return UICollectionViewCell()
        }
        
        let categoryNames = viewModel.getCategoryNames()
        let iconName = viewModel.getCategoryIconName(at: indexPath.item)
        let isSelected = indexPath.item == viewModel.selectedCategoryIndex
        cell.configure(title: categoryNames[indexPath.item], iconName: iconName, isSelected: isSelected)
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let categoryNames = viewModel.getCategoryNames()
        let title = categoryNames[indexPath.item]
        // Calculate width based on title (matching Figma design)
        let width: CGFloat = title.contains("\n") ? 88 : (title == "All" || title == "Otros" ? 64 : 72)
        return CGSize(width: width, height: 72)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectCategory(at: indexPath.item)
        collectionView.reloadData()
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension AddPlanActivityListingVC: UITableViewDataSource, UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getActivities().count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ActivityCardCell.reuseIdentifier, for: indexPath) as? ActivityCardCell else {
            return UITableViewCell()
        }

        if let tour = viewModel.getTourAt(index: indexPath.row) {
            cell.configure(with: tour)
        }

        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // TODO: Handle tour selection
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height

        // Only trigger if content is scrollable
        guard contentHeight > frameHeight else { return }

        // Check if scrolled near bottom (trigger when 100 points from bottom)
        let threshold: CGFloat = 100
        if offsetY + frameHeight >= contentHeight - threshold {
            // Load more tours if available
            if viewModel.hasMoreTours() {
                viewModel.loadMoreTours()
            }
        }
    }
}

// MARK: - UISearchBarDelegate
extension AddPlanActivityListingVC: UISearchBarDelegate {
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.updateSearchText(searchText)
    }

    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - AddPlanActivityListingViewModelDelegate
extension AddPlanActivityListingVC: AddPlanActivityListingViewModelDelegate {

    public func activitiesDidLoad() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.tableView.reloadData()

            let count = self.viewModel.getActivityCount()
            let activityText = count == 1 ? "actividad" : "actividades"
            self.activityCountLabel.text = "\(count) \(activityText)"

            // Update footer based on pagination state
            self.updateTableFooter()
        }
    }

    private func updateTableFooter() {
        if viewModel.hasMoreTours() {
            tableView.tableFooterView = loadingFooterView
        } else {
            tableView.tableFooterView = nil
        }
    }

    public func activitiesDidFail(error: Error) {
        DispatchQueue.main.async {
            EvrAlertView.showAlert(contentText: error.localizedDescription, type: .error)
        }
    }

    public func showLoading(_ show: Bool) {
        DispatchQueue.main.async { [weak self] in
            if show {
                self?.loader?.show()
            } else {
                self?.loader?.remove()
            }
        }
    }
}

// MARK: - CategoryFilterCell
private class CategoryFilterCell: UICollectionViewCell {
    static let reuseIdentifier = "CategoryFilterCell"
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.backgroundColor = .white
        
        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),
            
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configure(title: String, iconName: String?, isSelected: Bool) {
        titleLabel.text = title
        
        // Set icon (use SF Symbol if iconName provided)
        if let iconName = iconName {
            iconImageView.image = UIImage(systemName: iconName)
        }
        
        // Update colors and font based on selection state (matching Figma design)
        if isSelected {
            iconImageView.tintColor = ColorSet.primary.uiColor // #EA0558
            titleLabel.textColor = ColorSet.primary.uiColor // #EA0558
            titleLabel.font = FontSet.montserratRegular.font(12)
            contentView.backgroundColor = .white
        } else {
            iconImageView.tintColor = ColorSet.fgWeak.uiColor // #666666
            titleLabel.textColor = ColorSet.fgWeak.uiColor // #666666
            titleLabel.font = FontSet.montserratLight.font(12)
            contentView.backgroundColor = .white
        }
    }
}
