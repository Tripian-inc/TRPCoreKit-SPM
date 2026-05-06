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
    private var customNavigationBar: TRPTimelineCustomNavigationBar!
    private static let skeletonChipCount: Int = 5
    private static let skeletonRowCount: Int = 6

    // Callback when segment is created successfully, passes selected day for navigation
    public var onSegmentCreated: ((Date?) -> Void)?

    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        viewModel.delegate = self
        viewModel.performInitialSearch()
    }
    
    // MARK: - UI Components
    private lazy var searchBar: TRPSearchBar = {
        let searchBar = TRPSearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.searchActivity)
        searchBar.delegate = self
        return searchBar
    }()

    private lazy var filterButtonView: FilterButtonView = {
        let view = FilterButtonView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.configure(
            icon: TRPImageController().getImage(inFramework: "ic_filter_activity", inApp: nil),
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.filters)
        )
        return view
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
        let stackView = UIStackView(arrangedSubviews: [filterButtonView, sortButton])
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
        label.font = FontSet.montserratMedium.font(12)
        label.textColor = ColorSet.neutral500.uiColor
        label.isHidden = true
        return label
    }()
    
    private lazy var infoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "info.circle")
        imageView.tintColor = ColorSet.neutral500.uiColor
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
        imageView.isHidden = true
        return imageView
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

    // MARK: - Lifecycle
    public override func setupViews() {
        super.setupViews()
        view.backgroundColor = .white

        // Setup navigation bar using base class method
        customNavigationBar = setupCustomNavigationBar(
            title: AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.categoryActivities)
        )
        customNavigationBar.delegate = self

        view.addSubview(searchBar)
        view.addSubview(filterSortStackView)
        view.addSubview(categoryCollectionView)
        view.addSubview(activityCountLabel)
        view.addSubview(infoImageView)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            // Search Bar
            searchBar.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Filter and Sort Stack View
            filterSortStackView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 24),
            filterSortStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            filterSortStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            filterSortStackView.heightAnchor.constraint(equalToConstant: 40),

            // Category Collection View
            categoryCollectionView.topAnchor.constraint(equalTo: filterSortStackView.bottomAnchor, constant: 16),
            categoryCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            categoryCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            categoryCollectionView.heightAnchor.constraint(equalToConstant: 88),

            // Activity Count Label
            activityCountLabel.topAnchor.constraint(equalTo: categoryCollectionView.bottomAnchor, constant: 22),
            activityCountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            // Info ImageView
            infoImageView.centerYAnchor.constraint(equalTo: activityCountLabel.centerYAnchor),
            infoImageView.leadingAnchor.constraint(equalTo: activityCountLabel.trailingAnchor, constant: 4),
            infoImageView.heightAnchor.constraint(equalToConstant: 16),
            infoImageView.widthAnchor.constraint(equalToConstant: 16),

            // Table View
            tableView.topAnchor.constraint(equalTo: activityCountLabel.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        // Add button actions
        filterButtonView.onTap = { [weak self] in
            self?.filterButtonTapped()
        }
        sortButton.addTarget(self, action: #selector(sortButtonTapped), for: .touchUpInside)

        // Add info icon tap gesture
        let infoTapGesture = UITapGestureRecognizer(target: self, action: #selector(infoIconTapped))
        infoImageView.addGestureRecognizer(infoTapGesture)
    }

    @objc private func infoIconTapped() {
        let title = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.sortingInfoTitle)
        let message = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.sortingInfoMessage)
        let bottomSheetVC = SortingInfoBottomSheetVC(title: title, message: message)
        presentVCWithDynamicHeight(bottomSheetVC, prefersGrabberVisible: false, isDimmed: true)
//        showInfoBottomSheet(title: title, message: message)
    }

    // MARK: - Actions
    private func filterButtonTapped() {
        let filterVC = AddPlanFilterVC(filterData: viewModel.filterData)
        filterVC.priceRangeFacet = viewModel.priceRangeFacet
        filterVC.durationRangeFacet = viewModel.durationRangeFacet
        filterVC.onFilterApplied = { [weak self] filterData in
            self?.viewModel.updateFilterData(filterData)
            self?.updateFilterButtonAppearance()

            // Scroll table to top when filter changes
            if self?.tableView.numberOfRows(inSection: 0) ?? 0 > 0 {
                self?.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
        presentVCWithDynamicHeight(filterVC, prefersGrabberVisible: false, isDimmed: false)
    }

    @objc private func sortButtonTapped() {
        let sortVC = AddPlanSortByVC(selectedOption: viewModel.selectedSortOption)
        sortVC.onSortOptionSelected = { [weak self] option in
            self?.viewModel.updateSortOption(option)

            // Scroll table to top when sort changes
            if self?.tableView.numberOfRows(inSection: 0) ?? 0 > 0 {
                self?.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
        presentVCWithDynamicHeight(sortVC, prefersGrabberVisible: false, isDimmed: false)
    }

    private func updateFilterButtonAppearance() {
        let filterCount = viewModel.filterData.activeFilterCount
        let hasFilters = filterCount > 0

        // Update badge visibility
        filterButtonView.setBadgeVisible(hasFilters)

        // Update title with count
        let baseTitle = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.filters)
        let title = hasFilters ? "\(baseTitle) (\(filterCount))" : baseTitle
        filterButtonView.updateTitle(title)
    }
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegateFlowLayout
extension AddPlanActivityListingVC: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if viewModel.isFacetsLoading() {
            return Self.skeletonChipCount
        }
        return viewModel.getCategoryChipCount()
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryFilterCell.reuseIdentifier, for: indexPath) as? CategoryFilterCell else {
            return UICollectionViewCell()
        }

        if viewModel.isFacetsLoading() {
            cell.configureSkeleton()
            return cell
        }

        let title = viewModel.getCategoryChipLabel(at: indexPath.item)
        let iconName = viewModel.getCategoryChipIconName(at: indexPath.item)
        let isSelected = viewModel.isCategoryChipSelected(at: indexPath.item)
        cell.configure(title: title, iconName: iconName, isSelected: isSelected)

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 82, height: 72)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !viewModel.isFacetsLoading() else { return }
        viewModel.selectCategoryChip(at: indexPath.item)
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
        if viewModel.isLoadingTours {
            return Self.skeletonRowCount
        }
        return viewModel.getActivities().count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ActivityCardCell.reuseIdentifier, for: indexPath) as? ActivityCardCell else {
            return UITableViewCell()
        }

        if viewModel.isLoadingTours {
            cell.configureSkeleton()
            return cell
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
        guard !viewModel.isLoadingTours else { return }

        // Notify delegate about activity detail request
        if let tour = viewModel.getTourAt(index: indexPath.row) {
            TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityDetail(activityId: tour.productId)
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

            self.activityCountLabel.isHidden = false
            self.infoImageView.isHidden = false
            self.tableView.reloadData()

            let count = self.viewModel.getActivityCount()
            let activityText = count == 1
                ? AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.activity)
                : AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.activities)
            self.activityCountLabel.text = "\(count) \(activityText)"
        }
    }

    public func facetsDidLoad() {
        DispatchQueue.main.async { [weak self] in
            self?.categoryCollectionView.reloadData()
        }
    }

    public func tourLoadingStateDidChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.viewModel.isLoadingTours {
                self.activityCountLabel.isHidden = true
                self.infoImageView.isHidden = true
            }
            self.tableView.reloadData()
        }
    }

    public func activitiesDidFail(error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
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
    private static let skeletonAnimationKey = "shimmer"

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

    private let iconSkeletonView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.lineWeak.uiColor
        view.layer.cornerRadius = 16
        view.isHidden = true
        return view
    }()

    private let titleSkeletonView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.lineWeak.uiColor
        view.layer.cornerRadius = 4
        view.isHidden = true
        return view
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
        contentView.addSubview(iconSkeletonView)
        contentView.addSubview(titleSkeletonView)
        contentView.backgroundColor = .white

        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),

            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(greaterThanOrEqualTo: contentView.bottomAnchor),

            iconSkeletonView.centerXAnchor.constraint(equalTo: iconImageView.centerXAnchor),
            iconSkeletonView.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
            iconSkeletonView.widthAnchor.constraint(equalToConstant: 32),
            iconSkeletonView.heightAnchor.constraint(equalToConstant: 32),

            titleSkeletonView.centerXAnchor.constraint(equalTo: titleLabel.centerXAnchor),
            titleSkeletonView.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            titleSkeletonView.widthAnchor.constraint(equalToConstant: 56),
            titleSkeletonView.heightAnchor.constraint(equalToConstant: 8)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopSkeletonAnimation()
    }

    func configure(title: String, iconName: String?, isSelected: Bool) {
        stopSkeletonAnimation()

        iconImageView.isHidden = false
        titleLabel.isHidden = false
        iconSkeletonView.isHidden = true
        titleSkeletonView.isHidden = true

        titleLabel.text = title

        // Set icon (use custom icon from framework with template rendering mode)
        if let iconName = iconName {
            let image = TRPImageController().getImage(inFramework: iconName, inApp: nil, withTintColor: true)
            iconImageView.image = image
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

    func configureSkeleton() {
        iconImageView.isHidden = true
        titleLabel.isHidden = true
        iconSkeletonView.isHidden = false
        titleSkeletonView.isHidden = false

        startSkeletonAnimation()
    }

    private func startSkeletonAnimation() {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.4
        animation.toValue = 1.0
        animation.duration = 0.8
        animation.autoreverses = true
        animation.repeatCount = .infinity
        iconSkeletonView.layer.add(animation, forKey: Self.skeletonAnimationKey)
        titleSkeletonView.layer.add(animation, forKey: Self.skeletonAnimationKey)
    }

    private func stopSkeletonAnimation() {
        iconSkeletonView.layer.removeAnimation(forKey: Self.skeletonAnimationKey)
        titleSkeletonView.layer.removeAnimation(forKey: Self.skeletonAnimationKey)
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

        // Set segment creation callback with selected day for navigation
        timeSelectionVC.onSegmentCreated = { [weak self] selectedDay in
            // Trigger parent callback with selected day
            self?.onSegmentCreated?(selectedDay)
        }

        // Present as bottom sheet using base extension
        presentVCWithModal(timeSelectionVC)
    }
}

// MARK: - TRPTimelineCustomNavigationBarDelegate
extension AddPlanActivityListingVC: TRPTimelineCustomNavigationBarDelegate {

    func customNavigationBarDidTapBack(_ navigationBar: TRPTimelineCustomNavigationBar) {
        dismiss(animated: true)
    }
}

// MARK: - FilterButtonView
private class FilterButtonView: UIView {

    // MARK: - Properties
    var onTap: (() -> Void)?

    // MARK: - UI Components
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ColorSet.fgWeak.uiColor
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(14)
        label.textColor = ColorSet.primaryText.uiColor
        return label
    }()

    /// Badge indicator for active filter (8x8, primary color, 0.5px white border)
    private let badge: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ColorSet.primary.uiColor
        view.layer.cornerRadius = 4 // 8/2 = 4
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.white.cgColor
        view.isHidden = true
        return view
    }()

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI() {
        // Button appearance
        backgroundColor = .white
        layer.cornerRadius = 20
        layer.borderWidth = 0.5
        layer.borderColor = ColorSet.lineWeak.uiColor.cgColor

        // Container to center icon + label together
        let contentStack = UIStackView(arrangedSubviews: [iconImageView, titleLabel])
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .horizontal
        contentStack.spacing = 8
        contentStack.alignment = .center

        addSubview(contentStack)
        addSubview(badge)

        NSLayoutConstraint.activate([
            // Icon size
            iconImageView.widthAnchor.constraint(equalToConstant: 16),
            iconImageView.heightAnchor.constraint(equalToConstant: 16),

            // Center content stack in view
            contentStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor),

            // Badge at top-right corner of icon
            badge.widthAnchor.constraint(equalToConstant: 8),
            badge.heightAnchor.constraint(equalToConstant: 8),
            badge.topAnchor.constraint(equalTo: iconImageView.topAnchor, constant: -2),
            badge.trailingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 4)
        ])
    }

    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }

    // MARK: - Actions
    @objc private func handleTap() {
        onTap?()
    }

    // MARK: - Public Methods
    func configure(icon: UIImage?, title: String) {
        iconImageView.image = icon?.withRenderingMode(.alwaysTemplate)
        titleLabel.text = title
    }

    func updateTitle(_ title: String) {
        titleLabel.text = title
    }

    func setBadgeVisible(_ visible: Bool) {
        badge.isHidden = !visible
    }
}
