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
    private var isLoadingMore = false

    // Callback when segment is created successfully
    public var onSegmentCreated: (() -> Void)?

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
            .font: FontSet.montserratSemiBold.font(18)
        ]
        appearance.shadowColor = .clear // Remove navigation bar separator line

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }
    
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - UI Components
    private lazy var searchBar: TRPSearchBar = {
        let searchBar = TRPSearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.searchActivity)
        searchBar.delegate = self
        return searchBar
    }()

    private lazy var separatorLine: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.lineWeak.uiColor // #CFCFCF
        return view
    }()
    
    private lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.filters), for: .normal)
        button.setTitleColor(ColorSet.primaryText.uiColor, for: .normal)
        button.titleLabel?.font = FontSet.montserratMedium.font(14)
        button.backgroundColor = .white
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 0.5
        button.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)

        // Add filter icon
        let image = TRPImageController().getImage(inFramework: "ic_filter_activity", inApp: nil)
        button.setImage(image, for: .normal)
        button.tintColor = ColorSet.fgWeak.uiColor
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 8)

        return button
    }()

    private lazy var sortButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.sortBy), for: .normal)
        button.setTitleColor(ColorSet.primaryText.uiColor, for: .normal)
        button.titleLabel?.font = FontSet.montserratMedium.font(14)
        button.backgroundColor = .white
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 0.5
        button.layer.borderColor = ColorSet.lineWeak.uiColor.cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)

        // Add sort icon
        let image = TRPImageController().getImage(inFramework: "ic_order_activity", inApp: nil)
        button.setImage(image, for: .normal)
        button.tintColor = ColorSet.fgWeak.uiColor
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 8)

        return button
    }()

    private lazy var filterSortStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [filterButton, sortButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        return stackView
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
        tableView.showsVerticalScrollIndicator = false
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
        view.addSubview(separatorLine)
        view.addSubview(filterSortStackView)
        view.addSubview(categoryCollectionView)
        view.addSubview(activityCountLabel)
        view.addSubview(infoButton)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            // Search Bar
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Separator Line (below search bar)
            separatorLine.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 12),
            separatorLine.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5),

            // Filter and Sort Stack View
            filterSortStackView.topAnchor.constraint(equalTo: separatorLine.bottomAnchor, constant: 16),
            filterSortStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filterSortStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            filterSortStackView.heightAnchor.constraint(equalToConstant: 40),

            // Category Collection View
            categoryCollectionView.topAnchor.constraint(equalTo: filterSortStackView.bottomAnchor, constant: 16),
            categoryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoryCollectionView.heightAnchor.constraint(equalToConstant: 88),

            // Activity Count Label
            activityCountLabel.topAnchor.constraint(equalTo: categoryCollectionView.bottomAnchor, constant: 16),
            activityCountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            // Info Button
            infoButton.centerYAnchor.constraint(equalTo: activityCountLabel.centerYAnchor),
            infoButton.leadingAnchor.constraint(equalTo: activityCountLabel.trailingAnchor, constant: 4),
            infoButton.heightAnchor.constraint(equalToConstant: 16),
            infoButton.widthAnchor.constraint(equalToConstant: 16),

            // Table View
            tableView.topAnchor.constraint(equalTo: activityCountLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
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
        let isSelected = viewModel.isCategorySelected(at: indexPath.item)
        cell.configure(title: categoryNames[indexPath.item], iconName: iconName, isSelected: isSelected)
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let categoryNames = viewModel.getCategoryNames()
//        let title = categoryNames[indexPath.item]
        // Calculate width based on title (matching Figma design)
//        let width: CGFloat = title.contains("\n") ? 88 : (title == "All" || title == "Otros" ? 64 : 72)
        return CGSize(width: 80, height: 72)
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectCategory(at: indexPath.item)
        collectionView.reloadData()

        // Scroll table to top when category changes
        if tableView.numberOfRows(inSection: 0) > 0 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
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

        cell.delegate = self

        if let tour = viewModel.getTourAt(index: indexPath.row) {
            cell.configure(with: tour)
        }

        // Hide separator for last cell
        let isLastCell = indexPath.row == viewModel.getActivities().count - 1
        cell.setSeparatorHidden(isLastCell)

        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Notify delegate about activity detail request
        if let tour = viewModel.getTourAt(index: indexPath.row) {
            TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityDetail(activityId: tour.productId)
        }
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
            // Load more tours if available and not already loading
            if viewModel.hasMoreTours() && !isLoadingMore {
                isLoadingMore = true
                tableView.tableFooterView = loadingFooterView
                viewModel.loadMoreTours()
            }
        }
    }
}

// MARK: - TRPSearchBarDelegate
extension AddPlanActivityListingVC: TRPSearchBarDelegate {

    public func searchBar(_ searchBar: TRPSearchBar, textDidChange text: String) {
        viewModel.updateSearchText(text)
    }

    public func searchBarSearchButtonClicked(_ searchBar: TRPSearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - AddPlanActivityListingViewModelDelegate
extension AddPlanActivityListingVC: AddPlanActivityListingViewModelDelegate {

    public func activitiesDidLoad() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Reset loading state
            self.isLoadingMore = false

            self.tableView.reloadData()

            let count = self.viewModel.getActivityCount()
            let activityText = count == 1
                ? AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.activity)
                : AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.activities)
            self.activityCountLabel.text = "\(count) \(activityText)"

            // Update footer - only remove if no more tours
            self.updateTableFooter()
        }
    }

    private func updateTableFooter() {
        // Only show footer if there's no more data
        if !viewModel.hasMoreTours() {
            tableView.tableFooterView = nil
        }
    }

    public func activitiesDidFail(error: Error) {
        DispatchQueue.main.async { [weak self] in
            // Reset loading state on error
            self?.isLoadingMore = false
            self?.tableView.tableFooterView = nil

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
            titleLabel.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor)
        ])
    }
    
    func configure(title: String, iconName: String?, isSelected: Bool) {
        titleLabel.text = title

        // Set icon (use custom icon from framework with template rendering mode)
        if let iconName = iconName {
            let image = TRPImageController().getImage(inFramework: iconName, inApp: nil)
            iconImageView.image = image?.withRenderingMode(.alwaysTemplate)
        }

        // Update colors and font based on selection state
        if isSelected {
            iconImageView.tintColor = ColorSet.primary.uiColor
            titleLabel.textColor = ColorSet.primary.uiColor
            titleLabel.font = FontSet.montserratRegular.font(12)
        } else {
            iconImageView.tintColor = ColorSet.fgWeak.uiColor
            titleLabel.textColor = ColorSet.fgWeak.uiColor
            titleLabel.font = FontSet.montserratLight.font(12)
        }
    }
}

// MARK: - ActivityCardCellDelegate
extension AddPlanActivityListingVC: ActivityCardCellDelegate {

    func activityCardCellDidTapAdd(_ cell: ActivityCardCell, tour: TRPTourProduct) {
        // Create time selection screen
        let timeSelectionVC = AddPlanTimeSelectionVC(tour: tour, planData: viewModel.planData)

        timeSelectionVC.onTimeSelected = { [weak self] selectedDate, selectedTimeSlot in
            print("Selected date: \(selectedDate), time: \(selectedTimeSlot.time)")
        }

        // Set segment creation callback
        timeSelectionVC.onSegmentCreated = { [weak self] in
            // Trigger parent callback
            self?.onSegmentCreated?()
        }

        // Present as bottom sheet using base extension
        presentVCWithModal(timeSelectionVC, onlyLarge: false, prefersGrabberVisible: false)
    }
}
