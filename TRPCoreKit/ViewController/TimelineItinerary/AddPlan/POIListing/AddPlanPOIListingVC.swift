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

    /// Mirrors the Activity Listing skeleton row count so the table reads as a busy
    /// list while a fetch is in flight, instead of an empty / collapsed state.
    private static let skeletonRowCount: Int = 6

    /// One-shot guard so the window-attached Lottie is only presented once per
    /// `.lottie` loading-style transition (the VM may emit the state twice during a
    /// single fetch — once on entry, once on the categories-then-pois follow-up).
    private var lottiePresented: Bool = false


    // Temporarily stores selected POI while time range is being selected
    private var pendingPoi: TRPPoi?

    /// Captured POI name held across the create + GetTimeline poll, used to populate
    /// the success toast once the segment is fully generated. Cleared in
    /// `segmentCreatedSuccessfully` and on add-path errors.
    private var pendingPoiName: String?

    /// Callback for the legacy "dismiss everything on success" path. Left for backward
    /// compatibility — internal flow now uses `onSegmentCreatedSilent`.
    public var onSegmentCreated: ((Date?) -> Void)?

    /// Callback fired AFTER a manual POI is added and the timeline regeneration poll
    /// has completed. POI listing stays open; host VC is expected to refresh its
    /// timeline silently. Mirrors `AddPlanActivityListingVC.onSegmentCreatedSilent`.
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
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 96
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(POIListingCell.self, forCellReuseIdentifier: POIListingCell.reuseIdentifier)
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

        // Setup navigation bar using base class method
        customNavigationBar = setupCustomNavigationBar(title: viewModel.getTitle())
        customNavigationBar.delegate = self

        view.addSubview(searchBar)
        view.addSubview(filterSortStackView)
        view.addSubview(poiCountLabel)
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

            // POI Count Label
            poiCountLabel.topAnchor.constraint(equalTo: filterSortStackView.bottomAnchor, constant: 16),
            poiCountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            poiCountLabel.heightAnchor.constraint(equalToConstant: 28),

            // Info Button
            infoImageView.centerYAnchor.constraint(equalTo: poiCountLabel.centerYAnchor),
            infoImageView.leadingAnchor.constraint(equalTo: poiCountLabel.trailingAnchor, constant: 4),
            infoImageView.heightAnchor.constraint(equalToConstant: 16),
            infoImageView.widthAnchor.constraint(equalToConstant: 16),

            // Table View
            tableView.topAnchor.constraint(equalTo: poiCountLabel.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        // Add button actions
        filterButton.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
        sortButton.addTarget(self, action: #selector(sortButtonTapped), for: .touchUpInside)

        // Add info icon tap gesture
        let infoTapGesture = UITapGestureRecognizer(target: self, action: #selector(infoIconTapped))
        infoImageView.addGestureRecognizer(infoTapGesture)
    }

    // MARK: - Actions
    @objc private func filterButtonTapped() {
        let filterVC = AddPlanPOIFilterVC(categoryType: viewModel.categoryType, filterData: viewModel.filterData)
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
        // POI listing only shows popularity and rating options
        let poiSortOptions: [SortOption] = [.popularity, .rating]
        let sortVC = AddPlanSortByVC(selectedOption: viewModel.selectedSortOption, availableOptions: poiSortOptions)
        sortVC.onSortOptionSelected = { [weak self] option in
            self?.viewModel.updateSortOption(option)

            // Scroll table to top when sort changes
            if self?.tableView.numberOfRows(inSection: 0) ?? 0 > 0 {
                self?.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
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

        // Update title with count
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
        // Block detail navigation while skeleton rows are showing.
        guard viewModel.loadingStyle != .skeleton else { return }
        tableView.deselectRow(at: indexPath, animated: true)

        // Navigate to POI detail
        if let poi = viewModel.getPoiAt(index: indexPath.row) {
            openPoiDetail(poi: poi)
        }
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height

        guard contentHeight > frameHeight else { return }

        let threshold: CGFloat = 100
        if offsetY + frameHeight >= contentHeight - threshold {
            if viewModel.hasMorePois() && !isLoadingMore {
                isLoadingMore = true
                tableView.tableFooterView = loadingFooterView
                viewModel.loadMorePois()
            }
        }
    }

    private func openPoiDetail(poi: TRPPoi) {
        let detailVM = TimelinePoiDetailViewModel(poi: poi)
        let detailVC = TimelinePoiDetailViewController(viewModel: detailVM)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - TRPSearchBarDelegate
extension AddPlanPOIListingVC: TRPSearchBarDelegate {

    public func searchBar(_ searchBar: TRPSearchBar, textDidChange text: String) {
        viewModel.updateSearchText(text)
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
        // POI count label is meaningless during skeleton mode (still rendering); show it
        // again only once we're back to `.none`.
        if viewModel.loadingStyle != .skeleton {
            updatePoiCountLabel()
        }
        updateTableFooter()
    }

    public func poiLoadingStateDidChange() {
        // Mirrors Activity Listing's `tourLoadingStateDidChange`
        // (`AddPlanActivityListingVC.swift:394`). The base helper marshals to the main
        // queue internally so the window-attached overlay attaches AFTER the modal
        // presentation has started compositing — otherwise the loader z-orders beneath
        // the still-presenting VC view.
        switch viewModel.loadingStyle {
        case .lottie:
            // First-open / heavy refetch — show full-screen window-attached Lottie. Idempotent.
            if !lottiePresented {
                lottiePresented = true
                let text = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.gettingPlaces)
                viewModel(showLottie: .fullScreen, textMode: .single(text))
            }
        case .skeleton, .bottomSheet, .none:
            // POI Listing doesn't drive `.bottomSheet` itself (it's an Activity Listing
            // category-change indicator), but the shared enum forces an exhaustive switch.
            // Treat it the same as `.skeleton`/`.none` here: tear down the full-screen
            // Lottie if it's still up. The table skeleton lives inside the cell so the
            // surrounding UI stays interactive — except for the count label which we
            // suppress in `poisDidLoad`.
            if lottiePresented {
                lottiePresented = false
                viewModel(hideLottie: .fullScreen)
            }
        }
    }

    public func segmentCreatedSuccessfully() {
        // Hide the in-flight bottom-sheet "Adding…" loader. Show a success toast on the
        // listing and stay open — the host VC refreshes its timeline silently via
        // `onSegmentCreatedSilent`, so the user can keep adding more POIs.
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
        // If an add was in flight, tear down the bottom-sheet loader before surfacing
        // the error alert so the two don't visually stack.
        viewModel(hideLottie: .bottomSheet)
        pendingPoiName = nil
        super.viewModel(error: error)
    }
}

// MARK: - POIListingCellDelegate
extension AddPlanPOIListingVC: POIListingCellDelegate {

    func poiListingCellDidTapAdd(_ cell: POIListingCell, poi: TRPPoi) {
        // Store POI temporarily
        pendingPoi = poi

        // Show time range selection
        let timeRangeVC = TRPTimeRangeSelectionViewController()
        timeRangeVC.delegate = self

        // Pass selected date for minimum time validation (prevents selecting past times for today)
        if let selectedDay = viewModel.planData.selectedDay {
            timeRangeVC.setSelectedDate(selectedDay)
        }

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

        // Clear pending POI; capture name for the eventual success toast.
        pendingPoi = nil
        pendingPoiName = poi.name

        // Show the bottom-sheet "Adding to your itinerary…" Lottie loader BEFORE the API
        // call. The loader stays visible through the whole create + GetTimeline polling
        // window — VM only fires `segmentCreatedSuccessfully` after polling completes.
        let text = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.addingToItinerary)
        viewModel(showLottie: .bottomSheet, textMode: .single(text))

        // Create segment with selected times
        viewModel.createManualPoiSegment(poi: poi, startTime: fromDate, endTime: toDate)
    }
}

// MARK: - TRPTimelineCustomNavigationBarDelegate
extension AddPlanPOIListingVC: TRPTimelineCustomNavigationBarDelegate {

    func customNavigationBarDidTapBack(_ navigationBar: TRPTimelineCustomNavigationBar) {
        // If the user backs out while the initial-fetch Lottie is still up (slow network),
        // make sure the window-attached overlay is torn down — otherwise it would orphan
        // on top of the underlying screen.
        if lottiePresented {
            lottiePresented = false
            viewModel(hideLottie: .fullScreen)
        }
        dismiss(animated: true)
    }
}
