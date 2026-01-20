//
//  TRPTimelineItineraryVC+CellDelegates.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - Cell delegate implementations extracted from main VC
//

import UIKit
import TRPFoundationKit

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
        // Store the segment being edited
        segmentBeingEdited = segment

        // Get current start and end times from segment
        let timeRangeVC = TRPTimeRangeSelectionViewController()
        timeRangeVC.delegate = self

        // Parse segment times and set as initial values
        if let startDateStr = segment.startDate,
           let endDateStr = segment.endDate,
           let startDate = parseSegmentDateTime(startDateStr),
           let endDate = parseSegmentDateTime(endDateStr) {
            timeRangeVC.setInitialTimes(from: startDate, to: endDate)
        }

        // Present the time selection view controller
        timeRangeVC.show(from: self)
    }

    /// Parses segment datetime string to Date without timezone conversion
    /// Supports formats: "yyyy-MM-dd HH:mm:ss" and "yyyy-MM-dd HH:mm"
    /// Uses current timezone to avoid UTC conversion issues
    internal func parseSegmentDateTime(_ dateTimeString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current

        // Try format with seconds first (server format)
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = dateFormatter.date(from: dateTimeString) {
            return date
        }

        // Try format without seconds
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return dateFormatter.date(from: dateTimeString)
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
    internal func parseStepDateTime(_ dateTimeString: String) -> Date? {
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

    func recommendationsCellNeedsRouteCalculation(_ cell: TRPTimelineRecommendationsCell, locations: [TRPLocation], cellIndexPath: IndexPath) {
        guard locations.count > 1 else { return }

        // Check if all routes are already cached
        var allCached = true
        var cachedResults: [(index: Int, data: (distance: Float, time: Int))] = []

        for i in 0..<(locations.count - 1) {
            let cacheKey = generateRouteCacheKey(from: locations[i], to: locations[i + 1])
            if let cachedResult = routeCache[cacheKey] {
                cachedResults.append((index: i, data: cachedResult))
            } else {
                allCached = false
                break
            }
        }

        // If all cached, apply immediately
        if allCached {
            if calculatedDistances[cellIndexPath] == nil {
                calculatedDistances[cellIndexPath] = [:]
            }
            for result in cachedResults {
                calculatedDistances[cellIndexPath]?[result.index] = result.data
                cell.updateDistance(at: result.index, distance: result.data.distance, time: result.data.time)
            }
            return
        }

        // Calculate route for all waypoints at once
        viewModel.calculateRoute(for: locations) { [weak self] route, error in
            guard let self = self else { return }

            DispatchQueue.main.async {
                guard let route = route else { return }

                // Initialize distances dictionary for this cell
                if self.calculatedDistances[cellIndexPath] == nil {
                    self.calculatedDistances[cellIndexPath] = [:]
                }

                // Process each leg - legs[i] corresponds to route from locations[i] to locations[i+1]
                for (index, leg) in route.legs.enumerated() {
                    let readable = ReadableDistance.calculate(distance: Float(leg.distance), time: leg.expectedTravelTime)
                    let distanceData = (distance: readable.distance, time: readable.time)

                    // Cache each leg separately
                    if index < locations.count - 1 {
                        let cacheKey = self.generateRouteCacheKey(from: locations[index], to: locations[index + 1])
                        self.routeCache[cacheKey] = distanceData
                    }

                    // Store and update cell
                    self.calculatedDistances[cellIndexPath]?[index] = distanceData

                    // Update the cell if it's still visible
                    if let currentCell = self.tableView.cellForRow(at: cellIndexPath) as? TRPTimelineRecommendationsCell {
                        currentCell.updateDistance(at: index, distance: distanceData.distance, time: distanceData.time)
                    }
                }
            }
        }
    }

    internal func generateRouteCacheKey(from: TRPLocation, to: TRPLocation) -> String {
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

// MARK: - TRPTimelineSavedPlansButtonDelegate

extension TRPTimelineItineraryVC: TRPTimelineSavedPlansButtonDelegate {

    func savedPlansButtonDidTap(_ button: TRPTimelineSavedPlansButton) {
        // Open saved/favorite plans list
        showSavedPlans()
    }

    internal func showSavedPlans() {
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
            self.refreshTimelineAfterSegmentCreation()
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
        // Check if we're editing a segment (manual POI)
        if let segment = segmentBeingEdited {
            // fromTime and toTime are already in "HH:mm" format from TRPTimeRangeSelectionViewController
            viewModel.updateSegmentTime(segment: segment, startTime: fromTime, endTime: toTime) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success:
                    // Clear the segment being edited
                    self.segmentBeingEdited = nil

                case .failure:
                    // Error is already handled by ViewModel (shows error via delegate)
                    self.segmentBeingEdited = nil
                }
            }
            return
        }

        // Otherwise, we're editing a step (recommendation)
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
