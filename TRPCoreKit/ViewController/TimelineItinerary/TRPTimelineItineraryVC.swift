//
//  TRPTimelineItineraryVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 02.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import UIKit
import TRPFoundationKit

public protocol TRPTimelineItineraryVCDelegate: AnyObject {
    func timelineItineraryFilterPressed(_ viewController: TRPTimelineItineraryVC)
    func timelineItineraryAddPlansPressed(_ viewController: TRPTimelineItineraryVC)
    func timelineItineraryDidSelectStep(_ viewController: TRPTimelineItineraryVC, step: TRPTimelineStep)
    func timelineItineraryDidSelectBookedActivity(_ viewController: TRPTimelineItineraryVC, segment: TRPTimelineSegment)
    func timelineItineraryAddButtonPressed(_ viewController: TRPTimelineItineraryVC, atSectionIndex: Int)
    func timelineItineraryChangeTimePressed(_ viewController: TRPTimelineItineraryVC, step: TRPTimelineStep)
    func timelineItineraryRemoveStepPressed(_ viewController: TRPTimelineItineraryVC, step: TRPTimelineStep)
    func timelineItineraryDidRequestActivityReservation(_ viewController: TRPTimelineItineraryVC, activityId: String)
}

@objc(SPMTRPTimelineItineraryVC)
public class TRPTimelineItineraryVC: TRPBaseUIViewController {
    
    internal var viewModel: TRPTimelineItineraryViewModel!
    public weak var delegate: TRPTimelineItineraryVCDelegate?
    internal var map: TRPMapView?
    internal var hasLoadedInitialMapData: Bool = false
    
    // Cache for route calculations - keyed by route coordinates
    private var routeCache: [String: (distance: Float, time: Int)] = [:]
    
    // Store calculated distances for each section (using cached or new calculations)
    private var calculatedDistances: [IndexPath: [Int: (distance: Float, time: Int)]] = [:]
    
    // MARK: - UI Components
    private lazy var customNavigationBar: TRPTimelineCustomNavigationBar = {
        let bar = TRPTimelineCustomNavigationBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.delegate = self
        return bar
    }()
    
    private lazy var savedPlansButton: TRPTimelineSavedPlansButton = {
        let button = TRPTimelineSavedPlansButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.delegate = self
        button.isHidden = true // Hidden by default, shown if favorite items exist
        return button
    }()
    
    private lazy var dayFilterView: TRPTimelineDayFilterView = {
        let view = TRPTimelineDayFilterView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.separatorStyle = .none
        table.backgroundColor = .white
        table.showsVerticalScrollIndicator = true
        table.delegate = self
        table.dataSource = self
        table.estimatedRowHeight = 200
        table.rowHeight = UITableView.automaticDimension
        table.sectionHeaderHeight = UITableView.automaticDimension
        table.estimatedSectionHeaderHeight = 80
        table.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
        return table
    }()
    
    private lazy var mapFloatingButton: TRPFloatingActionButton = {
        let button = TRPFloatingActionButton(
            icon: TRPImageController().getImage(inFramework: "ic_map", inApp: nil),
            backgroundColor: ColorSet.fg.uiColor
        )
        button.addTarget(self, action: #selector(mapFloatingButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var addPlanFloatingButton: TRPFloatingActionButton = {
        let button = TRPFloatingActionButton(
            icon: TRPImageController().getImage(inFramework: "ic_plus_bold", inApp: nil),
            backgroundColor: ColorSet.fgPink.uiColor
        )
        button.addTarget(self, action: #selector(addPlanFloatingButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // Map container view is now internal for map view controller
    internal lazy var mapContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()
    
    // Bottom POI preview cards
    private lazy var poiPreviewContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()
    
    internal lazy var poiPreviewCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 8  // Gap between cells
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()
    
    private var poiPreviewBottomConstraint: NSLayoutConstraint?
    private var addPlanButtonBottomConstraint: NSLayoutConstraint?
    
    // Enum to handle both POIs and Booked Activities (legacy - kept for compatibility)
    internal enum TimelineItem {
        case poi(TRPPoi)
        case bookedActivity(TRPTimelineSegment)
    }

    internal var currentTimelineItems: [TimelineItem] = []

    /// Ordered map display items with unified order (matches list view ordering)
    internal var mapDisplayItems: [(order: Int, item: MapDisplayItem)] = []

    private var isShowingMap: Bool = false

    // Step being edited for time change
    private var stepBeingEdited: TRPTimelineStep?
    
    // Collection view state
    private var isCollectionViewExpanded: Bool = false
    private let collectionViewHeight: CGFloat = 120
    private let collapsedOffset: CGFloat = 114  // Only 5% visible (6pt out of 120pt)
    private let expandedOffset: CGFloat = -16   // Fully visible with margin
    
    // MARK: - Initialization
    public init(viewModel: TRPTimelineItineraryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        // Hide the default navigation bar
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        // Update saved plans button visibility after view is loaded
        updateSavedPlansButton()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ensure default navigation bar stays hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    public override func setupViews() {
        super.setupViews()
        setupCustomNavigationBar()
        setupSavedPlansButton()
        setupDayFilterView()
        setupTableView()
        setupMapView()
        setupPOIPreviewCards()
        setupFloatingButtons()
        registerCells()

        // Bring navigation bar and day filter to front so they appear above the map
        view.bringSubviewToFront(customNavigationBar)
        view.bringSubviewToFront(savedPlansButton)
        view.bringSubviewToFront(dayFilterView)
    }

    
    private func registerCells() {
        tableView.register(TRPTimelineBookedActivityCell.self, forCellReuseIdentifier: TRPTimelineBookedActivityCell.reuseIdentifier)
        tableView.register(TRPTimelineManualPoiCell.self, forCellReuseIdentifier: TRPTimelineManualPoiCell.reuseIdentifier)
        tableView.register(TRPTimelineActivityStepCell.self, forCellReuseIdentifier: TRPTimelineActivityStepCell.reuseIdentifier)
        tableView.register(TRPTimelineRecommendationsCell.self, forCellReuseIdentifier: TRPTimelineRecommendationsCell.reuseIdentifier)
        tableView.register(TRPTimelineEmptyStateCell.self, forCellReuseIdentifier: TRPTimelineEmptyStateCell.reuseIdentifier)
        tableView.register(TRPTimelineSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: TRPTimelineSectionHeaderView.reuseIdentifier)
        tableView.register(TRPTimelineSectionFooterView.self, forHeaderFooterViewReuseIdentifier: TRPTimelineSectionFooterView.reuseIdentifier)

        // POI preview cell for map view
        poiPreviewCollectionView.register(TRPTimelineMapPOIPreviewCell.self, forCellWithReuseIdentifier: TRPTimelineMapPOIPreviewCell.reuseIdentifier)
    }
    
    // MARK: - Setup Methods
    private func setupCustomNavigationBar() {
        guard customNavigationBar.superview == nil else { return }
        
        view.addSubview(customNavigationBar)
        
        NSLayoutConstraint.activate([
            customNavigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            customNavigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customNavigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customNavigationBar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupSavedPlansButton() {
        guard savedPlansButton.superview == nil else { return }
        
        view.addSubview(savedPlansButton)
        
        NSLayoutConstraint.activate([
            savedPlansButton.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor, constant: 12),
            savedPlansButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            savedPlansButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            savedPlansButton.heightAnchor.constraint(equalToConstant: 72)
        ])
    }
    
    private var dayFilterViewTopConstraint: NSLayoutConstraint?
    
    private func setupDayFilterView() {
        guard dayFilterView.superview == nil else { return }
        
        view.addSubview(dayFilterView)
        
        // Initial constraint: below navigation bar (since button is hidden by default)
        dayFilterViewTopConstraint = dayFilterView.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor, constant: 12)
        
        NSLayoutConstraint.activate([
            dayFilterViewTopConstraint!,
            dayFilterView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dayFilterView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dayFilterView.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func updateDayFilterViewConstraints() {
        // Update day filter view position based on saved plans button visibility
        let newConstraint: NSLayoutConstraint
        
        if savedPlansButton.isHidden {
            // Button is hidden: attach to navigation bar
            newConstraint = dayFilterView.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor, constant: 12)
        } else {
            // Button is visible: attach to button
            newConstraint = dayFilterView.topAnchor.constraint(equalTo: savedPlansButton.bottomAnchor, constant: 12)
        }
        
        // Deactivate old constraint and activate new one
        dayFilterViewTopConstraint?.isActive = false
        dayFilterViewTopConstraint = newConstraint
        dayFilterViewTopConstraint?.isActive = true
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: dayFilterView.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupMapView() {
        view.addSubview(mapContainerView)
        
        // Make map full screen (covers entire view)
        NSLayoutConstraint.activate([
            mapContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            mapContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupPOIPreviewCards() {
        view.addSubview(poiPreviewContainerView)
        poiPreviewContainerView.addSubview(poiPreviewCollectionView)
        
        // Use bottom constraint to slide in/out
        poiPreviewBottomConstraint = poiPreviewContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: collapsedOffset)
        
        NSLayoutConstraint.activate([
            // Container - fixed height, slides up/down via bottom constraint
            poiPreviewContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            poiPreviewContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            poiPreviewContainerView.heightAnchor.constraint(equalToConstant: collectionViewHeight),
            poiPreviewBottomConstraint!,
            
            // Collection View
            poiPreviewCollectionView.topAnchor.constraint(equalTo: poiPreviewContainerView.topAnchor),
            poiPreviewCollectionView.leadingAnchor.constraint(equalTo: poiPreviewContainerView.leadingAnchor),
            poiPreviewCollectionView.trailingAnchor.constraint(equalTo: poiPreviewContainerView.trailingAnchor),
            poiPreviewCollectionView.bottomAnchor.constraint(equalTo: poiPreviewContainerView.bottomAnchor)
        ])
    }
    
    private func setupFloatingButtons() {
        view.addSubview(mapFloatingButton)
        view.addSubview(addPlanFloatingButton)

        // Use constraint for add plan button bottom that we can animate
        addPlanButtonBottomConstraint = addPlanFloatingButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)

        NSLayoutConstraint.activate([
            // Map floating button - bottom right, above add plan button
            mapFloatingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            mapFloatingButton.bottomAnchor.constraint(equalTo: addPlanFloatingButton.topAnchor, constant: -16),

            // Add plan floating button - bottom right (constraint managed for animation)
            addPlanFloatingButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            addPlanButtonBottomConstraint!
        ])
    }
    
    // MARK: - Actions
    @objc private func mapFloatingButtonTapped() {
        // Toggle between list and map views
        toggleView()
    }
    
    @objc private func addPlanFloatingButtonTapped() {
        // Launch add plan flow
        showAddPlanFlow()
    }
    
    private func toggleView() {
        isShowingMap.toggle()
        
        if isShowingMap {
            // Show map view
            showMapView()
        } else {
            // Show list view
            showListView()
    }
    }
    
    private func showMapView() {
        // Hide list, show map
        UIView.animate(withDuration: 0.3) {
            self.tableView.isHidden = true
            self.mapContainerView.isHidden = false
            self.poiPreviewContainerView.isHidden = false

            // Hide saved plans button on map view
            self.savedPlansButton.isHidden = true

            // Make header transparent for map view
            self.customNavigationBar.backgroundColor = .clear
            self.dayFilterView.backgroundColor = .clear

            // Update floating button icon to list
            self.mapFloatingButton.updateIcon(TRPImageController().getImage(inFramework: "ic_list", inApp: nil))
        }

        // Update day filter position (move up since savedPlansButton is hidden)
        updateDayFilterViewConstraints()

        // Initialize map if needed
            if map == nil {
                initializeMap()
            } else {
                refreshMap()
            }

        // Update POI preview cards
        updatePOIPreviewCards()
    }
    
    private func showListView() {
        // Hide map, show list
        UIView.animate(withDuration: 0.3) {
            self.tableView.isHidden = false
            self.mapContainerView.isHidden = true
            self.poiPreviewContainerView.isHidden = true

            // Reset FAB positions to original
            self.addPlanButtonBottomConstraint?.constant = -24
            self.view.layoutIfNeeded()

            // Update floating button icon to map
            self.mapFloatingButton.updateIcon(TRPImageController().getImage(inFramework: "ic_map", inApp: nil))
        }

        // Reset collection view state
        isCollectionViewExpanded = false

        // Restore saved plans button visibility
        updateSavedPlansButton()
    }
    
    private func updatePOIPreviewCards() {
        // Get ordered items from ViewModel (uses unified order matching list view)
        mapDisplayItems = viewModel.getOrderedItemsForMap()

        // Also update legacy currentTimelineItems for compatibility
        currentTimelineItems = []
        for (_, item) in mapDisplayItems {
            switch item {
            case .poi(let poi, _, _):
                currentTimelineItems.append(.poi(poi))
            case .activity(let segment):
                currentTimelineItems.append(.bookedActivity(segment))
            }
        }

        if mapDisplayItems.isEmpty {
            // Hide completely if no items
            poiPreviewBottomConstraint?.constant = -collectionViewHeight
        } else {
            // Start in collapsed state (half visible)
            isCollectionViewExpanded = false
            poiPreviewBottomConstraint?.constant = collapsedOffset
            addPlanButtonBottomConstraint?.constant = -24
        }

        poiPreviewCollectionView.reloadData()
    }
    
    // MARK: - Collection View Expand/Collapse
    internal func expandCollectionView(completion: (() -> Void)? = nil) {
        guard !isCollectionViewExpanded else {
            completion?()
            return
        }
        isCollectionViewExpanded = true
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            // Slide collection view up to be fully visible
            self.poiPreviewBottomConstraint?.constant = self.expandedOffset
            // Move add plan button above collection view
            self.addPlanButtonBottomConstraint?.constant = self.expandedOffset - self.collectionViewHeight - 24
            self.view.layoutIfNeeded()
        }, completion: { _ in
            completion?()
        })
    }
    
    internal func collapseCollectionView() {
        guard isCollectionViewExpanded else { return }
        isCollectionViewExpanded = false
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            // Slide collection view down to be half visible
            self.poiPreviewBottomConstraint?.constant = self.collapsedOffset
            // Move add plan button back to original position
            self.addPlanButtonBottomConstraint?.constant = -24
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Public Methods
    public func reload() {
        // Clear both caches when reloading data
        routeCache.removeAll()
        calculatedDistances.removeAll()
        dayFilterView.configure(with: viewModel.getAvailableDates(), selectedDay: viewModel.selectedDayIndex)
        
        // Update saved plans button visibility and count
        updateSavedPlansButton()
        
        tableView.reloadData()
    }
    
    private func updateSavedPlansButton() {
        let hasFavorites = viewModel.hasFavoriteItems()
        savedPlansButton.isHidden = !hasFavorites
        
        if hasFavorites {
            let favoriteCount = viewModel.getFavoriteItemsCount()
            savedPlansButton.configure(savedPlansCount: favoriteCount)
        }
        
        // Update day filter view constraints based on button visibility
        updateDayFilterViewConstraints()
    }
    
    /// Update timeline data
    /// - Parameter timeline: New timeline data
    public func updateTimeline(_ timeline: TRPTimeline) {
        // Clear both caches when timeline data changes
        routeCache.removeAll()
        calculatedDistances.removeAll()
        viewModel.updateTimeline(timeline)
        reload()
    }
    
    /// Set the custom navigation bar title
    /// - Parameter title: The title to display
    public func setNavigationTitle(_ title: String) {
        customNavigationBar.setTitle(title)
    }
    
    /// Get the current navigation bar title
    public func getNavigationTitle() -> String? {
        return customNavigationBar.getTitle()
    }
    
    /// Debug helper to print timeline information
}

// MARK: - UITableViewDataSource
extension TRPTimelineItineraryVC: UITableViewDataSource {

    public func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(in: section)
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cellType = viewModel.cellType(at: indexPath) else {
            return UITableViewCell()
        }
        return configureCell(for: cellType, at: indexPath, in: tableView)
    }

    /// Configure cell using TimelineCellType with pre-computed cell data
    private func configureCell(for cellType: TimelineCellType, at indexPath: IndexPath, in tableView: UITableView) -> UITableViewCell {
        switch cellType {
        case .bookedActivity(let cellData):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TRPTimelineBookedActivityCell.reuseIdentifier, for: indexPath) as? TRPTimelineBookedActivityCell else {
                return UITableViewCell()
            }
            cell.configure(with: cellData)
            cell.delegate = self
            return cell

        case .reservedActivity(let cellData):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TRPTimelineBookedActivityCell.reuseIdentifier, for: indexPath) as? TRPTimelineBookedActivityCell else {
                return UITableViewCell()
            }
            cell.configure(with: cellData)
            cell.delegate = self
            return cell

        case .manualPoi(let cellData):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TRPTimelineManualPoiCell.reuseIdentifier, for: indexPath) as? TRPTimelineManualPoiCell else {
                return UITableViewCell()
            }
            cell.configure(with: cellData)
            cell.delegate = self
            return cell

        case .activityStep(let cellData):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TRPTimelineActivityStepCell.reuseIdentifier, for: indexPath) as? TRPTimelineActivityStepCell else {
                return UITableViewCell()
            }
            cell.configure(with: cellData.step, order: cellData.step.order)
            cell.delegate = self
            return cell

        case .recommendations(let cellData):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TRPTimelineRecommendationsCell.reuseIdentifier, for: indexPath) as? TRPTimelineRecommendationsCell else {
                return UITableViewCell()
            }
            cell.configure(with: cellData)
            cell.delegate = self

            // Apply any pre-calculated distances
            if let distances = calculatedDistances[indexPath] {
                for (index, distanceData) in distances {
                    cell.updateDistance(at: index, distance: distanceData.distance, time: distanceData.time)
                }
            }

            return cell

        case .emptyState:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TRPTimelineEmptyStateCell.reuseIdentifier, for: indexPath) as? TRPTimelineEmptyStateCell else {
                return UITableViewCell()
            }
            cell.configure()
            cell.delegate = self
            return cell
        }
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerData = viewModel.headerData(for: section)

        // Don't show header if shouldShowHeader is false
        guard headerData.shouldShowHeader else {
            return nil
        }

        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TRPTimelineSectionHeaderView.reuseIdentifier) as? TRPTimelineSectionHeaderView else {
            return nil
        }

        headerView.configure(with: headerData)
        headerView.delegate = self
        return headerView
    }
}

// MARK: - UITableViewDelegate
extension TRPTimelineItineraryVC: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let headerData = viewModel.headerData(for: section)

        // Return 0 height if header should not be shown
        guard headerData.shouldShowHeader else {
            return 0
        }

        // Return automatic dimension for header
        return UITableView.automaticDimension
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        let headerData = viewModel.headerData(for: section)

        // Return 0 estimated height if header should not be shown
        guard headerData.shouldShowHeader else {
            return 0
        }

        // Return estimated height for header
        return 80
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // Don't show footer for empty state
        if viewModel.numberOfSections() == 1,
           viewModel.numberOfRows(in: section) == 1,
           let cellType = viewModel.cellType(at: IndexPath(row: 0, section: section)),
           case .emptyState = cellType {
            return nil
        }

        // Don't show footer after the last section
        guard section < viewModel.numberOfSections() - 1 else {
            return nil
        }

        guard let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TRPTimelineSectionFooterView.reuseIdentifier) as? TRPTimelineSectionFooterView else {
            return nil
        }

        footerView.configure(section: section)
        footerView.delegate = self
        return footerView
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // Don't show footer for empty state
        if viewModel.numberOfSections() == 1,
           viewModel.numberOfRows(in: section) == 1,
           let cellType = viewModel.cellType(at: IndexPath(row: 0, section: section)),
           case .emptyState = cellType {
            return 0
        }

        // Don't show footer after the last section
        guard section < viewModel.numberOfSections() - 1 else {
            return 0
        }

        return 60
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        // Don't show footer for empty state
        if viewModel.numberOfSections() == 1,
           viewModel.numberOfRows(in: section) == 1,
           let cellType = viewModel.cellType(at: IndexPath(row: 0, section: section)),
           case .emptyState = cellType {
            return 0
        }

        // Don't show footer after the last section
        guard section < viewModel.numberOfSections() - 1 else {
            return 0
        }

        return 60
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let cellType = viewModel.cellType(at: indexPath) else {
            return
        }

        switch cellType {
        case .bookedActivity(let cellData):
            delegate?.timelineItineraryDidSelectBookedActivity(self, segment: cellData.segment)

        case .reservedActivity(let cellData):
            delegate?.timelineItineraryDidSelectBookedActivity(self, segment: cellData.segment)

        case .manualPoi:
            // Manual POI cell handles selection internally via TRPTimelineManualPoiCellDelegate
            break

        case .activityStep(let cellData):
            delegate?.timelineItineraryDidSelectStep(self, step: cellData.step)

        case .recommendations:
            // Recommendations cell handles selection internally
            break

        case .emptyState:
            // Empty state cell handles selection internally via button
            break
        }
    }
}

// MARK: - TRPTimelineDayFilterViewDelegate
extension TRPTimelineItineraryVC: TRPTimelineDayFilterViewDelegate {
    
    public func dayFilterViewDidSelectDay(_ view: TRPTimelineDayFilterView, dayIndex: Int) {
        // Clear only the IndexPath-based cache, keep route calculations cached
        calculatedDistances.removeAll()
        viewModel.selectDay(at: dayIndex)
        tableView.reloadData()

        // Scroll table view to top after reload
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.viewModel.numberOfSections() > 0 && self.viewModel.numberOfRows(in: 0) > 0 {
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            } else {
                self.tableView.setContentOffset(.zero, animated: true)
            }
        }

        // If map is showing, refresh it and update POI cards
        if isShowingMap {
                refreshMap()
            updatePOIPreviewCards()

            // Scroll collection view to the beginning
            if !currentTimelineItems.isEmpty {
                poiPreviewCollectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .left, animated: true)
            }
        }
    }
    
}

// MARK: - TRPTimelineBookedActivityCellDelegate
extension TRPTimelineItineraryVC: TRPTimelineBookedActivityCellDelegate {

    func bookedActivityCellDidTapMoreOptions(_ cell: TRPTimelineBookedActivityCell) {
        // Handle more options
    }

    func bookedActivityCellDidTapReservation(_ cell: TRPTimelineBookedActivityCell, segment: TRPTimelineSegment) {
        // Notify delegate about activity reservation request
        guard let activityId = segment.additionalData?.activityId else {
            return
        }
        TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityReservation(activityId: activityId)
    }

    func bookedActivityCellDidTapRemove(_ cell: TRPTimelineBookedActivityCell, segment: TRPTimelineSegment) {
        showConfirmAlert(
            title: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.removeActivityTitle),
            message: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.removeActivityMessage),
            confirmTitle: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.remove),
            cancelTitle: CommonLocalizationKeys.localized(CommonLocalizationKeys.cancel),
            btnConfirmAction: { [weak self] in
                self?.viewModel.removeSegment(segment)
            }
        )
    }
}

// MARK: - TRPTimelineActivityStepCellDelegate
extension TRPTimelineItineraryVC: TRPTimelineActivityStepCellDelegate {

    func activityStepCellDidTapMoreOptions(_ cell: TRPTimelineActivityStepCell) {
        // Handle more options for activity steps
    }

    func activityStepCellDidTapReservation(_ cell: TRPTimelineActivityStepCell, step: TRPTimelineStep) {
        // Notify delegate about activity reservation request
        guard let activityId = step.poi?.id else {
            return
        }
        TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityReservation(activityId: activityId)
    }
}

// MARK: - TRPTimelineManualPoiCellDelegate
extension TRPTimelineItineraryVC: TRPTimelineManualPoiCellDelegate {

    func manualPoiCellDidTapChangeTime(_ cell: TRPTimelineManualPoiCell, segment: TRPTimelineSegment) {
        // TODO: Implement time change for manual POI
    }

    func manualPoiCellDidTapRemove(_ cell: TRPTimelineManualPoiCell, segment: TRPTimelineSegment) {
        showConfirmAlert(
            title: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.removeActivityTitle),
            message: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.removeActivityMessage),
            confirmTitle: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.remove),
            cancelTitle: CommonLocalizationKeys.localized(CommonLocalizationKeys.cancel),
            btnConfirmAction: { [weak self] in
                self?.viewModel.removeSegment(segment)
            }
        )
    }

    func manualPoiCellDidTapCell(_ cell: TRPTimelineManualPoiCell, segment: TRPTimelineSegment, poi: TRPPoi?) {
        // Open POI detail
        if let poi = poi {
            let detailVM = TimelinePoiDetailViewModel(poi: poi)
            let detailVC = TimelinePoiDetailViewController(viewModel: detailVM)
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}

// MARK: - TRPTimelineSectionHeaderViewDelegate
extension TRPTimelineItineraryVC: TRPTimelineSectionHeaderViewDelegate {
    // No delegate methods needed - FAB handles adding plans
}

// MARK: - TRPTimelineSectionFooterViewDelegate
extension TRPTimelineItineraryVC: TRPTimelineSectionFooterViewDelegate {
    
    func sectionFooterViewDidTapAdd(_ view: TRPTimelineSectionFooterView, section: Int) {
        delegate?.timelineItineraryAddButtonPressed(self, atSectionIndex: section)
    }
}

// MARK: - TRPTimelineEmptyStateCellDelegate
extension TRPTimelineItineraryVC: TRPTimelineEmptyStateCellDelegate {
    
    func emptyStateCellDidTapAddPlan(_ cell: TRPTimelineEmptyStateCell) {
        // Launch add plan flow
        showAddPlanFlow()
    }
}

// MARK: - TRPTimelineRecommendationsCellDelegate
extension TRPTimelineItineraryVC: TRPTimelineRecommendationsCellDelegate {
    
    func recommendationsCellDidTapClose(_ cell: TRPTimelineRecommendationsCell, segment: TRPTimelineSegment?) {
        guard let segment = segment else { return }

        showConfirmAlert(
            title: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.removeRecommendationsTitle),
            message: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.removeRecommendationsMessage),
            confirmTitle: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.remove),
            cancelTitle: CommonLocalizationKeys.localized(CommonLocalizationKeys.cancel),
            btnConfirmAction: { [weak self] in
                self?.viewModel.removeSegment(segment)
            }
        )
    }
    
    func recommendationsCellDidTapToggle(_ cell: TRPTimelineRecommendationsCell, isExpanded: Bool) {
        // Get cell's section to save state
        if let indexPath = tableView.indexPath(for: cell) {
            // Save collapse state in ViewModel
            viewModel.setSectionCollapseState(for: indexPath.section, isExpanded: isExpanded)
        }

        // Handle expand/collapse - table will auto-adjust
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    func recommendationsCellDidSelectStep(_ cell: TRPTimelineRecommendationsCell, step: TRPTimelineStep) {
        // Open new POI detail view controller
        guard let poi = step.poi else { return }

        let viewModel = TimelinePoiDetailViewModel(poi: poi)
        let detailVC = TimelinePoiDetailViewController(viewModel: viewModel)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func recommendationsCellDidTapChangeTime(_ cell: TRPTimelineRecommendationsCell, step: TRPTimelineStep) {
        // Store the step being edited
        stepBeingEdited = step

        // Get current start and end times from step
        let timeRangeVC = TRPTimeRangeSelectionViewController()
        timeRangeVC.delegate = self

        // Parse step times and set as initial values
        if let startDateTimes = step.startDateTimes,
           let endDateTimes = step.endDateTimes,
           let startDate = parseStepDateTime(startDateTimes),
           let endDate = parseStepDateTime(endDateTimes) {
            timeRangeVC.setInitialTimes(from: startDate, to: endDate)
        }

        // Present the time selection view controller
        timeRangeVC.show(from: self)
    }

    /// Parses step datetime string to Date without timezone conversion
    /// Supports formats: "yyyy-MM-dd HH:mm:ss" and "yyyy-MM-dd HH:mm"
    /// Uses current timezone to avoid UTC conversion issues
    private func parseStepDateTime(_ dateTimeString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current // Use local timezone, not UTC

        // Try format with seconds first (server format)
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = dateFormatter.date(from: dateTimeString) {
            return date
        }

        // Try format without seconds
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return dateFormatter.date(from: dateTimeString)
    }

    func recommendationsCellDidTapRemoveStep(_ cell: TRPTimelineRecommendationsCell, step: TRPTimelineStep) {
        showConfirmAlert(
            title: "Remove Step",
            message: "Are you sure you want to remove this step from your itinerary?",
            confirmTitle: "Remove",
            btnConfirmAction: { [weak self] in
                self?.viewModel.removeStep(step)
            }
        )
    }

    func recommendationsCellDidTapReservation(_ cell: TRPTimelineRecommendationsCell, step: TRPTimelineStep) {
        // Handle reservation tap for activity steps
        // Try to get product ID from POI's bookings first, fallback to POI id
        guard let poi = step.poi else { return }

        let activityId: String
        if let booking = poi.bookings?.first, let product = booking.firstProduct() {
            activityId = product.id
        } else {
            // Fallback to POI id if no booking product available
            activityId = poi.id
        }

        // Delegate to coordinator to open reservation flow
        delegate?.timelineItineraryDidRequestActivityReservation(self, activityId: activityId)
    }

    func recommendationsCellNeedsRouteCalculation(_ cell: TRPTimelineRecommendationsCell, from: TRPLocation, to: TRPLocation, index: Int) {
        // Get the index path of the cell
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        // Generate cache key from coordinates
        let cacheKey = generateRouteCacheKey(from: from, to: to)
        
        // Check if we have this route cached
        if let cachedResult = routeCache[cacheKey] {
            // Use cached result immediately
            if calculatedDistances[indexPath] == nil {
                calculatedDistances[indexPath] = [:]
            }
            calculatedDistances[indexPath]?[index] = cachedResult
            
            // Update the cell
            cell.updateDistance(at: index, distance: cachedResult.distance, time: cachedResult.time)
            return
        }
        
        // Calculate route between two POIs
        viewModel.calculateRoute(for: [from, to]) { [weak self] route, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                let distanceData: (distance: Float, time: Int)
                
                if let route = route {
                    // Convert distance and time to readable format
                    let readable = ReadableDistance.calculate(distance: Float(route.distance), time: route.expectedTravelTime)
                    distanceData = (distance: readable.distance, time: readable.time)
                } else {
                    // Store failed calculation
                    distanceData = (distance: 0, time: 0)
                }
                
                // Cache the result
                self.routeCache[cacheKey] = distanceData
                
                // Store the calculated distance for this cell
                if self.calculatedDistances[indexPath] == nil {
                    self.calculatedDistances[indexPath] = [:]
                }
                self.calculatedDistances[indexPath]?[index] = distanceData
                
                // Update the cell if it's still visible
                if let currentCell = self.tableView.cellForRow(at: indexPath) as? TRPTimelineRecommendationsCell {
                    currentCell.updateDistance(at: index, distance: distanceData.distance, time: distanceData.time)
                }
            }
        }
    }
    
    private func generateRouteCacheKey(from: TRPLocation, to: TRPLocation) -> String {
        // Create a unique key based on coordinates (rounded to avoid floating point precision issues)
        let fromLat = String(format: "%.6f", from.lat)
        let fromLon = String(format: "%.6f", from.lon)
        let toLat = String(format: "%.6f", to.lat)
        let toLon = String(format: "%.6f", to.lon)
        return "\(fromLat),\(fromLon)-\(toLat),\(toLon)"
    }
}

// MARK: - TRPTimelineCustomNavigationBarDelegate
extension TRPTimelineItineraryVC: TRPTimelineCustomNavigationBarDelegate {
    
    func customNavigationBarDidTapBack(_ navigationBar: TRPTimelineCustomNavigationBar) {
        // Close SDK when back button is tapped
        // Since this is the root screen after splash, dismiss the entire navigation controller
        if let navController = navigationController {
            // Dismiss the navigation controller to close SDK
            navController.dismiss(animated: true, completion: nil)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegateFlowLayout
extension TRPTimelineItineraryVC: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mapDisplayItems.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TRPTimelineMapPOIPreviewCell.reuseIdentifier, for: indexPath) as? TRPTimelineMapPOIPreviewCell else {
            return UICollectionViewCell()
        }

        let (order, item) = mapDisplayItems[indexPath.item]

        // Configure cell with MapDisplayItem and unified order
        cell.configure(with: item, order: order)

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 300, height: 104)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Expand the collection view when user taps on an item
        expandCollectionView()

        let (_, item) = mapDisplayItems[indexPath.item]

        // Center map on selected item's coordinate
        if let coordinate = item.coordinate, let mapView = map {
            mapView.setCenter(coordinate, zoomLevel: 15)
        }
    }
}

// MARK: - Add Plan Flow
extension TRPTimelineItineraryVC {
    
    public func showAddPlanFlow() {
        // Get available days and cities from view model
        let days = viewModel.getDayDates()
        let cities = viewModel.getCities()
        let selectedDayIndex = viewModel.selectedDayIndex
        let bookedActivities = viewModel.getAllBookedActivities()

        // Create container view model
        let containerViewModel = AddPlanContainerViewModel(days: days,
                                                           cities: cities,
                                                           selectedDayIndex: selectedDayIndex,
                                                           bookedActivities: bookedActivities)

        // Inject tripHash into planData
        containerViewModel.planData.tripHash = viewModel.getTripHash()

        // Create container VC
        let containerVC = AddPlanContainerVC()
        containerVC.viewModel = containerViewModel
        containerVC.delegate = self
        
        // Create step ViewModels and VCs
        let selectDayViewModel = AddPlanSelectDayViewModel(containerViewModel: containerViewModel)
        let selectDayVC = AddPlanSelectDayVC()
        selectDayVC.viewModel = selectDayViewModel
        selectDayVC.containerVC = containerVC
        
        let timeAndTravelersViewModel = AddPlanTimeAndTravelersViewModel(containerViewModel: containerViewModel)
        let timeAndTravelersVC = AddPlanTimeAndTravelersVC()
        timeAndTravelersVC.viewModel = timeAndTravelersViewModel
        timeAndTravelersVC.containerVC = containerVC
        
        let categoryViewModel = AddPlanCategorySelectionViewModel(containerViewModel: containerViewModel)
        let categoryVC = AddPlanCategorySelectionVC()
        categoryVC.viewModel = categoryViewModel
        categoryVC.containerVC = containerVC
        
        // Add VCs to container
        containerVC.addViewController(selectDayVC)
        containerVC.addViewController(timeAndTravelersVC)
        containerVC.addViewController(categoryVC)

        // Present as bottom sheet modal with dynamic height
        presentVCWithDynamicHeight(containerVC)
    }
}

// MARK: - AddPlanContainerVCDelegate
extension TRPTimelineItineraryVC: AddPlanContainerVCDelegate {

    public func addPlanContainerDidComplete(_ viewController: AddPlanContainerVC, data: AddPlanData) {
        // Check if Smart Recommendations mode
        guard data.selectedMode == .smartRecommendations else {
            // For manual mode, just dismiss (existing behavior)
            viewController.dismiss(animated: true)
            return
        }

        // Create segment for Smart Recommendations
        createSmartRecommendationSegment(from: data, containerVC: viewController)
    }

    public func addPlanContainerDidCancel(_ viewController: AddPlanContainerVC) {
        // Dismissed without completing
    }
    
    public func addPlanContainerShouldShowActivityListing(_ viewController: AddPlanContainerVC, data: AddPlanData) {
        // Don't dismiss the add plan container - present activity listing on top of it
        // This allows user to go back to add plan screen

        // Create activity listing ViewModel with the plan data
        let activityListingViewModel = AddPlanActivityListingViewModel(planData: data)
        let activityListingVC = AddPlanActivityListingVC()
        activityListingVC.viewModel = activityListingViewModel

        // Set segment creation callback
        activityListingVC.onSegmentCreated = { [weak self, weak viewController] in
            guard let self = self, let viewController = viewController else { return }
            // Trigger container delegate
            self.addPlanContainerSegmentCreated(viewController)
        }

        // Create navigation controller for the activity listing
        let navController = UINavigationController(rootViewController: activityListingVC)
        navController.modalPresentationStyle = .fullScreen

        // Set title
        activityListingVC.title = AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.categoryActivities)

        // Present from the AddPlanContainerVC instead of dismissing it first
        viewController.present(navController, animated: true)
    }

    public func addPlanContainerShouldShowPOIListing(_ viewController: AddPlanContainerVC, data: AddPlanData, categoryType: POIListingCategoryType) {
        // Don't dismiss the add plan container - present POI listing on top of it
        // This allows user to go back to add plan screen

        // Create POI listing ViewModel with the plan data and category type
        let poiListingViewModel = AddPlanPOIListingViewModel(planData: data, categoryType: categoryType)
        let poiListingVC = AddPlanPOIListingVC()
        poiListingVC.viewModel = poiListingViewModel

        // Set segment creation callback
        poiListingVC.onSegmentCreated = { [weak self, weak viewController] in
            guard let self = self, let viewController = viewController else { return }
            // Trigger container delegate
            self.addPlanContainerSegmentCreated(viewController)
        }

        // Create navigation controller for the POI listing
        let navController = UINavigationController(rootViewController: poiListingVC)
        navController.modalPresentationStyle = .fullScreen

        // Present from the AddPlanContainerVC instead of dismissing it first
        viewController.present(navController, animated: true)
    }

    public func addPlanContainerSegmentCreated(_ viewController: AddPlanContainerVC) {
        // Dismiss all modals from self (TRPTimelineItineraryVC)
        // This will dismiss AddPlanContainerVC and all modals presented on top of it
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            // Refresh timeline after segment creation
            self.refreshTimeline()
        }
    }

    private func refreshTimeline() {
        guard let tripHash = viewModel.getTripHash() else { return }

        // Wait for segment generation to complete, then refresh timeline
        viewModel.waitForSegmentGeneration(tripHash: tripHash)
    }

    // MARK: - Smart Recommendations Segment Creation

    private func createSmartRecommendationSegment(from data: AddPlanData, containerVC: AddPlanContainerVC) {
        // Delegate segment creation to ViewModel
        viewModel.createSmartRecommendationSegment(from: data)

        // Dismiss AddPlan modal after initiating segment creation
        containerVC.dismiss(animated: true)
    }
}

// MARK: - TRPTimelineItineraryViewModelDelegate
extension TRPTimelineItineraryVC: TRPTimelineItineraryViewModelDelegate {

    public func timelineItineraryViewModel(didUpdateTimeline: Bool) {
        guard didUpdateTimeline else { return }
        reload()
    }
}

// MARK: - TRPTimelineSavedPlansButtonDelegate
extension TRPTimelineItineraryVC: TRPTimelineSavedPlansButtonDelegate {

    func savedPlansButtonDidTap(_ button: TRPTimelineSavedPlansButton) {
        // Open saved/favorite plans list
        showSavedPlans()
    }

    private func showSavedPlans() {
        let favouriteItems = viewModel.getFavoriteItems()
        let tripHash = viewModel.getTripHash()
        let availableDays = viewModel.getDayDates()
        let availableCities = viewModel.getCities()

        let savedPlansViewModel = SavedPlansViewModel(
            favouriteItems: favouriteItems,
            tripHash: tripHash,
            availableDays: availableDays,
            availableCities: availableCities
        )

        let savedPlansVC = SavedPlansVC(viewModel: savedPlansViewModel)

        // Set callback for segment creation
        savedPlansVC.onSegmentCreated = { [weak self] in
            guard let self = self else { return }
            // Refresh timeline after segment is created
            self.refreshTimeline()
        }

        // Present in navigation controller
        let navController = UINavigationController(rootViewController: savedPlansVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
}

// MARK: - TRPTimeRangeSelectionDelegate
extension TRPTimelineItineraryVC: TRPTimeRangeSelectionDelegate {

    func timeRangeSelected(fromTime: String, toTime: String) {
        guard let step = stepBeingEdited else { return }

        // fromTime and toTime are already in "HH:mm" format from TRPTimeRangeSelectionViewController
        viewModel.updateStepTime(step: step, startTime: fromTime, endTime: toTime) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                // Clear the step being edited
                self.stepBeingEdited = nil
                // Notify delegate if needed
                self.delegate?.timelineItineraryChangeTimePressed(self, step: step)

            case .failure:
                // Error is already handled by ViewModel (shows error via delegate)
                self.stepBeingEdited = nil
            }
        }
    }

    func timeRangeSelected(fromDate: Date, toDate: Date) {
        // Not used - we use the String version
    }
}

