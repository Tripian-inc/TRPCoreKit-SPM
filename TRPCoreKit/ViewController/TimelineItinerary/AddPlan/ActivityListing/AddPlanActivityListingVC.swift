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

    /// Which Lottie loader (if any) is currently presented for this VC, so
    /// `activitiesDidLoad`/`activitiesDidFail` know to dismiss the matching one (with
    /// the right completion sequencing for follow-up UI) versus a plain skeleton refresh.
    /// `nil` means no Lottie is up.
    private var currentLottiePresentation: LottieLoaderPresentation?

    // Callback when segment is created successfully, passes selected day for navigation
    public var onSegmentCreated: ((Date?) -> Void)?

    /// Fires after a manual activity is added but the user chose to stay on the
    /// listing screen (no dismiss). The host VC should refresh its timeline data
    /// silently — the listing handles its own success toast locally.
    public var onSegmentCreatedSilent: ((Date?) -> Void)?

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

    /// Container for filter buttons, category chips and the activity count.
    /// Lives as the table view's `tableHeaderView` so it scrolls naturally with
    /// the content — disappearing under the search bar (clipped by the table's
    /// own bounds) instead of using a separate hide/show animation.
    private lazy var headerContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
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
        view.addSubview(tableView)

        headerContainerView.addSubview(filterSortStackView)
        headerContainerView.addSubview(categoryCollectionView)
        headerContainerView.addSubview(activityCountLabel)
        headerContainerView.addSubview(infoImageView)

        NSLayoutConstraint.activate([
            // Search Bar
            searchBar.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Table View — pinned edge-to-edge directly under the search bar. The 16pt
            // horizontal inset that the activity rows need is applied inside the cell
            // (`ActivityCardCell.cardContainerView`) so the header's category collection
            // can still extend to the screen edges.
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            // Filter and Sort Stack View — 16pt inset matches the search bar above.
            filterSortStackView.topAnchor.constraint(equalTo: headerContainerView.topAnchor, constant: 8),
            filterSortStackView.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor, constant: 16),
            filterSortStackView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor, constant: -16),
            filterSortStackView.heightAnchor.constraint(equalToConstant: 40),

            // Category Collection View — flush with the screen edges; the cell's own
            // sectionInset handles the visual side padding.
            categoryCollectionView.topAnchor.constraint(equalTo: filterSortStackView.bottomAnchor, constant: 16),
            categoryCollectionView.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor),
            categoryCollectionView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor),
            categoryCollectionView.heightAnchor.constraint(equalToConstant: 88),

            // Activity Count Label — 16pt inset, aligned with the filter row.
            activityCountLabel.topAnchor.constraint(equalTo: categoryCollectionView.bottomAnchor, constant: 22),
            activityCountLabel.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor, constant: 16),
            activityCountLabel.heightAnchor.constraint(equalToConstant: 16),
            activityCountLabel.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor, constant: -8),

            // Info ImageView
            infoImageView.centerYAnchor.constraint(equalTo: activityCountLabel.centerYAnchor),
            infoImageView.leadingAnchor.constraint(equalTo: activityCountLabel.trailingAnchor, constant: 4),
            infoImageView.heightAnchor.constraint(equalToConstant: 16),
            infoImageView.widthAnchor.constraint(equalToConstant: 16),
        ])

        tableView.tableHeaderView = headerContainerView

        // Add button actions
        filterButtonView.onTap = { [weak self] in
            self?.filterButtonTapped()
        }
        sortButton.addTarget(self, action: #selector(sortButtonTapped), for: .touchUpInside)

        // Add info icon tap gesture
        let infoTapGesture = UITapGestureRecognizer(target: self, action: #selector(infoIconTapped))
        infoImageView.addGestureRecognizer(infoTapGesture)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sizeTableHeaderToFit()
    }

    /// `UITableView.tableHeaderView` is frame-driven, so its Auto Layout intrinsic
    /// size has to be measured manually and applied via `.frame` (then re-assigned
    /// to commit). The height check guards against an infinite layout loop.
    private func sizeTableHeaderToFit() {
        guard let header = tableView.tableHeaderView else { return }
        let width = tableView.bounds.width
        guard width > 0 else { return }
        let target = header.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        if header.frame.size.width != width || header.frame.size.height != target.height {
            header.frame = CGRect(x: 0, y: 0, width: width, height: target.height)
            tableView.tableHeaderView = header
        }
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

            // Reset scroll so the filter / category / count header is visible again.
            // `scrollToRow(.top)` would park the first cell at the top and push the
            // header off-screen — `setContentOffset(.zero)` returns to the true top.
            self?.tableView.setContentOffset(.zero, animated: true)
        }
        presentVCWithDynamicHeight(filterVC, prefersGrabberVisible: false, isDimmed: false)
    }

    @objc private func sortButtonTapped() {
        let sortVC = AddPlanSortByVC(selectedOption: viewModel.selectedSortOption)
        sortVC.onSortOptionSelected = { [weak self] option in
            self?.viewModel.updateSortOption(option)

            // Reset to true top so the header (filter / category / count) is back in view.
            self?.tableView.setContentOffset(.zero, animated: true)
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

        // Reset to true top so the header (filter / category / count) is back in view.
        tableView.setContentOffset(.zero, animated: true)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension AddPlanActivityListingVC: UITableViewDataSource, UITableViewDelegate {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewModel.loadingStyle == .skeleton {
            return Self.skeletonRowCount
        }
        return viewModel.getActivities().count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ActivityCardCell.reuseIdentifier, for: indexPath) as? ActivityCardCell else {
            return UITableViewCell()
        }

        if viewModel.loadingStyle == .skeleton {
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

        // Notify delegate about activity detail request. `tour.productId` comes from
        // the search mapper as `C_{id}_{provider}` — strip to the bare product id so
        // the host always receives the same shape it gets from every other tap path.
        if let tour = viewModel.getTourAt(index: indexPath.row) {
            TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityDetail(activityId: tour.productId.cleanedAsActivityId())
        }
    }

}

// MARK: - TRPSearchBarDelegate
extension AddPlanActivityListingVC: TRPSearchBarDelegate {

    public func searchBar(_ searchBar: TRPSearchBar, textDidChange text: String) {
        viewModel.updateSearchText(text)
        tableView.setContentOffset(.zero, animated: true)
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

            let renderResults = {
                self.activityCountLabel.isHidden = false
                self.infoImageView.isHidden = false
                self.tableView.reloadData()

                let count = self.viewModel.getActivityCount()
                let activityText = count == 1
                    ? AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.activity)
                    : AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.activities)
                self.activityCountLabel.text = "\(count) \(activityText)"
            }

            // If a Lottie overlay was up (initial open / category change), dismiss it
            // first so results animate in once the fade-out finishes. Match the same
            // presentation we showed it under — full-screen for initial open, bottom
            // sheet for category change.
            if let presentation = self.currentLottiePresentation {
                self.currentLottiePresentation = nil
                self.viewModel(hideLottie: presentation, completion: renderResults)
                return
            }
            renderResults()
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

                // Style-driven loading UI:
                //   .lottie      → shared full-screen overlay (initial open)
                //   .bottomSheet → modal Lottie sheet (category chip change)
                //   .skeleton    → inline table skeleton (sort/filter + search-text refresh)
                if self.currentLottiePresentation == nil {
                    let message = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.gettingActivities)
                    switch self.viewModel.loadingStyle {
                    case .lottie:
                        self.currentLottiePresentation = .fullScreen
                        self.viewModel(showLottie: .fullScreen, textMode: .single(message))
                    case .bottomSheet:
                        self.currentLottiePresentation = .bottomSheet
                        self.viewModel(showLottie: .bottomSheet, textMode: .single(message))
                    case .skeleton, .none:
                        break  // table skeleton handles itself via reload below
                    }
                }
            }
            self.tableView.reloadData()
        }
    }

    public func searchTextDidReset() {
        DispatchQueue.main.async { [weak self] in
            self?.searchBar.text = ""
        }
    }

    public func activitiesDidFail(error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let presentAlert = {
                self.tableView.reloadData()
                EvrAlertView.showAlert(contentText: error.localizedDescription, type: .error)
            }

            if let presentation = self.currentLottiePresentation {
                self.currentLottiePresentation = nil
                self.viewModel(hideLottie: presentation, completion: presentAlert)
                return
            }
            presentAlert()
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
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.lineBreakMode = .byTruncatingTail
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
            // Bounded by the cell, but allowed to hug its intrinsic height so the
            // text always starts at the pinned top (y=icon.bottom+8). With a forced
            // min-height equal to the cell, UILabel vertically centers single-line
            // text and titles across cells stop lining up at the top.
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),

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

        // Capture the activity name; day label comes from the Date extension.
        let activityName = tour.name
        timeSelectionVC.onSegmentCreated = { [weak self] selectedDay in
            guard let self = self else { return }

            let dayLabel = selectedDay?.weekdayWithDayMonth() ?? ""
            let template = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.activityAddedToast)
            let message = String(format: template, activityName, dayLabel)
            TRPSuccessToast.show(over: self, message: message)

            // Stay on the listing — host VC refreshes the timeline silently.
            self.onSegmentCreatedSilent?(selectedDay)
        }

        // Present as bottom sheet using base extension
        presentVCWithDynamicHeight(timeSelectionVC, prefersGrabberVisible: true, isDimmed: true)
    }
}

// MARK: - TRPTimelineCustomNavigationBarDelegate
extension AddPlanActivityListingVC: TRPTimelineCustomNavigationBarDelegate {

    func customNavigationBarDidTapBack(_ navigationBar: TRPTimelineCustomNavigationBar) {
        // Listing is presented on top of the AddPlan sheet (so the open animation
        // is smooth). On back, dismiss the entire modal chain so the user returns
        // to the screen that originated the flow (timeline), not to AddPlan.
        // Falls back to a plain self-dismiss if there's only one level of chain.
        let presenter = presentingViewController?.presentingViewController ?? presentingViewController
        presenter?.dismiss(animated: true)
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
