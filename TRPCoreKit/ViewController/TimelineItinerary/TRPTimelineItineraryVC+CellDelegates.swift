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
        viewModel.cancelActiveRouteCalculations()

        viewModel.selectDay(at: dayIndex)

        reload()

        // Use absolute zero offset (not scrollToRow) so the conflict banner header stays visible.
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

        if isShowingMap {
            refreshMap()
            updatePOIPreviewCards()

            if !currentTimelineItems.isEmpty {
                poiPreviewCollectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .left, animated: true)
            }
        }
    }
}

// MARK: - TRPTimelineActivityCellDelegate

extension TRPTimelineItineraryVC: TRPTimelineActivityCellDelegate {

    /// A booked activity opens the host's booking detail; reserved and flexible ones the activity detail.
    /// `cleanedAsActivityId()` normalizes any `C_{id}_{provider}` form.
    func activityCellDidTapCell(_ cell: TRPTimelineActivityCell, segment: TRPTimelineSegment, kind: TRPTimelineActivityCellKind) {
        switch kind {
        case .booked:
            guard let bookingId = segment.additionalData?.bookingId else { return }
            TRPCoreKit.shared.delegate?.trpCoreKitDidRequestBookingDetail(bookingId: bookingId.cleanedAsActivityId())

        case .reserved, .flexible:
            guard let activityId = segment.additionalData?.activityId else { return }
            TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityDetail(activityId: activityId.cleanedAsActivityId())
        }
    }

    func activityCellDidTapReservation(_ cell: TRPTimelineActivityCell, segment: TRPTimelineSegment, kind: TRPTimelineActivityCellKind) {
        guard let activityId = segment.additionalData?.activityId else { return }
        let cleanedId = activityId.cleanedAsActivityId()
        // A flexible row carries no specific slot, so the host gets the day at 00:00.
        let isFlexible = kind == .flexible || segment.additionalData?.isFlexible == true
        let preferred = segment.additionalData?.startDatetime ?? segment.startDate
        let reservationDate = resolveReservationDate(preferred: preferred, isFlexible: isFlexible)
        TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityReservation(activityId: cleanedId, date: reservationDate)
    }

    func activityCellDidTapRemove(_ cell: TRPTimelineActivityCell, segment: TRPTimelineSegment) {
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

    func activityCellDidTapChangeTime(_ cell: TRPTimelineActivityCell, segment: TRPTimelineSegment) {
        var planData = AddPlanData()
        planData.tripHash = viewModel.getTripHash()
        planData.availableDays = viewModel.getDayDates()
        planData.selectedCity = segment.city
        planData.travelers = segment.adults

        if let startDateStr = segment.startDate,
           let date = parseSegmentDateTime(startDateStr) {
            planData.selectedDay = date
        }

        planData.segmentIndex = viewModel.getSegmentIndex(for: segment)

        let timeSelectionVC = AddPlanTimeSelectionVC(segment: segment, planData: planData)

        // Sheet keeps its inline loader through the update API and host refresh; dismiss after to avoid a loader→loader jump.
        timeSelectionVC.onSegmentUpdated = { [weak self, weak timeSelectionVC] in
            guard let self = self else { return }
            // Picker only offers live-available slots, so drop the segment's stale "not available" key.
            self.viewModel.clearCachedAvailability(for: segment)
            self.viewModel.fetchAndRefreshTimeline { _ in
                DispatchQueue.main.async {
                    timeSelectionVC?.dismiss(animated: true)
                }
            }
        }

        // Confirm is shown by the sheet; here we just run the removal.
        timeSelectionVC.onRemoveFromPlan = { [weak self] in
            self?.viewModel.removeSegment(segment)
        }

        presentVCWithDynamicHeight(timeSelectionVC, prefersGrabberVisible: true, isDimmed: true)
    }
}

// MARK: - TRPTimelineActivityStepCellDelegate

extension TRPTimelineItineraryVC: TRPTimelineActivityStepCellDelegate {

    func activityStepCellDidTapMoreOptions(_ cell: TRPTimelineActivityStepCell) {
    }

    func activityStepCellDidTapReservation(_ cell: TRPTimelineActivityStepCell, step: TRPTimelineStep) {
        guard let poi = step.poi else { return }
        let activityId = extractActivityId(from: poi)
        let reservationDate = resolveReservationDate(preferred: step.startDateTimes)
        TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityReservation(activityId: activityId, date: reservationDate)
    }
}

// MARK: - TRPTimelineManualPoiCellDelegate

extension TRPTimelineItineraryVC: TRPTimelineManualPoiCellDelegate {

    func manualPoiCellDidTapChangeTime(_ cell: TRPTimelineManualPoiCell, segment: TRPTimelineSegment, poi: TRPPoi?) {
        segmentBeingEdited = segment

        let timeRangeVC = TRPTimeRangeSelectionViewController()
        timeRangeVC.delegate = self

        // City drives the min-time gate / default time in the city's IANA timezone, not the device's.
        timeRangeVC.setSelectedCity(segment.city)

        // Parse with `parseStepDateTime` (LOCAL) so the displayed HH:mm matches the stored value — the picker formats device-local.
        // `parseSegmentDateTime` stays UTC because it also feeds `resolveReservationDate`.
        if let startDateStr = segment.startDate,
           let endDateStr = segment.endDate,
           let startDate = parseStepDateTime(startDateStr),
           let endDate = parseStepDateTime(endDateStr) {
            timeRangeVC.setInitialTimes(from: startDate, to: endDate)
            timeRangeVC.setOpeningHours(poi?.hours, on: startDate)
        }

        timeRangeVC.show(from: self)
    }

    /// Resolves a Date carrying day + start time. Flexible pins to 00:00; else uses the source time. Falls back to the selected day at 00:00.
    /// All parsing is UTC: server strings are wall-clock UTC and the host expects UTC HH:mm.
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
        return baseDay.getDateWithZeroHour(forLocal: false)
    }

    /// Parses datetime strings as UTC (server times are wall-clock UTC). Supports formats with and without seconds.
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
        if let poi = poi {
            let dateRange = viewModel.getTripDateRange()
            let detailVM = TimelinePoiDetailViewModel(poi: poi,
                                                      tripStartDate: dateRange?.start,
                                                      tripEndDate: dateRange?.end)
            let detailVC = TimelinePoiDetailViewController(viewModel: detailVM)
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}

// MARK: - TRPTimelineSectionHeaderViewDelegate

extension TRPTimelineItineraryVC: TRPTimelineSectionHeaderViewDelegate {
}

// MARK: - TRPTimelineEmptyStateCellDelegate

extension TRPTimelineItineraryVC: TRPTimelineEmptyStateCellDelegate {

    func emptyStateCellDidTapAddPlan(_ cell: TRPTimelineEmptyStateCell) {
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
        if let indexPath = tableView.indexPath(for: cell) {
            viewModel.setSectionCollapseState(for: indexPath.section, isExpanded: isExpanded)
        }

        tableView.beginUpdates()
        tableView.endUpdates()
    }

    func recommendationsCellDidSelectStep(_ cell: TRPTimelineRecommendationsCell, step: TRPTimelineStep) {
        handleStepSelection(step)
    }

    func recommendationsCellDidTapChangeTime(_ cell: TRPTimelineRecommendationsCell, step: TRPTimelineStep) {
        handleStepChangeTime(step)
    }

    func recommendationsCellDidTapRemoveStep(_ cell: TRPTimelineRecommendationsCell, step: TRPTimelineStep) {
        handleStepRemoval(step)
    }

    func recommendationsCellDidTapReservation(_ cell: TRPTimelineRecommendationsCell, step: TRPTimelineStep) {
        handleStepReservation(step)
    }
}

// MARK: - TRPTimelinePlanStepCellDelegate

extension TRPTimelineItineraryVC: TRPTimelinePlanStepCellDelegate {

    func planStepCellDidSelect(_ cell: TRPTimelinePlanStepCell, step: TRPTimelineStep) {
        handleStepSelection(step)
    }

    func planStepCellDidTapChangeTime(_ cell: TRPTimelinePlanStepCell, step: TRPTimelineStep) {
        handleStepChangeTime(step)
    }

    func planStepCellDidTapRemove(_ cell: TRPTimelinePlanStepCell, step: TRPTimelineStep) {
        handleStepRemoval(step)
    }

    func planStepCellDidTapReservation(_ cell: TRPTimelinePlanStepCell, step: TRPTimelineStep) {
        handleStepReservation(step)
    }
}

// MARK: - Step Actions (shared by the recommendations card and the flat timeline's step rows)

extension TRPTimelineItineraryVC {

    /// "poi" steps open the internal POI detail; every other step type notifies the host for its product detail.
    internal func handleStepSelection(_ step: TRPTimelineStep) {
        guard let poi = step.poi else { return }

        // Mirror Android: only "poi" steps open the internal POI detail screen;
        // every other step type (e.g. "activity") notifies the host for its
        // product detail. (Gating on `== "activity"` wrongly routed non-"poi"
        // product steps to the internal screen → "activity not found".)
        if step.stepType == "poi" {
            let dateRange = viewModel.getTripDateRange()
            let detailViewModel = TimelinePoiDetailViewModel(poi: poi,
                                                            tripStartDate: dateRange?.start,
                                                            tripEndDate: dateRange?.end)
            let detailVC = TimelinePoiDetailViewController(viewModel: detailViewModel)
            navigationController?.pushViewController(detailVC, animated: true)
            return
        }

        let activityId = extractActivityId(from: poi)
        TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityDetail(activityId: activityId)
    }

    /// Activity steps open the availability time-slot picker; other steps the plain time range picker.
    internal func handleStepChangeTime(_ step: TRPTimelineStep) {
        if step.stepType == "activity" {
            openActivityTimeSelection(for: step)
        } else {
            openTimeRangeSelection(for: step)
        }
    }

    /// Opens AddPlanTimeSelectionVC for activity steps (with availability API)
    private func openActivityTimeSelection(for step: TRPTimelineStep) {
        var planData = AddPlanData()
        planData.tripHash = viewModel.getTripHash()
        planData.availableDays = viewModel.getDayDates()
        planData.travelers = 1

        if let poi = step.poi {
            planData.selectedCity = viewModel.getCities().first { $0.id == poi.cityId }
        }

        if let startDateTimes = step.startDateTimes,
           let date = parseStepDateTime(startDateTimes) {
            planData.selectedDay = date
        }

        let timeSelectionVC = AddPlanTimeSelectionVC(step: step, planData: planData)

        // Sheet keeps its inline loader through the host refresh; dismiss after.
        timeSelectionVC.onStepUpdated = { [weak self, weak timeSelectionVC] in
            guard let self = self else { return }
            self.viewModel.fetchAndRefreshTimeline { _ in
                DispatchQueue.main.async {
                    timeSelectionVC?.dismiss(animated: true)
                }
            }
        }

        // Confirm is shown by the sheet; here we just run the removal.
        timeSelectionVC.onRemoveFromPlan = { [weak self] in
            self?.viewModel.removeStep(step)
        }

        presentVCWithDynamicHeight(timeSelectionVC, prefersGrabberVisible: true, isDimmed: true)
    }

    /// Opens TRPTimeRangeSelectionViewController for regular POI steps
    private func openTimeRangeSelection(for step: TRPTimelineStep) {
        stepBeingEdited = step

        let timeRangeVC = TRPTimeRangeSelectionViewController()
        timeRangeVC.delegate = self

        // City drives the min-time gate / default time in the city's IANA timezone.
        if let cityId = step.poi?.cityId,
           let city = viewModel.getCities().first(where: { $0.id == cityId }) {
            timeRangeVC.setSelectedCity(city)
        }

        if let startDateTimes = step.startDateTimes,
           let endDateTimes = step.endDateTimes,
           let startDate = parseStepDateTime(startDateTimes),
           let endDate = parseStepDateTime(endDateTimes) {
            timeRangeVC.setInitialTimes(from: startDate, to: endDate)
            timeRangeVC.setOpeningHours(step.poi?.hours, on: startDate)
        }

        timeRangeVC.show(from: self)
    }

    /// Parses step datetime in LOCAL timezone (avoids UTC shift in the picker). Supports formats with and without seconds.
    internal func parseStepDateTime(_ dateTimeString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current

        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = dateFormatter.date(from: dateTimeString) {
            return date
        }

        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return dateFormatter.date(from: dateTimeString)
    }

    internal func handleStepRemoval(_ step: TRPTimelineStep) {
        showConfirmAlert(
            title: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.removeStepTitle),
            message: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.removeStepMessage),
            confirmTitle: TimelineLocalizationKeys.localized(TimelineLocalizationKeys.remove),
            btnConfirmAction: { [weak self] in
                self?.viewModel.removeStep(step)
            }
        )
    }

    internal func handleStepReservation(_ step: TRPTimelineStep) {
        guard let poi = step.poi else { return }
        let activityId = extractActivityId(from: poi)
        let reservationDate = resolveReservationDate(preferred: step.startDateTimes)
        TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityReservation(activityId: activityId, date: reservationDate)
    }
}

// MARK: - TRPTimelineRecommendationsCellDelegate (route calculation)

extension TRPTimelineItineraryVC {

    func recommendationsCellNeedsRouteCalculation(_ cell: TRPTimelineRecommendationsCell, locations: [TRPLocation], cellIndexPath: IndexPath) {
        guard locations.count > 1 else { return }

        var allCached = true
        var cachedResults: [(index: Int, data: TRPStepRouteInfo)] = []

        for i in 0..<(locations.count - 1) {
            let cacheKey = generateRouteCacheKey(from: locations[i], to: locations[i + 1])
            if let cachedResult = routeCache[cacheKey] {
                cachedResults.append((index: i, data: cachedResult))
            } else {
                allCached = false
                break
            }
        }

        if allCached {
            if calculatedDistances[cellIndexPath] == nil {
                calculatedDistances[cellIndexPath] = [:]
            }
            for result in cachedResults {
                calculatedDistances[cellIndexPath]?[result.index] = result.data
                cell.updateDistance(at: result.index, routeInfo: result.data)
            }
            return
        }

        viewModel.calculateStepRoutes(for: locations) { [weak self] routes in
            guard let self = self, let routes = routes else { return }

            if self.calculatedDistances[cellIndexPath] == nil {
                self.calculatedDistances[cellIndexPath] = [:]
            }

            for (index, routeInfo) in routes.enumerated() {
                if index < locations.count - 1 {
                    let cacheKey = self.generateRouteCacheKey(from: locations[index], to: locations[index + 1])
                    self.routeCache[cacheKey] = routeInfo
                }

                self.calculatedDistances[cellIndexPath]?[index] = routeInfo
            }

            if let currentCell = self.tableView.cellForRow(at: cellIndexPath) as? TRPTimelineRecommendationsCell {
                if let distances = self.calculatedDistances[cellIndexPath] {
                    for (index, routeInfo) in distances {
                        currentCell.updateDistance(at: index, routeInfo: routeInfo)
                    }
                }
            } else {
                // Cell offscreen — reload so it picks up cached distances when visible.
                if cellIndexPath.section < self.tableView.numberOfSections,
                   cellIndexPath.row < self.tableView.numberOfRows(inSection: cellIndexPath.section) {
                    self.tableView.reloadRows(at: [cellIndexPath], with: .none)
                }
            }
        }
    }

    internal func generateRouteCacheKey(from: TRPLocation, to: TRPLocation) -> String {
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
        // Map view → switch back to list instead of closing the SDK.
        if isShowingMap {
            toggleView()
            return
        }

        // This is the root screen, so back closes the SDK by dismissing the nav controller.
        if let navController = navigationController {
            navController.dismiss(animated: true, completion: nil)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - TRPTimelineSavedPlansButtonDelegate

extension TRPTimelineItineraryVC: TRPTimelineSavedPlansButtonDelegate {

    func savedPlansButtonDidTap(_ button: TRPTimelineSavedPlansButton) {
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

        // Saved Plans stays open after an add; the time-selection sheet's loader covers create + regeneration, so we only need a silent refresh behind it.
        savedPlansVC.onSegmentCreatedSilent = { [weak self] selectedDay in
            self?.refreshTimelineSilently(selectedDay: selectedDay)
        }

        let navController = UINavigationController(rootViewController: savedPlansVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
}

// MARK: - TRPTimeRangeSelectionDelegate

extension TRPTimelineItineraryVC: TRPTimeRangeSelectionDelegate {

    func timeRangeSelected(fromTime: String, toTime: String) {
        if let segment = segmentBeingEdited {
            viewModel.updateSegmentTime(segment: segment, startTime: fromTime, endTime: toTime) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .success:
                    self.segmentBeingEdited = nil

                case .failure:
                    self.segmentBeingEdited = nil
                }
            }
            return
        }

        guard let step = stepBeingEdited else { return }

        viewModel.updateStepTime(step: step, startTime: fromTime, endTime: toTime) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.stepBeingEdited = nil
                self.delegate?.timelineItineraryChangeTimePressed(self, step: step)

            case .failure:
                self.stepBeingEdited = nil
            }
        }
    }

    func timeRangeSelected(fromDate: Date, toDate: Date) {
        // Not used — the String version is.
    }
}

// MARK: - Activity ID Helpers

extension TRPTimelineItineraryVC {

    /// Clean activity ID. Priority: additionalData.productId → booking product ID → cleaned poi.id.
    internal func extractActivityId(from poi: TRPPoi) -> String {
        if let productId = poi.additionalData?.productId, !productId.isEmpty {
            return productId.cleanedAsActivityId()
        }

        if let booking = poi.bookings?.first, let product = booking.firstProduct() {
            return product.id.cleanedAsActivityId()
        }

        return poi.id.cleanedAsActivityId()
    }
}
