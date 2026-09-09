//
//  AddPlanPOIListingVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 30.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit
import TRPFoundationKit

@objc(SPMAddPlanPOIListingVC)
public class AddPlanPOIListingVC: TRPBaseUIViewController {

    // MARK: - Properties
    public var viewModel: AddPlanPOIListingViewModel!
    private var isLoadingMore = false
    private var customNavigationBar: TRPTimelineCustomNavigationBar!

    private static let skeletonRowCount: Int = 6

    /// One-shot guard: the VM may emit the `.lottie` state twice during a single fetch.
    private var lottiePresented: Bool = false


    private var pendingPoi: TRPPoi?

    private var pendingPoiName: String?

    /// Legacy "dismiss everything on success" callback; internal flow uses `onSegmentCreatedSilent`.
    public var onSegmentCreated: ((Date?) -> Void)?

    /// Fired after the manual-POI add + regeneration poll; listing stays open, host refreshes silently.
    public var onSegmentCreatedSilent: ((Date?) -> Void)?

    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        viewModel.delegate = self
        viewModel.performInitialFetch()
    }

    // MARK: - UI Components
    private lazy var searchBar: TRPSearchBar = {
        let searchBar = TRPSearchBar()
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.searchPOIPlace)
        searchBar.delegate = self
        return searchBar
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

    private lazy var poiCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = FontSet.montserratMedium.font(12)
        label.textColor = ColorSet.neutral500.uiColor
        label.textAlignment = .center
        label.text = "0 \(AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.places))"
        return label
    }()
    
    private lazy var infoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "info.circle")
        imageView.tintColor = ColorSet.neutral500.uiColor
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isUserInteractionEnabled = true
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
        tableView.estimatedRowHeight = 96
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(POIListingCell.self, forCellReuseIdentifier: POIListingCell.reuseIdentifier)
        return tableView
    }()

    /// Lives as the table's `tableHeaderView` so filter/sort/count scroll with content.
    private lazy var headerContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
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

        customNavigationBar = setupCustomNavigationBar(title: viewModel.getTitle())
        customNavigationBar.delegate = self

        view.addSubview(searchBar)
        view.addSubview(tableView)

        headerContainerView.addSubview(filterSortStackView)
        headerContainerView.addSubview(poiCountLabel)
        headerContainerView.addSubview(infoImageView)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Table pinned edge-to-edge; the 16pt row inset is applied inside POIListingCell.
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            filterSortStackView.topAnchor.constraint(equalTo: headerContainerView.topAnchor, constant: 8),
            filterSortStackView.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor, constant: 16),
            filterSortStackView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor, constant: -16),
            filterSortStackView.heightAnchor.constraint(equalToConstant: 40),

            poiCountLabel.topAnchor.constraint(equalTo: filterSortStackView.bottomAnchor, constant: 16),
            poiCountLabel.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor, constant: 16),
            poiCountLabel.heightAnchor.constraint(equalToConstant: 28),
            poiCountLabel.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor, constant: -8),

            infoImageView.centerYAnchor.constraint(equalTo: poiCountLabel.centerYAnchor),
            infoImageView.leadingAnchor.constraint(equalTo: poiCountLabel.trailingAnchor, constant: 4),
            infoImageView.heightAnchor.constraint(equalToConstant: 16),
            infoImageView.widthAnchor.constraint(equalToConstant: 16),
        ])

        tableView.tableHeaderView = headerContainerView

        filterButton.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
        sortButton.addTarget(self, action: #selector(sortButtonTapped), for: .touchUpInside)

        let infoTapGesture = UITapGestureRecognizer(target: self, action: #selector(infoIconTapped))
        infoImageView.addGestureRecognizer(infoTapGesture)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sizeTableHeaderToFit()
    }

    /// `tableHeaderView` is frame-driven: measure via Auto Layout, apply via `.frame`. Height check guards an infinite layout loop.
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

    // MARK: - Actions
    @objc private func filterButtonTapped() {
        let filterVC = AddPlanPOIFilterVC(categoryType: viewModel.categoryType, filterData: viewModel.filterData)
        filterVC.onFilterApplied = { [weak self] filterData in
            self?.viewModel.updateFilterData(filterData)
            self?.updateFilterButtonAppearance()

            // `setContentOffset(.zero)` returns to true top; `scrollToRow(.top)` would hide the header.
            self?.tableView.setContentOffset(.zero, animated: true)
        }
        presentVCWithDynamicHeight(filterVC, prefersGrabberVisible: false, isDimmed: false)
    }

    @objc private func sortButtonTapped() {
        let poiSortOptions: [SortOption] = [.popularity, .rating]
        let sortVC = AddPlanSortByVC(selectedOption: viewModel.selectedSortOption, availableOptions: poiSortOptions)
        sortVC.onSortOptionSelected = { [weak self] option in
            self?.viewModel.updateSortOption(option)

            self?.tableView.setContentOffset(.zero, animated: true)
        }
        presentVCWithDynamicHeight(sortVC, prefersGrabberVisible: false, isDimmed: false)
    }

    @objc private func infoIconTapped() {
        let title = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.sortingInfoTitle)
        let message = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.sortingInfoMessage)
        let bottomSheetVC = SortingInfoBottomSheetVC(title: title, message: message)
        presentVCWithDynamicHeight(bottomSheetVC, prefersGrabberVisible: false, isDimmed: true)
    }

    private func updatePoiCountLabel() {
        poiCountLabel.text = viewModel.getPoiCountDisplayString()
    }

    private func updateFilterButtonAppearance() {
        let filterCount = viewModel.filterData.activeFilterCount
        let hasFilters = filterCount > 0

        let baseTitle = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.filters)
        let title = hasFilters ? "\(baseTitle) (\(filterCount))" : baseTitle
        filterButton.setTitle(title, for: .normal)
    }

    private func updateTableFooter() {
        if !viewModel.hasMorePois() {
            tableView.tableFooterView = nil
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension AddPlanPOIListingVC: UITableViewDataSource, UITableViewDelegate {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewModel.loadingStyle == .skeleton {
            return Self.skeletonRowCount
        }
        return viewModel.getPois().count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: POIListingCell.reuseIdentifier, for: indexPath) as? POIListingCell else {
            return UITableViewCell()
        }

        cell.delegate = self

        if viewModel.loadingStyle == .skeleton {
            cell.configureSkeleton()
        } else if let poi = viewModel.getPoiAt(index: indexPath.row) {
            cell.configure(with: poi)
        }

        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard viewModel.loadingStyle != .skeleton else { return }
        tableView.deselectRow(at: indexPath, animated: true)

        if let poi = viewModel.getPoiAt(index: indexPath.row) {
            openPoiDetail(poi: poi)
        }
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height

        guard contentHeight > frameHeight else { return }

        let paginationThreshold: CGFloat = 100
        if offsetY + frameHeight >= contentHeight - paginationThreshold {
            if viewModel.hasMorePois() && !isLoadingMore {
                isLoadingMore = true
                tableView.tableFooterView = loadingFooterView
                viewModel.loadMorePois()
            }
        }
    }

    private func openPoiDetail(poi: TRPPoi) {
        let availableDays = viewModel.planData.availableDays
        let detailVM = TimelinePoiDetailViewModel(poi: poi,
                                                  tripStartDate: availableDays.first,
                                                  tripEndDate: availableDays.last)
        let detailVC = TimelinePoiDetailViewController(viewModel: detailVM)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - TRPSearchBarDelegate
extension AddPlanPOIListingVC: TRPSearchBarDelegate {

    public func searchBar(_ searchBar: TRPSearchBar, textDidChange text: String) {
        tableView.setContentOffset(.zero, animated: true)
    }

    public func searchBar(_ searchBar: TRPSearchBar, queryDidChange query: String) {
        viewModel.updateSearchText(query)
    }

    public func searchBarSearchButtonClicked(_ searchBar: TRPSearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - AddPlanPOIListingViewModelDelegate
extension AddPlanPOIListingVC: AddPlanPOIListingViewModelDelegate {

    public func poisDidLoad() {
        isLoadingMore = false
        tableView.reloadData()
        // Count label is meaningless during skeleton mode; show it only once back to `.none`.
        if viewModel.loadingStyle != .skeleton {
            updatePoiCountLabel()
        }
        updateTableFooter()
    }

    public func poiLoadingStateDidChange() {
        // Base helper marshals to main so the overlay attaches after the modal starts compositing (else it z-orders beneath).
        switch viewModel.loadingStyle {
        case .lottie:
            if !lottiePresented {
                lottiePresented = true
                let text = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.gettingPlaces)
                viewModel(showLottie: .fullScreen, textMode: .single(text))
            }
        case .skeleton, .bottomSheet, .none:
            // `.bottomSheet` is an Activity Listing case but the shared enum forces it here; treat as skeleton/none.
            if lottiePresented {
                lottiePresented = false
                viewModel(hideLottie: .fullScreen)
            }
        }
    }

    public func segmentCreatedSuccessfully() {
        let activityName = pendingPoiName ?? ""
        let selectedDay = viewModel.getSelectedDay()
        viewModel(hideLottie: .bottomSheet, completion: { [weak self] in
            guard let self = self else { return }
            let dayLabel = selectedDay?.weekdayWithDayMonth() ?? ""
            let template = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.activityAddedToast)
            let message = String(format: template, activityName, dayLabel)
            TRPSuccessToast.show(over: self, message: message)
            self.pendingPoiName = nil
            self.onSegmentCreatedSilent?(selectedDay)
        })
    }

    public override func viewModel(error: Error) {
        // Tear down any in-flight bottom-sheet loader so it doesn't stack with the error alert.
        viewModel(hideLottie: .bottomSheet)
        pendingPoiName = nil
        super.viewModel(error: error)
    }
}

// MARK: - POIListingCellDelegate
extension AddPlanPOIListingVC: POIListingCellDelegate {

    func poiListingCellDidTapAdd(_ cell: POIListingCell, poi: TRPPoi) {
        pendingPoi = poi

        let timeRangeVC = TRPTimeRangeSelectionViewController()
        timeRangeVC.delegate = self

        if let selectedDay = viewModel.planData.selectedDay {
            timeRangeVC.setSelectedDate(selectedDay)
        }

        // City drives the IANA timezone for "today" / minimum-time, not the device.
        timeRangeVC.setSelectedCity(viewModel.planData.selectedCity)
        timeRangeVC.setOpeningHours(poi.hours)

        timeRangeVC.show(from: self)
    }
}

// MARK: - TRPTimeRangeSelectionDelegate
extension AddPlanPOIListingVC: TRPTimeRangeSelectionDelegate {

    public func timeRangeSelected(fromTime: String, toTime: String) {
        // Not used - we use the Date version
    }

    public func timeRangeSelected(fromDate: Date, toDate: Date) {
        guard let poi = pendingPoi else { return }

        pendingPoi = nil
        pendingPoiName = poi.name

        // Loader stays up through the whole create + GetTimeline poll; success only fires after polling.
        let text = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.addingToItinerary)
        viewModel(showLottie: .bottomSheet, textMode: .single(text))

        viewModel.createManualPoiSegment(poi: poi, startTime: fromDate, endTime: toDate)
    }
}

// MARK: - TRPTimelineCustomNavigationBarDelegate
extension AddPlanPOIListingVC: TRPTimelineCustomNavigationBarDelegate {

    func customNavigationBarDidTapBack(_ navigationBar: TRPTimelineCustomNavigationBar) {
        // Tear down the initial-fetch overlay on back, else it orphans over the underlying screen.
        if lottiePresented {
            lottiePresented = false
            viewModel(hideLottie: .fullScreen)
        }
        // Dismiss the whole modal chain so back returns to the originating screen (timeline), not AddPlan.
        let presenter = presentingViewController?.presentingViewController ?? presentingViewController
        presenter?.dismiss(animated: true)
    }
}
