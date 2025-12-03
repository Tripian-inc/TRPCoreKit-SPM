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
    func timelineItineraryThumbsUpPressed(_ viewController: TRPTimelineItineraryVC, step: TRPTimelineStep)
    func timelineItineraryThumbsDownPressed(_ viewController: TRPTimelineItineraryVC, step: TRPTimelineStep)
}

@objc(SPMTRPTimelineItineraryVC)
public class TRPTimelineItineraryVC: TRPBaseUIViewController {
    
    internal var viewModel: TRPTimelineItineraryViewModel!
    public weak var delegate: TRPTimelineItineraryVCDelegate?
    internal var map: TRPMapView?
    internal var callOutController: TRPCallOutController?
    internal var hasLoadedInitialMapData: Bool = false
    
    // MARK: - UI Components
    private lazy var customNavigationBar: TRPTimelineCustomNavigationBar = {
        let bar = TRPTimelineCustomNavigationBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.delegate = self
        return bar
    }()
    
    private lazy var tabView: TRPTimelineTabView = {
        let view = TRPTimelineTabView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
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
        return table
    }()
    
    internal lazy var mapContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.isHidden = true
        return view
    }()
    
    // MARK: - Initialization
    public init(viewModel: TRPTimelineItineraryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        // Hide the default navigation bar
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Ensure default navigation bar stays hidden
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    public override func setupViews() {
        super.setupViews()
        setupCustomNavigationBar()
        setupTabView()
        setupDayFilterView()
        setupTableView()
        setupMapView()
        setupCallOutController()
        registerCells()
        
        // Load initial data
        reload()
    }
    
    // MARK: - Setup Methods
    private func setupCustomNavigationBar() {
        view.addSubview(customNavigationBar)
        
        NSLayoutConstraint.activate([
            customNavigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            customNavigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customNavigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customNavigationBar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupTabView() {
        view.addSubview(tabView)
        
        NSLayoutConstraint.activate([
            tabView.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor),
            tabView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabView.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Configure tabs
        let tabs = [
            TRPTimelineTabItem(id: "list", title: "List"),
            TRPTimelineTabItem(id: "map", title: "Map")
        ]
        tabView.configure(with: tabs, selectedIndex: 0)
    }
    
    private func setupDayFilterView() {
        view.addSubview(dayFilterView)
        
        NSLayoutConstraint.activate([
            dayFilterView.topAnchor.constraint(equalTo: tabView.bottomAnchor, constant: 12),
            dayFilterView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dayFilterView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dayFilterView.heightAnchor.constraint(equalToConstant: 50)
        ])
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
        
        NSLayoutConstraint.activate([
            mapContainerView.topAnchor.constraint(equalTo: dayFilterView.bottomAnchor, constant: 8),
            mapContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Map will be initialized when tab is selected
        mapContainerView.backgroundColor = .white
    }
    
    private func setupCallOutController() {
        let addImage = TRPImageController().getImage(inFramework: "add_btn", inApp: TRPAppearanceSettings.Common.addButtonImage)
        let removeImage = TRPImageController().getImage(inFramework: "remove_btn", inApp: TRPAppearanceSettings.Common.removeButtonImage)
        let navImage = TRPImageController().getImage(inFramework: "navigation_btn", inApp: TRPAppearanceSettings.Common.navigationButtonImage)
        
        let bottomSpace: CGFloat = 62
        
        callOutController = TRPCallOutController(inView: self.view,
                                                 addBtnImage: addImage,
                                                 removeBtnImage: removeImage,
                                                 navigationBtnImage: navImage,
                                                 bottomSpace: bottomSpace)
        
        callOutController?.cellPressed = { [weak self] id, inRoute in
            guard let self = self else { return }
            self.callOutController?.hidden()
            
            // Get POI and show detail
            if let poi = self.viewModel.getPoi(byId: id) {
                // For now, we'll just log. You can extend the delegate to handle POI details
                // print("POI clicked: \(poi.name)")
            }
        }
        
        callOutController?.action = { [weak self] status, id in
            guard let self = self else { return }
            self.callOutController?.hidden()
            
            // Handle add/remove actions
            // This can be extended based on your requirements
        }
    }
    
    private func registerCells() {
        tableView.register(TRPTimelineBookedActivityCell.self, forCellReuseIdentifier: TRPTimelineBookedActivityCell.reuseIdentifier)
        tableView.register(TRPTimelineRecommendationsCell.self, forCellReuseIdentifier: TRPTimelineRecommendationsCell.reuseIdentifier)
        tableView.register(TRPTimelineSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: TRPTimelineSectionHeaderView.reuseIdentifier)
        tableView.register(TRPTimelineSectionFooterView.self, forHeaderFooterViewReuseIdentifier: TRPTimelineSectionFooterView.reuseIdentifier)
    }
    
    // MARK: - Actions
    private func handleTabChange(tabId: String, index: Int) {
        switch tabId {
        case "list":
            tableView.isHidden = false
            mapContainerView.isHidden = true
            dayFilterView.isHidden = false
            
        case "calendar":
            // Calendar view - TODO: Implement
            tableView.isHidden = true
            mapContainerView.isHidden = true
            dayFilterView.isHidden = false
            
        case "map":
            tableView.isHidden = true
            mapContainerView.isHidden = false
            dayFilterView.isHidden = false
            
            // Initialize map if not already done, or refresh if already initialized
            if map == nil {
                initializeMap()
                // Data will be loaded automatically when map finishes loading
            } else {
                // Map already exists, just refresh the data
                refreshMap()
            }
            
        default:
            break
        }
    }
    
    // MARK: - Public Methods
    public func reload() {
        dayFilterView.configure(with: viewModel.getDays(), selectedDay: viewModel.selectedDayIndex)
        tableView.reloadData()
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
    
    /// Configure custom tabs
    /// - Parameters:
    ///   - tabs: Array of tab items with unique IDs and titles
    ///   - selectedIndex: Initially selected tab index (default: 0)
    public func configureTabs(_ tabs: [TRPTimelineTabItem], selectedIndex: Int = 0) {
        tabView.configure(with: tabs, selectedIndex: selectedIndex)
    }
    
    /// Switch to a specific tab by index
    /// - Parameters:
    ///   - index: Tab index to select
    ///   - animated: Whether to animate the transition (default: true)
    public func selectTab(at index: Int, animated: Bool = true) {
        tabView.selectTab(at: index, animated: animated)
    }
    
    /// Switch to a specific tab by ID
    /// - Parameters:
    ///   - id: Tab ID to select
    ///   - animated: Whether to animate the transition (default: true)
    public func selectTab(byId id: String, animated: Bool = true) {
        tabView.selectTab(byId: id, animated: animated)
    }
    
    /// Get the currently selected tab index
    public func getSelectedTabIndex() -> Int {
        return tabView.getSelectedIndex()
    }
    
    /// Get the currently selected tab ID
    public func getSelectedTabId() -> String? {
        return tabView.getSelectedTabId()
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
        
        switch cellType {
        case .bookedActivity(let segment):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TRPTimelineBookedActivityCell.reuseIdentifier, for: indexPath) as? TRPTimelineBookedActivityCell else {
                return UITableViewCell()
            }
            cell.configure(with: segment)
            cell.delegate = self
            return cell
            
        case .recommendations(let steps):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TRPTimelineRecommendationsCell.reuseIdentifier, for: indexPath) as? TRPTimelineRecommendationsCell else {
                return UITableViewCell()
            }
            cell.configure(with: steps)
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
        // Don't show footer after the last section
        guard section < viewModel.numberOfSections() - 1 else {
            return 0
        }
        
        return 60
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
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
        case .bookedActivity(let segment):
            delegate?.timelineItineraryDidSelectBookedActivity(self, segment: segment)
            
        case .recommendations:
            // Recommendations cell handles selection internally
            break
        }
    }
}

// MARK: - TRPTimelineDayFilterViewDelegate
extension TRPTimelineItineraryVC: TRPTimelineDayFilterViewDelegate {
    
    public func dayFilterViewDidSelectDay(_ view: TRPTimelineDayFilterView, dayIndex: Int) {
        viewModel.selectDay(at: dayIndex)
        tableView.reloadData()
        
        // Refresh map if it's visible and initialized
        if !mapContainerView.isHidden {
            if let map = map {
                // Map is already initialized, just refresh the data
                refreshMap()
            } else {
                // Map not initialized yet, initialize it now
                initializeMap()
            }
        }
    }
    
    public func dayFilterViewDidTapFilter(_ view: TRPTimelineDayFilterView) {
        // Handle filter button tap
    }
}

// MARK: - TRPTimelineBookedActivityCellDelegate
extension TRPTimelineItineraryVC: TRPTimelineBookedActivityCellDelegate {
    
    func bookedActivityCellDidTapMoreOptions(_ cell: TRPTimelineBookedActivityCell) {
        // Handle more options
    }
}

// MARK: - TRPTimelineSectionHeaderViewDelegate
extension TRPTimelineItineraryVC: TRPTimelineSectionHeaderViewDelegate {
    
    func sectionHeaderViewDidTapFilter(_ view: TRPTimelineSectionHeaderView) {
        delegate?.timelineItineraryFilterPressed(self)
    }
    
    func sectionHeaderViewDidTapAddPlans(_ view: TRPTimelineSectionHeaderView) {
        delegate?.timelineItineraryAddPlansPressed(self)
    }
}

// MARK: - TRPTimelineSectionFooterViewDelegate
extension TRPTimelineItineraryVC: TRPTimelineSectionFooterViewDelegate {
    
    func sectionFooterViewDidTapAdd(_ view: TRPTimelineSectionFooterView, section: Int) {
        delegate?.timelineItineraryAddButtonPressed(self, atSectionIndex: section)
    }
}

// MARK: - TRPTimelineTabViewDelegate
extension TRPTimelineItineraryVC: TRPTimelineTabViewDelegate {
    
    func timelineTabView(_ view: TRPTimelineTabView, didSelectTabAtIndex index: Int, tabId: String) {
        handleTabChange(tabId: tabId, index: index)
    }
}

// MARK: - TRPTimelineRecommendationsCellDelegate
extension TRPTimelineItineraryVC: TRPTimelineRecommendationsCellDelegate {
    
    func recommendationsCellDidTapEdit(_ cell: TRPTimelineRecommendationsCell) {
        // Handle edit recommendations
    }
    
    func recommendationsCellDidTapToggle(_ cell: TRPTimelineRecommendationsCell, isExpanded: Bool) {
        // Handle expand/collapse - table will auto-adjust
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    func recommendationsCellDidSelectStep(_ cell: TRPTimelineRecommendationsCell, step: TRPTimelineStep) {
        delegate?.timelineItineraryDidSelectStep(self, step: step)
    }
    
    func recommendationsCellDidTapThumbsUp(_ cell: TRPTimelineRecommendationsCell, step: TRPTimelineStep) {
        delegate?.timelineItineraryThumbsUpPressed(self, step: step)
    }
    
    func recommendationsCellDidTapThumbsDown(_ cell: TRPTimelineRecommendationsCell, step: TRPTimelineStep) {
        delegate?.timelineItineraryThumbsDownPressed(self, step: step)
    }
    
    func recommendationsCellNeedsRouteCalculation(_ cell: TRPTimelineRecommendationsCell, from: TRPLocation, to: TRPLocation, index: Int) {
        // Calculate route between two POIs
        viewModel.calculateRoute(for: [from, to]) { [weak self, weak cell] route, error in
            guard let self = self, let cell = cell else { return }
            
            if let route = route {
                // Convert distance and time to readable format
                let readable = ReadableDistance.calculate(distance: Float(route.distance), time: route.expectedTravelTime)
                
                DispatchQueue.main.async {
                    cell.updateDistance(at: index, distance: readable.distance, time: readable.time)
                }
            } else {
                // If route calculation fails, show a placeholder
                DispatchQueue.main.async {
                    cell.updateDistance(at: index, distance: 0, time: 0)
                }
            }
        }
    }
}

// MARK: - TRPTimelineCustomNavigationBarDelegate
extension TRPTimelineItineraryVC: TRPTimelineCustomNavigationBarDelegate {
    
    func customNavigationBarDidTapBack(_ navigationBar: TRPTimelineCustomNavigationBar) {
        // Handle back button tap
        if let navigationController = navigationController {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
}

