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

    /// Opens the add plan sheet as soon as the timeline is on screen. For a host whose own
    /// entry point is "add something to this day" rather than "look at this day", which would
    /// otherwise have to wait for the screen to load before it could ask.
    public var opensAddPlanWhenReady: Bool = false
    internal var map: TRPMapView?
    internal var hasLoadedInitialMapData: Bool = false
    /// Bumped on every route redraw so late completions from a previous day are dropped.
    internal var mapRouteGeneration: Int = 0

    // Cache for route calculations - keyed by route coordinates
    internal var routeCache: [String: TRPStepRouteInfo] = [:]

    internal var calculatedDistances: [IndexPath: [Int: TRPStepRouteInfo]] = [:]

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

    /// Conflict banner installed as `tableView.tableHeaderView`; visibility driven by `updateConflictWarningVisibility()`.
    internal lazy var conflictWarningView: TRPTimelineConflictWarningView = {
        let view = TRPTimelineConflictWarningView()
        view.onCloseTapped = { [weak self] in
            guard let self = self else { return }
            self.conflictWarningDismissedDayIndex = self.viewModel.selectedDayIndex
            self.updateConflictWarningVisibility()
        }
        return view
    }()

    /// Day index for which the user dismissed the conflict banner. Reset on timeline refresh.
    internal var conflictWarningDismissedDayIndex: Int?

    internal lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .grouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.separatorStyle = .none
        table.backgroundColor = .white
        table.showsVerticalScrollIndicator = false
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

    internal lazy var mapContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.isHidden = true
        return view
    }()

    internal lazy var mainViewButton: TRPMainViewButton = {
        let button = TRPMainViewButton()
        button.addTarget(self, action: #selector(mainViewButtonTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

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
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = .fast  // For custom paging
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()

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

    internal var hasMultipleCitiesOnSelectedDay: Bool = false

    internal var isShowingStepMarkersInMultiCity: Bool = false
    // Above this = show step markers; at/below = show city markers. Kept low (regional
    // zoom) so city markers only appear once you've zoomed well away from a city, and
    // step markers stay visible across the whole metro/city range.
    internal let multiCityZoomThreshold: CGFloat = 9.0

    internal var selectedMarkerPoiIds: Set<String> = []

    internal var stepBeingEdited: TRPTimelineStep?
    internal var segmentBeingEdited: TRPTimelineSegment?

    internal var isCollectionViewExpanded: Bool = false
    // 126pt card + 1pt breathing room top & bottom so the rounded corners/shadow aren't clipped.
    internal let collectionViewHeight: CGFloat = 128
    internal let collapsedOffset: CGFloat = 60   // 50% visible (60pt of 120pt)
    internal let expandedOffset: CGFloat = -16   // Fully visible with margin

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
        navigationController?.setNavigationBarHidden(true, animated: false)

        updateSavedPlansButton()

        if viewModel.showNoCityStateOnLoad {
            timelineItineraryViewModel(noCitiesAvailable: true)
        }

        // Deferred to next runloop so Lottie modal presentation doesn't race with this VC's own presentation.
        DispatchQueue.main.async { [weak self] in
            self?.viewModel.loadInitialTimelineIfNeeded()
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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

        // Bring these to front so they appear above the map
        view.bringSubviewToFront(customNavigationBar)
        view.bringSubviewToFront(savedPlansButton)
        view.bringSubviewToFront(dayFilterView)
        view.bringSubviewToFront(mainViewButton)
    }

    // MARK: - Actions

    @objc private func mapFloatingButtonTapped() {
        toggleView()
    }

    @objc private func addPlanFloatingButtonTapped() {
        showAddPlanFlow()
    }

    internal func toggleView() {
        isShowingMap.toggle()

        if isShowingMap {
            showMapView()
        } else {
            showListView()
        }
    }

    private func showMapView() {
        setStatusBarHidden(true)

        // Top padding compensates for the hidden status bar
        let statusBarHeight = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        customNavigationBar.topPadding = statusBarHeight

        mapFloatingButtonBottomToPreviewConstraint?.isActive = false
        mapFloatingButtonBottomToSafeAreaConstraint?.isActive = false
        mapFloatingButtonBottomToAddPlanConstraint?.isActive = true

        UIView.animate(withDuration: 0.3) {
            self.tableView.isHidden = true
            self.mapContainerView.isHidden = false
            self.poiPreviewContainerView.isHidden = false

            self.savedPlansButton.isHidden = true

            self.customNavigationBar.backgroundColor = .clear
            self.dayFilterView.backgroundColor = .clear

            self.mapFloatingButton.updateIcon(TRPImageController().getImage(inFramework: "ic_list", inApp: nil))
            self.addPlanFloatingButton.isHidden = false  // Visible in both list and map mode

            self.view.layoutIfNeeded()
        }

        updateDayFilterViewConstraints()

        if map == nil {
            initializeMap()
        } else {
            refreshMap()
        }

        updatePOIPreviewCards()
    }

    private func showListView() {
        setStatusBarHidden(false)

        customNavigationBar.topPadding = 0

        mapFloatingButtonBottomToPreviewConstraint?.isActive = false
        mapFloatingButtonBottomToSafeAreaConstraint?.isActive = false
        mapFloatingButtonBottomToAddPlanConstraint?.isActive = true

        UIView.animate(withDuration: 0.3) {
            self.tableView.isHidden = false
            self.mapContainerView.isHidden = true
            self.poiPreviewContainerView.isHidden = true

            self.addPlanButtonBottomConstraint?.constant = -24
            self.view.layoutIfNeeded()

            self.mapFloatingButton.updateIcon(TRPImageController().getImage(inFramework: "ic_map", inApp: nil))
            self.addPlanFloatingButton.isHidden = false
        }

        isCollectionViewExpanded = false
        selectedMarkerPoiIds.removeAll()
        updateMainViewButtonVisibility()

        updateSavedPlansButton()
    }

    internal func updatePOIPreviewCards() {
        mapDisplayItems = viewModel.getOrderedItemsForMap()

        hasMultipleCitiesOnSelectedDay = viewModel.hasMultipleCities()

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
            poiPreviewBottomConstraint?.constant = -collectionViewHeight
            addPlanButtonBottomConstraint?.constant = -24
            mapFloatingButtonBottomToPreviewConstraint?.isActive = false
            mapFloatingButtonBottomToSafeAreaConstraint?.isActive = false
            mapFloatingButtonBottomToAddPlanConstraint?.isActive = true
        } else {
            isCollectionViewExpanded = true
            poiPreviewBottomConstraint?.constant = expandedOffset
            addPlanButtonBottomConstraint?.constant = expandedOffset - collectionViewHeight - 24
            mapFloatingButtonBottomToSafeAreaConstraint?.isActive = false
            mapFloatingButtonBottomToPreviewConstraint?.isActive = false
            mapFloatingButtonBottomToAddPlanConstraint?.isActive = true
        }

        poiPreviewCollectionView.reloadData()
        // Re-sync after a refresh/day change: the map reset to overview (loadMapData cleared the zoom-into-city state), so the button should hide.
        updateMainViewButtonVisibility()
    }

    // MARK: - Collection View Expand/Collapse

    internal func expandCollectionView(completion: (() -> Void)? = nil) {
        guard !isCollectionViewExpanded else {
            completion?()
            return
        }
        isCollectionViewExpanded = true
        updateMainViewButtonVisibility()

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            self.poiPreviewBottomConstraint?.constant = self.expandedOffset
            self.addPlanButtonBottomConstraint?.constant = self.expandedOffset - self.collectionViewHeight - 24
            self.view.layoutIfNeeded()
        }, completion: { _ in
            completion?()
        })
    }

    internal func collapseCollectionView() {
        guard isCollectionViewExpanded else { return }
        isCollectionViewExpanded = false
        updateMainViewButtonVisibility()

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.poiPreviewBottomConstraint?.constant = self.collapsedOffset
            // 60pt visible + 24pt spacing
            self.addPlanButtonBottomConstraint?.constant = -84
            self.view.layoutIfNeeded()
        }
    }

    internal func toggleCollectionView() {
        if isCollectionViewExpanded {
            collapseCollectionView()
        } else {
            expandCollectionView()
        }
    }

    // MARK: - Public Methods

    public func reload() {
        // routeCache is coordinate-based and preserved across reloads; only calculatedDistances is per-day.
        calculatedDistances.removeAll()
        dayFilterView.configure(with: viewModel.getAvailableDates(), selectedDay: viewModel.selectedDayIndex)

        updateSavedPlansButton()

        tableView.reloadData()
        updateConflictWarningVisibility()

        if viewModel.usesFlatTimeline {
            requestFlatRoutes()
        } else {
            calculateRoutesForItinerarySegments()
        }

        if isShowingMap {
            refreshMap()
            updatePOIPreviewCards()
        }
    }

    /// Flat timeline: fetches legs for the day's chains not cached yet; every arrival re-renders
    /// the list and, when the map is up, its route.
    internal func requestFlatRoutes() {
        viewModel.requestMissingFlatRoutes { [weak self] in
            guard let self = self else { return }
            self.tableView.reloadData()
            if self.isShowingMap {
                self.drawRoutesForSelectedDay()
            }
        }
    }

    /// Installs the conflict banner as `tableView.tableHeaderView` when the day has undismissed conflicts.
    internal func updateConflictWarningVisibility() {
        let dayIndex = viewModel.selectedDayIndex
        let hasConflict = viewModel.hasConflictOnSelectedDay()
        let dismissedForThisDay = (conflictWarningDismissedDayIndex == dayIndex)
        let shouldShow = hasConflict && !dismissedForThisDay

        guard shouldShow else {
            tableView.tableHeaderView = nil
            return
        }

        let wasAlreadyInstalled = (tableView.tableHeaderView != nil)

        // tableHeaderView needs an explicit frame — Auto Layout doesn't size it for us.
        view.layoutIfNeeded()
        let banner = conflictWarningView
        let width = tableView.bounds.width
        guard width > 0 else { return }

        let target = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        let height = banner.systemLayoutSizeFitting(
            target,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        banner.frame = CGRect(x: 0, y: 0, width: width, height: height)
        tableView.tableHeaderView = banner

        // On first install, pull the table to top so the banner isn't hidden behind the day filter.
        if !wasAlreadyInstalled {
            tableView.setContentOffset(.zero, animated: false)
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

        updateDayFilterViewConstraints()
    }

    public func updateTimeline(_ timeline: TRPTimeline) {
        routeCache.removeAll()
        calculatedDistances.removeAll()
        // Reset banner dismissal — fresh data may surface conflicts dismissed for a prior state of the day.
        conflictWarningDismissedDayIndex = nil
        viewModel.updateTimeline(timeline)
        reload()
    }

    public func setNavigationTitle(_ title: String) {
        customNavigationBar.setTitle(title)
    }

    public func getNavigationTitle() -> String? {
        return customNavigationBar.getTitle()
    }

    // MARK: - Segment Route Pre-calculation

    internal func calculateRoutesForItinerarySegments() {
        let segments = viewModel.getItinerarySegmentsForRouteCalculation()

        for segmentData in segments {
            calculateRouteForSegment(locations: segmentData.locations)
        }
    }

    private func calculateRouteForSegment(locations: [TRPLocation]) {
        guard locations.count > 1 else { return }

        var needsCalculation = false
        for i in 0..<(locations.count - 1) {
            let cacheKey = generateRouteCacheKey(from: locations[i], to: locations[i + 1])
            if routeCache[cacheKey] == nil {
                needsCalculation = true
                break
            }
        }

        guard needsCalculation else { return }

        viewModel.calculateStepRoutes(for: locations) { [weak self] routes in
            guard let self = self, let routes = routes else { return }

            for (index, routeInfo) in routes.enumerated() where index < locations.count - 1 {
                let cacheKey = self.generateRouteCacheKey(from: locations[index], to: locations[index + 1])
                self.routeCache[cacheKey] = routeInfo
            }

            self.applyRouteCacheToVisibleCells()
        }
    }

    internal func applyRouteCacheToVisibleCells() {
        for cell in tableView.visibleCells {
            guard let recCell = cell as? TRPTimelineRecommendationsCell,
                  let indexPath = tableView.indexPath(for: recCell) else { continue }

            if let distances = calculatedDistances[indexPath] {
                for (index, routeInfo) in distances {
                    recCell.updateDistance(at: index, routeInfo: routeInfo)
                }
            }
        }
    }
}
