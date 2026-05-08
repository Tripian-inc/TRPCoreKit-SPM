//
//  TRPTimelineItineraryVC.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 02.12.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - Main VC file now contains only core logic
//  Extensions:
//    - +Setup.swift: UI setup and cell registration
//    - +TableView.swift: UITableViewDataSource/Delegate
//    - +CellDelegates.swift: All cell delegate implementations
//    - +AddPlan.swift: Add plan flow and related delegates
//    - +Map.swift: Map view functionality
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
    func timelineItineraryDidRequestActivityReservation(_ viewController: TRPTimelineItineraryVC, activityId: String, date: Date)
}

@objc(SPMTRPTimelineItineraryVC)
public class TRPTimelineItineraryVC: TRPBaseUIViewController {

    // MARK: - Properties

    internal var viewModel: TRPTimelineItineraryViewModel!
    public weak var delegate: TRPTimelineItineraryVCDelegate?
    internal var map: TRPMapView?
    internal var hasLoadedInitialMapData: Bool = false

    // Cache for route calculations - keyed by route coordinates
    internal var routeCache: [String: (distance: Float, time: Int)] = [:]

    // Store calculated distances for each section (using cached or new calculations)
    internal var calculatedDistances: [IndexPath: [Int: (distance: Float, time: Int)]] = [:]

    // MARK: - UI Components

    internal var customNavigationBar: TRPTimelineCustomNavigationBar!

    internal lazy var savedPlansButton: TRPTimelineSavedPlansButton = {
        let button = TRPTimelineSavedPlansButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.delegate = self
        button.isHidden = true // Hidden by default, shown if favorite items exist
        return button
    }()

    internal lazy var dayFilterView: TRPTimelineDayFilterView = {
        let view = TRPTimelineDayFilterView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()

    internal lazy var tableView: UITableView = {
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

    internal lazy var mapFloatingButton: TRPFloatingActionButton = {
        let button = TRPFloatingActionButton(
            icon: TRPImageController().getImage(inFramework: "ic_map", inApp: nil),
            backgroundColor: ColorSet.fg.uiColor
        )
        button.addTarget(self, action: #selector(mapFloatingButtonTapped), for: .touchUpInside)
        return button
    }()

    internal lazy var addPlanFloatingButton: TRPFloatingActionButton = {
        let button = TRPFloatingActionButton(
            icon: TRPImageController().getImage(inFramework: "ic_plus_bold", inApp: nil),
            backgroundColor: ColorSet.primary.uiColor
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

    // Main View button - returns to overview zoom when focused on a marker
    internal lazy var mainViewButton: TRPMainViewButton = {
        let button = TRPMainViewButton()
        button.addTarget(self, action: #selector(mainViewButtonTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    // Bottom POI preview cards
    internal lazy var poiPreviewContainerView: UIView = {
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
        collectionView.decelerationRate = .fast  // For better custom paging experience
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()

    // No city empty state view
    internal lazy var noCityView: TRPNoCityView = {
        let view = TRPNoCityView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        view.isHidden = true
        return view
    }()

    internal var poiPreviewBottomConstraint: NSLayoutConstraint?
    internal var addPlanButtonBottomConstraint: NSLayoutConstraint?
    internal var dayFilterViewTopConstraint: NSLayoutConstraint?
    internal var mapFloatingButtonBottomToAddPlanConstraint: NSLayoutConstraint?
    internal var mapFloatingButtonBottomToPreviewConstraint: NSLayoutConstraint?
    internal var mapFloatingButtonBottomToSafeAreaConstraint: NSLayoutConstraint?

    // Type alias for backward compatibility (model moved to TRPDataLayer/Domain/Models/Timeline/)
    internal typealias TimelineItem = TRPTimelineItem

    internal var currentTimelineItems: [TimelineItem] = []

    /// Ordered map display items with unified order per city (matches list view ordering)
    internal var mapDisplayItems: [(order: Int, section: Int, cityIndex: Int, item: MapDisplayItem)] = []

    internal var isShowingMap: Bool = false

    // Focus tracking for Main View button
    internal var isMarkerFocused: Bool = false
    internal var hasMultipleCitiesOnSelectedDay: Bool = false

    // Multi-city zoom state: true when zoomed in enough to show step markers
    internal var isShowingStepMarkersInMultiCity: Bool = false
    internal let multiCityZoomThreshold: CGFloat = 12.0  // Above this = show step markers

    // Selected marker tracking for marker appearance (one per city)
    internal var selectedMarkerPoiIds: Set<String> = []

    // Step being edited for time change
    internal var stepBeingEdited: TRPTimelineStep?

    // Segment being edited for time change (manual POI)
    internal var segmentBeingEdited: TRPTimelineSegment?

    // Collection view state
    internal var isCollectionViewExpanded: Bool = false
    internal let collectionViewHeight: CGFloat = 120
    internal let collapsedOffset: CGFloat = 60   // 50% visible (60pt of 120pt)
    internal let expandedOffset: CGFloat = -16   // Fully visible with margin

    // Status bar for fullscreen map
    private var statusBarHidden: Bool = false

    // MARK: - Status Bar

    public override var prefersStatusBarHidden: Bool {
        return statusBarHidden
    }

    public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }

    private func setStatusBarHidden(_ hidden: Bool) {
        statusBarHidden = hidden
        UIView.animate(withDuration: 0.3) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }

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

        // Check if no city state should be shown immediately
        if viewModel.showNoCityStateOnLoad {
            timelineItineraryViewModel(noCitiesAvailable: true)
        }

        // If the ViewModel was constructed with a tripHash only, fetch the timeline now
        // (Lottie loader is shown via delegate from inside the ViewModel).
        // Deferred to next runloop so Lottie modal presentation doesn't race with this VC's own presentation.
        DispatchQueue.main.async { [weak self] in
            self?.viewModel.loadInitialTimelineIfNeeded()
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ensure default navigation bar stays hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    public override func setupViews() {
        super.setupViews()
        setupTimelineNavigationBar()
        setupSavedPlansButton()
        setupDayFilterView()
        setupTableView()
        setupMapView()
        setupPOIPreviewCards()
        setupMainViewButton()
        setupFloatingButtons()
        setupNoCityView()
        registerCells()

        // Bring navigation bar, day filter, and main view button to front so they appear above the map
        view.bringSubviewToFront(customNavigationBar)
        view.bringSubviewToFront(savedPlansButton)
        view.bringSubviewToFront(dayFilterView)
        view.bringSubviewToFront(mainViewButton)
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

    internal func toggleView() {
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
        // Hide status bar for fullscreen map experience
        setStatusBarHidden(true)

        // Add top padding to navigation bar to compensate for hidden status bar
        let statusBarHeight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        customNavigationBar.topPadding = statusBarHeight

        // Update map floating button constraint - position above add plan button (same as list mode)
        mapFloatingButtonBottomToPreviewConstraint?.isActive = false
        mapFloatingButtonBottomToSafeAreaConstraint?.isActive = false
        mapFloatingButtonBottomToAddPlanConstraint?.isActive = true

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

            // Update floating button icon to list - KEEP add plan button visible
            self.mapFloatingButton.updateIcon(TRPImageController().getImage(inFramework: "ic_list", inApp: nil))
            self.addPlanFloatingButton.isHidden = false  // Visible in both list and map mode

            self.view.layoutIfNeeded()
        }

        // Update day filter position (move up since savedPlansButton is hidden)
        updateDayFilterViewConstraints()

        // Initialize map if needed
        if map == nil {
            initializeMap()
        } else {
            refreshMap()
        }

        // Update POI preview cards and FAB positions
        updatePOIPreviewCards()
    }

    private func showListView() {
        // Show status bar for list view
        setStatusBarHidden(false)

        // Remove top padding from navigation bar
        customNavigationBar.topPadding = 0

        // Update map floating button constraint - position above add plan button
        mapFloatingButtonBottomToPreviewConstraint?.isActive = false
        mapFloatingButtonBottomToSafeAreaConstraint?.isActive = false
        mapFloatingButtonBottomToAddPlanConstraint?.isActive = true

        // Hide map, show list
        UIView.animate(withDuration: 0.3) {
            self.tableView.isHidden = false
            self.mapContainerView.isHidden = true
            self.poiPreviewContainerView.isHidden = true

            // Reset FAB positions to original
            self.addPlanButtonBottomConstraint?.constant = -24
            self.view.layoutIfNeeded()

            // Update floating button icon to map and show add plan button
            self.mapFloatingButton.updateIcon(TRPImageController().getImage(inFramework: "ic_map", inApp: nil))
            self.addPlanFloatingButton.isHidden = false
        }

        // Reset collection view state, focus state, and selected markers
        isCollectionViewExpanded = false
        isMarkerFocused = false
        selectedMarkerPoiIds.removeAll()
        updateMainViewButtonVisibility()

        // Restore saved plans button visibility
        updateSavedPlansButton()
    }

    internal func updatePOIPreviewCards() {
        // Get ordered items from ViewModel (uses unified order matching list view)
        mapDisplayItems = viewModel.getOrderedItemsForMap()

        // Update hasMultipleCities flag for Main View button
        hasMultipleCitiesOnSelectedDay = viewModel.hasMultipleCities()

        // Also update legacy currentTimelineItems for compatibility
        currentTimelineItems = []
        for (_, _, _, item) in mapDisplayItems {
            switch item {
            case .poi(let poi, _, _):
                currentTimelineItems.append(.poi(poi))
            case .activity(let segment):
                currentTimelineItems.append(.bookedActivity(segment))
            }
        }

        if mapDisplayItems.isEmpty {
            // Hide preview cards if no items
            poiPreviewBottomConstraint?.constant = -collectionViewHeight
            // Position add plan button at bottom, map button above it
            addPlanButtonBottomConstraint?.constant = -24
            mapFloatingButtonBottomToPreviewConstraint?.isActive = false
            mapFloatingButtonBottomToSafeAreaConstraint?.isActive = false
            mapFloatingButtonBottomToAddPlanConstraint?.isActive = true
        } else {
            // Start in expanded state (fully visible)
            isCollectionViewExpanded = true
            poiPreviewBottomConstraint?.constant = expandedOffset
            // Both FABs move up above the preview cards
            addPlanButtonBottomConstraint?.constant = expandedOffset - collectionViewHeight - 24
            // Position map button above add plan button
            mapFloatingButtonBottomToSafeAreaConstraint?.isActive = false
            mapFloatingButtonBottomToPreviewConstraint?.isActive = false
            mapFloatingButtonBottomToAddPlanConstraint?.isActive = true
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

        // Reset focus state when collapsing
        isMarkerFocused = false
        updateMainViewButtonVisibility()

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            // Slide collection view down to be half visible
            self.poiPreviewBottomConstraint?.constant = self.collapsedOffset
            // Move add plan button above visible collection view (60pt + 24pt spacing)
            self.addPlanButtonBottomConstraint?.constant = -84
            self.view.layoutIfNeeded()
        }
    }

    internal func toggleCollectionView() {
        if isCollectionViewExpanded {
            collapseCollectionView()
        } else {
            expandCollectionView()
            isMarkerFocused = true
            updateMainViewButtonVisibility()
        }
    }

    // MARK: - Public Methods

    public func reload() {
        // Clear IndexPath-based distances (table structure changes per day)
        // NOTE: routeCache is coordinate-based and preserved across reloads/day switches
        // It is only cleared in updateTimeline() when actual timeline data changes
        calculatedDistances.removeAll()
        dayFilterView.configure(with: viewModel.getAvailableDates(), selectedDay: viewModel.selectedDayIndex)

        // Update saved plans button visibility and count
        updateSavedPlansButton()

        tableView.reloadData()

        // Pre-calculate routes for itinerary segments with multiple steps
        calculateRoutesForItinerarySegments()

        // If map is showing, refresh it and update POI cards
        // This ensures map syncs with day changes after segment creation
        if isShowingMap {
            refreshMap()
            updatePOIPreviewCards()
        }
    }

    internal func updateSavedPlansButton() {
        let hasFavorites = viewModel.hasFavoriteItems()
        let isMapViewActive = !mapContainerView.isHidden
        savedPlansButton.isHidden = !hasFavorites || isMapViewActive

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

    // MARK: - Segment Route Pre-calculation

    /// Starts route calculations for itinerary segments with multiple steps
    internal func calculateRoutesForItinerarySegments() {
        let segments = viewModel.getItinerarySegmentsForRouteCalculation()

        for segmentData in segments {
            calculateRouteForSegment(locations: segmentData.locations)
        }
    }

    /// Calculates routes for a single segment and caches the results
    private func calculateRouteForSegment(locations: [TRPLocation]) {
        guard locations.count > 1 else { return }

        // Check if all routes are already cached
        var needsCalculation = false
        for i in 0..<(locations.count - 1) {
            let cacheKey = generateRouteCacheKey(from: locations[i], to: locations[i + 1])
            if routeCache[cacheKey] == nil {
                needsCalculation = true
                break
            }
        }

        // Skip if all routes already cached
        guard needsCalculation else { return }

        // Calculate route for all waypoints at once
        // Note: viewModel.calculateRoute completion is already dispatched to main thread
        viewModel.calculateRoute(for: locations) { [weak self] route, error in
            guard let self = self, let route = route else { return }

            // Cache each leg separately
            for (index, leg) in route.legs.enumerated() {
                if index < locations.count - 1 {
                    let cacheKey = self.generateRouteCacheKey(from: locations[index], to: locations[index + 1])
                    let readable = ReadableDistance.calculate(distance: Float(leg.distance), time: leg.expectedTravelTime)
                    self.routeCache[cacheKey] = (distance: readable.distance, time: readable.time)
                }
            }

            // After caching, update visible recommendation cells with new route data
            self.applyRouteCacheToVisibleCells()
        }
    }

    /// Applies calculated distances to visible recommendation cells
    /// Called after pre-calculation completes to update any cells that already have distance data
    internal func applyRouteCacheToVisibleCells() {
        for cell in tableView.visibleCells {
            guard let recCell = cell as? TRPTimelineRecommendationsCell,
                  let indexPath = tableView.indexPath(for: recCell) else { continue }

            // Apply any already-calculated distances directly (no re-configuration needed)
            if let distances = calculatedDistances[indexPath] {
                for (index, distanceData) in distances {
                    recCell.updateDistance(at: index, distance: distanceData.distance, time: distanceData.time)
                }
            }
        }
    }
}
