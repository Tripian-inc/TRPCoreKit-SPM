//
//  TRPTimelineItineraryVC+AddPlan.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 20.01.2025.
//  Copyright © 2025 Tripian Inc. All rights reserved.
//
//  SOLID: SRP - AddPlan flow and delegate implementations extracted from main VC
//

import UIKit
import TRPFoundationKit

// MARK: - Add Plan Flow

extension TRPTimelineItineraryVC {

    public func showAddPlanFlow() {
        // Get available days and cities from view model
        let days = viewModel.getDayDates()
        let cities = viewModel.getCities()
        let selectedDayIndex = viewModel.selectedDayIndex
        let bookedActivities = viewModel.getAllBookedActivities()
        let destinationItems = viewModel.getDestinationItems()
        let favouriteItems = viewModel.getFavoriteItems()

        // Create container view model
        let containerViewModel = AddPlanContainerViewModel(days: days,
                                                           cities: cities,
                                                           selectedDayIndex: selectedDayIndex,
                                                           bookedActivities: bookedActivities,
                                                           destinationItems: destinationItems,
                                                           favouriteItems: favouriteItems)

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

        // Manual activity flow now stays on the listing on success and shows a toast
        // there — only the underlying timeline needs a silent refresh, no modal
        // dismiss. `onSegmentCreated` is intentionally not wired so the legacy
        // dismiss-everything path doesn't fire.
        activityListingVC.onSegmentCreatedSilent = { [weak self] selectedDay in
            self?.refreshTimelineSilently(selectedDay: selectedDay)
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

        // Set segment creation callback with selected day for navigation
        poiListingVC.onSegmentCreated = { [weak self, weak viewController] selectedDay in
            guard let self = self, let viewController = viewController else { return }
            // Trigger container delegate with selected day
            self.addPlanContainerSegmentCreated(viewController, selectedDay: selectedDay)
        }

        // Create navigation controller for the POI listing
        let navController = UINavigationController(rootViewController: poiListingVC)
        navController.modalPresentationStyle = .fullScreen

        // Present from the AddPlanContainerVC instead of dismissing it first
        viewController.present(navController, animated: true)
    }

    public func addPlanContainerSegmentCreated(_ viewController: AddPlanContainerVC, selectedDay: Date?) {
        // Dismiss all modals from self (TRPTimelineItineraryVC)
        // This will dismiss AddPlanContainerVC and all modals presented on top of it
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            // Set pending day navigation before refresh
            self.setPendingDayNavigation(selectedDay: selectedDay)
            // Refresh timeline after segment creation
            self.refreshTimelineAfterSegmentCreation()
        }
    }

    /// Sets pending day navigation index from selected day
    /// This will be applied after segment generation completes
    internal func setPendingDayNavigation(selectedDay: Date?) {
        guard let selectedDay = selectedDay else { return }
        let availableDays = viewModel.getAvailableDates()
        if let index = availableDays.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: selectedDay) }) {
            viewModel.pendingNavigationDayIndex = index
        }
    }

    internal func refreshTimelineAfterSegmentCreation() {
        guard let tripHash = viewModel.getTripHash() else { return }

        // Wait for segment generation to complete, then refresh timeline
        viewModel.waitForSegmentGeneration(tripHash: tripHash)
    }

    /// Refresh the timeline data without dismissing any of the modal stack
    /// (AddPlanContainerVC / ActivityListing / TimeSelection). Used by flows that
    /// surface their own in-screen confirmation (toast) and want the user to keep
    /// browsing — the underlying timeline still reflects the new segment when the
    /// user eventually returns to it.
    internal func refreshTimelineSilently(selectedDay: Date?) {
        setPendingDayNavigation(selectedDay: selectedDay)
        refreshTimelineAfterSegmentCreation()
    }

    // MARK: - Smart Recommendations Segment Creation

    internal func createSmartRecommendationSegment(from data: AddPlanData, containerVC: AddPlanContainerVC) {
        // Dismiss AddPlan modal first, then start segment creation
        // This prevents "already presenting" error when showing Lottie loading
        containerVC.dismiss(animated: true) { [weak self] in
            // Delegate segment creation to ViewModel (this shows Lottie loading)
            self?.viewModel.createSmartRecommendationSegment(from: data)
        }
    }
}

// MARK: - TRPTimelineItineraryViewModelDelegate

extension TRPTimelineItineraryVC: TRPTimelineItineraryViewModelDelegate {

    public func timelineItineraryViewModel(didUpdateTimeline: Bool) {
        guard didUpdateTimeline else { return }
        reload()
    }

    public func timelineItineraryViewModel(noCitiesAvailable: Bool) {
        guard noCitiesAvailable else { return }
        showNoCityState()
    }

    public func timelineItineraryViewModel(someCitiesUnavailable cityNames: [String]) {
        // Format city names: "City1, City2"
        let cityList = cityNames.joined(separator: ", ")

        // Get localized strings
        let titleFormat = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.partialUnavailableTitle)
        let title = String(format: titleFormat, cityList)
        let description = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.partialUnavailableDescription)
        let buttonTitle = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.partialUnavailableButton)

        // Show alert (no completion needed - timeline continues in background)
        showOkAlert(title: title, message: "", subContent: description, btnTitle: buttonTitle)
    }

    public func timelineItineraryViewModel(showLottieLoading: Bool, textMode: LottieLoadingTextMode) {
        if showLottieLoading {
            TRPLottieLoadingVC.shared.showOnWindow(textMode: textMode)
        } else {
            TRPLottieLoadingVC.shared.hideFromWindow()
        }
    }

    private func showNoCityState() {
        // Hide other UI elements
        dayFilterView.isHidden = true
        savedPlansButton.isHidden = true
        tableView.isHidden = true
        mapContainerView.isHidden = true
        mapFloatingButton.isHidden = true
        addPlanFloatingButton.isHidden = true

        // Show no city view
        noCityView.isHidden = false
    }
}

// MARK: - TRPNoCityViewDelegate

extension TRPTimelineItineraryVC: TRPNoCityViewDelegate {

    func noCityViewDidTapButton(_ view: TRPNoCityView) {
        // Dismiss SDK - use same pattern as back button
        if let navController = navigationController {
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

        let (order, _, _, item) = mapDisplayItems[indexPath.item]
        let isSelected = selectedMarkerPoiIds.contains(item.itemId)

        // Configure cell with MapDisplayItem, unified order, and selection state
        cell.configure(with: item, order: order, isSelected: isSelected)

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 300, height: 104)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let (_, _, _, item) = mapDisplayItems[indexPath.item]

        // Check if item is already selected
        let isAlreadySelected = selectedMarkerPoiIds.contains(item.itemId)

        if isAlreadySelected {
            // Navigate to detail - use same logic as list (RecommendationsCell)
            switch item {
            case .poi(_, _, let step):
                guard let step = step, let poi = step.poi else { return }

                // Activity step - call trpCoreKitDidRequestActivityDetail (same as list)
                if step.stepType == "activity" {
                    let activityId = extractActivityId(from: poi)
                    TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityDetail(activityId: activityId)
                    return
                }

                // Normal POI step - open POI detail view controller (same as list)
                let detailVM = TimelinePoiDetailViewModel(poi: poi)
                let detailVC = TimelinePoiDetailViewController(viewModel: detailVM)
                navigationController?.pushViewController(detailVC, animated: true)

            case .activity(let segment):
                // Booked/Reserved activity - call trpCoreKitDidRequestActivityDetail (same as list)
                guard let activityId = segment.additionalData?.activityId else { return }
                let cleanedId = activityId.cleanedAsActivityId()
                TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityDetail(activityId: cleanedId)
            }
        } else {
            // Normal selection flow
            expandCollectionView()

            // In multi-city mode, switch to step markers when selecting from collection view
            if viewModel.hasMultipleCities() && !isShowingStepMarkersInMultiCity {
                isShowingStepMarkersInMultiCity = true

                // Clear and redraw with step markers
                selectedMarkerPoiIds.removeAll()
                selectedMarkerPoiIds.insert(item.itemId)

                clearMapAnnotations()
                let orderedItems = viewModel.getOrderedItemsForMap()
                addAnnotationsForOrderedItems(orderedItems)
            } else {
                updateSelectedMarker(poiId: item.itemId)
            }

            if let coordinate = item.coordinate, let mapView = map {
                mapView.setCenter(coordinate, zoomLevel: 15)
                isMarkerFocused = true
                updateMainViewButtonVisibility()
            }

            // Scroll collection view to center the selected item
            poiPreviewCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            poiPreviewCollectionView.reloadData()
        }
    }

    // MARK: - Custom Paging

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView == poiPreviewCollectionView else { return }

        let cellWidth: CGFloat = 300
        let spacing: CGFloat = 8
        let itemWidth = cellWidth + spacing
        let leftInset: CGFloat = 16

        // Calculate nearest index based on target offset
        let targetX = targetContentOffset.pointee.x + leftInset
        var nearestIndex = round(targetX / itemWidth)

        // Clamp to valid range
        nearestIndex = max(0, min(nearestIndex, CGFloat(mapDisplayItems.count - 1)))

        // Calculate new target offset (left-aligned)
        let newTargetX = nearestIndex * itemWidth - leftInset
        targetContentOffset.pointee.x = newTargetX
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == poiPreviewCollectionView else { return }
        syncMapSelectionWithVisibleCell()
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == poiPreviewCollectionView, !decelerate else { return }
        syncMapSelectionWithVisibleCell()
    }

    /// Sync map selection with the currently visible cell in collection view
    private func syncMapSelectionWithVisibleCell() {
        let cellWidth: CGFloat = 300
        let spacing: CGFloat = 8
        let itemWidth = cellWidth + spacing
        let leftInset: CGFloat = 16

        // Find the left-aligned visible cell index
        let currentIndex = Int(round((poiPreviewCollectionView.contentOffset.x + leftInset) / itemWidth))

        guard currentIndex >= 0, currentIndex < mapDisplayItems.count else { return }

        let (_, _, _, item) = mapDisplayItems[currentIndex]

        // Update selected marker on map
        updateSelectedMarker(poiId: item.itemId)

        // Center map on selected item's coordinate
        if let coordinate = item.coordinate {
            map?.setCenter(coordinate, zoomLevel: 15)
        }

        // Update focus state for Main View button
        isMarkerFocused = true
        updateMainViewButtonVisibility()

        // Reload collection view to update badge styles
        poiPreviewCollectionView.reloadData()
    }
}
