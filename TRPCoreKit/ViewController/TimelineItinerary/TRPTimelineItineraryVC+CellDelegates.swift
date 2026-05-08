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
        // Cancel any pending route calculations from the previous day
        viewModel.cancelActiveRouteCalculations()

        // Update ViewModel to the new day
        viewModel.selectDay(at: dayIndex)

        // Use the same reload flow as initial load to ensure routes are calculated
        reload()

        // Scroll table view to top after reload. When the conflict banner is
        // installed as `tableHeaderView`, `scrollToRow(0, 0, .top)` would push
        // the first row to the top — hiding the banner. Use absolute zero
        // offset so the banner stays visible at the top of the viewport.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.tableView.tableHeaderView != nil {
                self.tableView.setContentOffset(.zero, animated: true)
            } else if self.viewModel.numberOfSections() > 0 && self.viewModel.numberOfRows(in: 0) > 0 {
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

    func bookedActivityCellDidTapCell(_ cell: TRPTimelineBookedActivityCell, segment: TRPTimelineSegment) {
        // Booked activity → host opens booking detail (not activity detail)
        guard let bookingId = segment.additionalData?.bookingId else { return }
        TRPCoreKit.shared.delegate?.trpCoreKitDidRequestBookingDetail(bookingId: bookingId)
    }
}

// MARK: - TRPTimelineReservedActivityCellDelegate

extension TRPTimelineItineraryVC: TRPTimelineReservedActivityCellDelegate {

    func reservedActivityCellDidTapReservation(_ cell: TRPTimelineReservedActivityCell, segment: TRPTimelineSegment) {
        // Notify delegate about activity reservation request
        guard let activityId = segment.additionalData?.activityId else { return }
        let cleanedId = activityId.cleanedAsActivityId()
        let isFlexible = segment.additionalData?.isFlexible == true
        let preferred = segment.additionalData?.startDatetime ?? segment.startDate
        let reservationDate = resolveReservationDate(preferred: preferred, isFlexible: isFlexible)
        TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityReservation(activityId: cleanedId, date: reservationDate)
    }

    func reservedActivityCellDidTapRemove(_ cell: TRPTimelineReservedActivityCell, segment: TRPTimelineSegment) {
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

    func reservedActivityCellDidTapChangeTime(_ cell: TRPTimelineReservedActivityCell, segment: TRPTimelineSegment) {
        // Create AddPlanData with timeline info for edit mode
        var planData = AddPlanData()
        planData.tripHash = viewModel.getTripHash()
        planData.availableDays = viewModel.getDayDates()
        planData.selectedCity = segment.city
        planData.travelers = segment.adults

        // Set selected day from current segment's date
        if let startDateStr = segment.startDate,
           let date = parseSegmentDateTime(startDateStr) {
            planData.selectedDay = date
        }

        // Find segment index for update API
        planData.segmentIndex = viewModel.getSegmentIndex(for: segment)

        // Create time selection VC in edit mode
        let timeSelectionVC = AddPlanTimeSelectionVC(segment: segment, planData: planData)

        // Set callback for segment update — sheet is already dismissed at this point,
        // so show the bottom sheet loader on the timeline screen during refresh.
        timeSelectionVC.onSegmentUpdated = { [weak self] in
            guard let self = self else { return }
            let text = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.changingTime)
            self.viewModel(showLottie: .bottomSheet, textMode: .single(text))
            self.viewModel.refreshTimeline()
        }

        // Present as bottom sheet
        presentVCWithDynamicHeight(timeSelectionVC, prefersGrabberVisible: true, isDimmed: true)
    }

    func reservedActivityCellDidTapCell(_ cell: TRPTimelineReservedActivityCell, segment: TRPTimelineSegment) {
        // Open activity detail
        guard let activityId = segment.additionalData?.activityId else { return }
        let cleanedId = activityId.cleanedAsActivityId()
        TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityDetail(activityId: cleanedId)
    }
}

// MARK: - TRPTimelineFlexibleActivityCellDelegate

extension TRPTimelineItineraryVC: TRPTimelineFlexibleActivityCellDelegate {

    func flexibleActivityCellDidTapReservation(_ cell: TRPTimelineFlexibleActivityCell, segment: TRPTimelineSegment) {
        guard let activityId = segment.additionalData?.activityId else { return }
        let cleanedId = activityId.cleanedAsActivityId()
        // Flex cell → time always pinned to 00:00 by the resolver.
        let preferred = segment.additionalData?.startDatetime ?? segment.startDate
        let reservationDate = resolveReservationDate(preferred: preferred, isFlexible: true)
        TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityReservation(activityId: cleanedId, date: reservationDate)
    }

    func flexibleActivityCellDidTapRemove(_ cell: TRPTimelineFlexibleActivityCell, segment: TRPTimelineSegment) {
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

    func flexibleActivityCellDidTapCell(_ cell: TRPTimelineFlexibleActivityCell, segment: TRPTimelineSegment) {
        guard let activityId = segment.additionalData?.activityId else { return }
        let cleanedId = activityId.cleanedAsActivityId()
        TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityDetail(activityId: cleanedId)
    }
}

// MARK: - TRPTimelineActivityStepCellDelegate

extension TRPTimelineItineraryVC: TRPTimelineActivityStepCellDelegate {

    func activityStepCellDidTapMoreOptions(_ cell: TRPTimelineActivityStepCell) {
        // Handle more options for activity steps
    }

    func activityStepCellDidTapReservation(_ cell: TRPTimelineActivityStepCell, step: TRPTimelineStep) {
        // Notify delegate about activity reservation request
        guard let poi = step.poi else { return }
        let activityId = extractActivityId(from: poi)
        let reservationDate = resolveReservationDate(preferred: step.startDateTimes)
        TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityReservation(activityId: activityId, date: reservationDate)
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

    /// Reservation date resolver. The returned Date carries both day and start time:
    /// flexible activities are always pinned to 00:00; otherwise the time component
    /// comes from the source datetime. Falls back to the timeline's currently
    /// selected day at 00:00 when no source datetime is available.
    ///
    /// All parsing is done in UTC to match the rest of the SDK: server datetime
    /// strings are wall-clock UTC, `getDayDates()` produces UTC days, and
    /// `getDateWithZeroHour(forLocal: false)` zeroes the hour in UTC. Parsing as
    /// local would shift the time by the device's UTC offset (e.g. "10:00" in
    /// Istanbul +3 would become "07:00 UTC", which is what the host then sees).
    internal func resolveReservationDate(preferred: String?, isFlexible: Bool = false) -> Date {
        let parsedSource = preferred.flatMap(parseSegmentDateTime)

        if !isFlexible, let parsed = parsedSource {
            return parsed
        }

        let baseDay: Date
        if let parsed = parsedSource {
            baseDay = parsed
        } else {
            let days = viewModel.getDayDates()
            let index = viewModel.selectedDayIndex
            if index >= 0, index < days.count {
                baseDay = days[index]
            } else {
                baseDay = days.first ?? Date()
            }
        }
        // Pin to 00:00 UTC of the resolved day (flexible path or no-source path).
        return baseDay.getDateWithZeroHour(forLocal: false)
    }

    /// Parses segment/step datetime strings using the project's `String.toDate`
    /// extension which defaults to UTC — server times are stored as wall-clock UTC,
    /// so this preserves the literal hour the host expects. Supports formats with
    /// and without seconds.
    internal func parseSegmentDateTime(_ dateTimeString: String) -> Date? {
        return dateTimeString.toDate(format: "yyyy-MM-dd HH:mm:ss")
            ?? dateTimeString.toDate(format: "yyyy-MM-dd HH:mm")
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
        guard let poi = step.poi else { return }

        // Activity step - call trpCoreKitDidRequestActivityDetail
        if step.stepType == "activity" {
            let activityId = extractActivityId(from: poi)
            TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityDetail(activityId: activityId)
            return
        }

        // Normal POI step - open POI detail view controller
        let viewModel = TimelinePoiDetailViewModel(poi: poi)
        let detailVC = TimelinePoiDetailViewController(viewModel: viewModel)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func recommendationsCellDidTapChangeTime(_ cell: TRPTimelineRecommendationsCell, step: TRPTimelineStep) {
        // Check if this is an activity step
        if step.stepType == "activity" {
            // Activity step - use AddPlanTimeSelectionVC with availability API
            openActivityTimeSelection(for: step, cell: cell)
        } else {
            // Regular POI step - use time range picker
            openTimeRangeSelection(for: step)
        }
    }

    /// Opens AddPlanTimeSelectionVC for activity steps (with availability API)
    private func openActivityTimeSelection(for step: TRPTimelineStep, cell: TRPTimelineRecommendationsCell) {
        // Create AddPlanData with timeline info for step edit mode
        var planData = AddPlanData()
        planData.tripHash = viewModel.getTripHash()
        planData.availableDays = viewModel.getDayDates()
        planData.travelers = 1 // Default, can be updated if needed

        // Set selected city from step's POI
        if let poi = step.poi {
            planData.selectedCity = viewModel.getCities().first { $0.id == poi.cityId }
        }

        // Set selected day from current step's date
        if let startDateTimes = step.startDateTimes,
           let date = parseStepDateTime(startDateTimes) {
            planData.selectedDay = date
        }

        // Create time selection VC in step edit mode
        let timeSelectionVC = AddPlanTimeSelectionVC(step: step, planData: planData)

        // Set callback for step update — sheet is already dismissed at this point,
        // so show the bottom sheet loader on the timeline screen during refresh.
        timeSelectionVC.onStepUpdated = { [weak self] in
            guard let self = self else { return }
            let text = LoadingLocalizationKeys.localized(LoadingLocalizationKeys.changingTime)
            self.viewModel(showLottie: .bottomSheet, textMode: .single(text))
            self.viewModel.refreshTimeline()
        }

        // Present as bottom sheet
        presentVCWithDynamicHeight(timeSelectionVC, prefersGrabberVisible: true, isDimmed: true)
    }

    /// Opens TRPTimeRangeSelectionViewController for regular POI steps
    private func openTimeRangeSelection(for step: TRPTimelineStep) {
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
            title: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.removeStepTitle),
            message: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.removeStepMessage),
            confirmTitle: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.remove),
            btnConfirmAction: { [weak self] in
                self?.viewModel.removeStep(step)
            }
        )
    }

    func recommendationsCellDidTapReservation(_ cell: TRPTimelineRecommendationsCell, step: TRPTimelineStep) {
        // Handle reservation tap for activity steps - open activity reservation
        guard let poi = step.poi else { return }
        let activityId = extractActivityId(from: poi)
        let reservationDate = resolveReservationDate(preferred: step.startDateTimes)
        TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityReservation(activityId: activityId, date: reservationDate)
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
        // Note: viewModel.calculateRoute completion is already dispatched to main thread
        viewModel.calculateRoute(for: locations) { [weak self] route, error in
            guard let self = self, let route = route else { return }

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

                // Store calculated distance
                self.calculatedDistances[cellIndexPath]?[index] = distanceData
            }

            // Update the cell - try direct update first, fallback to reload
            if let currentCell = self.tableView.cellForRow(at: cellIndexPath) as? TRPTimelineRecommendationsCell {
                // Cell is visible, update distances directly
                if let distances = self.calculatedDistances[cellIndexPath] {
                    for (index, distanceData) in distances {
                        currentCell.updateDistance(at: index, distance: distanceData.distance, time: distanceData.time)
                    }
                }
            } else {
                // Cell is not currently visible or couldn't be found - reload the row
                // so it picks up cached distances when it becomes visible
                if cellIndexPath.section < self.tableView.numberOfSections,
                   cellIndexPath.row < self.tableView.numberOfRows(inSection: cellIndexPath.section) {
                    self.tableView.reloadRows(at: [cellIndexPath], with: .none)
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
        // If map view is showing, switch back to list view instead of closing SDK
        if isShowingMap {
            toggleView()
            return
        }

        // Close SDK when back button is tapped from list view
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

        // Saved Plans now mirrors the Activity Listing flow: it stays open after a
        // successful add, the time-selection sheet's own Lottie loader covers the
        // create + GetTimeline regeneration window, and only the timeline behind us
        // needs a silent refresh (pending-day navigation; the actual data sync is
        // already driven by `TRPTimelineRefreshState.shared.setCompleted` from the
        // time-selection VM). Pass through the legacy `onSegmentCreated` too so any
        // external caller still using it keeps working.
        savedPlansVC.onSegmentCreatedSilent = { [weak self] selectedDay in
            self?.refreshTimelineSilently(selectedDay: selectedDay)
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

// MARK: - Activity ID Helpers

extension TRPTimelineItineraryVC {

    /// Extracts clean activity ID from POI for activity steps
    /// Priority: additionalData.productId → booking product ID → cleaned poi.id
    internal func extractActivityId(from poi: TRPPoi) -> String {
        // Priority 1: Use productId from additionalData
        if let productId = poi.additionalData?.productId, !productId.isEmpty {
            return productId.cleanedAsActivityId()
        }

        // Priority 2: Try booking product ID
        if let booking = poi.bookings?.first, let product = booking.firstProduct() {
            return product.id.cleanedAsActivityId()
        }

        // Priority 3: Fall back to POI ID (cleaned if needed)
        return poi.id.cleanedAsActivityId()
    }
}
