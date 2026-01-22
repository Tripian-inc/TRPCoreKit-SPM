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

    // Temporarily stores selected POI while time range is being selected
    private var pendingPoi: TRPPoi?

    // Callback when segment is created successfully
    public var onSegmentCreated: (() -> Void)?

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
        sortButton.addTarget(self, action: #selector(sortButtonTapped), for: .touchUpInside)

        // Add info icon tap gesture
        let infoTapGesture = UITapGestureRecognizer(target: self, action: #selector(infoIconTapped))
        infoImageView.addGestureRecognizer(infoTapGesture)
    }

    // MARK: - Actions
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

    private func updateTableFooter() {
        if !viewModel.hasMorePois() {
            tableView.tableFooterView = nil
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension AddPlanPOIListingVC: UITableViewDataSource, UITableViewDelegate {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getPois().count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: POIListingCell.reuseIdentifier, for: indexPath) as? POIListingCell else {
            return UITableViewCell()
        }

        cell.delegate = self

        if let poi = viewModel.getPoiAt(index: indexPath.row) {
            cell.configure(with: poi)
        }

        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
        updatePoiCountLabel()
        updateTableFooter()
    }

    public func segmentCreatedSuccessfully() {
        dismiss(animated: true) { [weak self] in
            self?.onSegmentCreated?()
        }
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

        // Clear pending POI
        pendingPoi = nil

        // Create segment with selected times
        viewModel.createManualPoiSegment(poi: poi, startTime: fromDate, endTime: toDate)
    }
}

// MARK: - TRPTimelineCustomNavigationBarDelegate
extension AddPlanPOIListingVC: TRPTimelineCustomNavigationBarDelegate {

    func customNavigationBarDidTapBack(_ navigationBar: TRPTimelineCustomNavigationBar) {
        dismiss(animated: true)
    }
}
