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
        let days = viewModel.getDayDates()
        let cities = viewModel.getCities()
        let selectedDayIndex = viewModel.selectedDayIndex
        let bookedActivities = viewModel.getAllBookedActivities()
        let destinationItems = viewModel.getDestinationItems()
        let favouriteItems = viewModel.getFavoriteItems()

        let containerViewModel = AddPlanContainerViewModel(days: days,
                                                           cities: cities,
                                                           selectedDayIndex: selectedDayIndex,
                                                           bookedActivities: bookedActivities,
                                                           destinationItems: destinationItems,
                                                           favouriteItems: favouriteItems)

        containerViewModel.planData.tripHash = viewModel.getTripHash()

        let containerVC = AddPlanContainerVC()
        containerVC.viewModel = containerViewModel
        containerVC.delegate = self

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

        containerVC.addViewController(selectDayVC)
        containerVC.addViewController(timeAndTravelersVC)
        containerVC.addViewController(categoryVC)

        presentVCWithDynamicHeight(containerVC)
    }
}

// MARK: - AddPlanContainerVCDelegate

extension TRPTimelineItineraryVC: AddPlanContainerVCDelegate {

    public func addPlanContainerDidComplete(_ viewController: AddPlanContainerVC, data: AddPlanData) {
        guard data.selectedMode == .smartRecommendations else {
            viewController.dismiss(animated: true)
            return
        }

        createSmartRecommendationSegment(from: data, containerVC: viewController)
    }

    public func addPlanContainerDidCancel(_ viewController: AddPlanContainerVC) {
    }

    public func addPlanContainerShouldShowActivityListing(_ viewController: AddPlanContainerVC, data: AddPlanData) {
        let activityListingViewModel = AddPlanActivityListingViewModel(planData: data)
        let activityListingVC = AddPlanActivityListingVC()
        activityListingVC.viewModel = activityListingViewModel

        activityListingVC.onSegmentCreatedSilent = { [weak self] selectedDay in
            self?.refreshTimelineSilently(selectedDay: selectedDay)
        }

        let navController = UINavigationController(rootViewController: activityListingVC)
        navController.modalPresentationStyle = .fullScreen

        // Present from the AddPlan sheet (kept underneath) so the transition has no gap; back handler tears down the whole stack.
        viewController.present(navController, animated: true)
    }

    public func addPlanContainerShouldShowPOIListing(_ viewController: AddPlanContainerVC, data: AddPlanData, categoryType: POIListingCategoryType) {
        let poiListingViewModel = AddPlanPOIListingViewModel(planData: data, categoryType: categoryType)
        let poiListingVC = AddPlanPOIListingVC()
        poiListingVC.viewModel = poiListingViewModel

        poiListingVC.onSegmentCreatedSilent = { [weak self] selectedDay in
            self?.refreshTimelineSilently(selectedDay: selectedDay)
        }

        let navController = UINavigationController(rootViewController: poiListingVC)
        navController.modalPresentationStyle = .fullScreen

        // Same pattern as activity listing — present on top of AddPlan; back handler tears down the chain.
        viewController.present(navController, animated: true)
    }

    public func addPlanContainerSegmentCreated(_ viewController: AddPlanContainerVC, selectedDay: Date?) {
        // Dismissing self tears down AddPlanContainerVC and any modals on top of it.
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.setPendingDayNavigation(selectedDay: selectedDay)
            self.refreshTimelineAfterSegmentCreation()
        }
    }

    /// Sets pending day navigation index, applied after segment generation completes.
    internal func setPendingDayNavigation(selectedDay: Date?) {
        guard let selectedDay = selectedDay else { return }
        let availableDays = viewModel.getAvailableDates()
        if let index = availableDays.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: selectedDay) }) {
            viewModel.pendingNavigationDayIndex = index
        }
    }

    internal func refreshTimelineAfterSegmentCreation() {
        guard let tripHash = viewModel.getTripHash() else { return }

        viewModel.waitForSegmentGeneration(tripHash: tripHash)
    }

    /// Apply the new day directly (don't rely on `pendingNavigationDayIndex`): silent-refresh VMs fire `setCompleted` before this callback, so the observer already read a nil index.
    internal func refreshTimelineSilently(selectedDay: Date?) {
        guard let selectedDay = selectedDay else { return }
        let availableDays = viewModel.getAvailableDates()
        guard let index = availableDays.firstIndex(where: {
            Calendar.current.isDate($0, inSameDayAs: selectedDay)
        }) else { return }
        viewModel.selectDay(at: index)
        reload()
    }

    // MARK: - Smart Recommendations Segment Creation

    internal func createSmartRecommendationSegment(from data: AddPlanData, containerVC: AddPlanContainerVC) {
        // Dismiss AddPlan first to avoid an "already presenting" error when the Lottie loading appears.
        containerVC.dismiss(animated: true) { [weak self] in
            self?.viewModel.createSmartRecommendationSegment(from: data)
        }
    }
}

// MARK: - TRPTimelineItineraryViewModelDelegate

extension TRPTimelineItineraryVC: TRPTimelineItineraryViewModelDelegate {

    public func timelineItineraryViewModel(didUpdateTimeline: Bool) {
        guard didUpdateTimeline else { return }
        // Clear the per-day banner dismissal so a freshly introduced overlap re-surfaces the warning.
        conflictWarningDismissedDayIndex = nil
        viewModel(hideLottie: .bottomSheet)
        reload()
    }

    public func timelineItineraryViewModel(noCitiesAvailable: Bool) {
        guard noCitiesAvailable else { return }
        showNoCityState()
    }

    public func timelineItineraryViewModel(someCitiesUnavailable cityNames: [String]) {
        let cityList = cityNames.joined(separator: ", ")

        let titleFormat = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.partialUnavailableTitle)
        let title = String(format: titleFormat, cityList)
        let description = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.partialUnavailableDescription)
        let buttonTitle = TimelineLocalizationKeys.localized(TimelineLocalizationKeys.partialUnavailableButton)

        showOkAlert(title: title, message: "", subContent: description, btnTitle: buttonTitle)
    }

    public func timelineItineraryViewModel(showLottieLoading: Bool, textMode: LottieLoadingTextMode) {
        if showLottieLoading {
            viewModel(showLottie: .fullScreen, textMode: textMode)
        } else {
            viewModel(hideLottie: .fullScreen)
        }
    }

    private func showNoCityState() {
        dayFilterView.isHidden = true
        savedPlansButton.isHidden = true
        tableView.isHidden = true
        mapContainerView.isHidden = true
        mapFloatingButton.isHidden = true
        addPlanFloatingButton.isHidden = true

        noCityView.isHidden = false
    }
}

// MARK: - TRPNoCityViewDelegate

extension TRPTimelineItineraryVC: TRPNoCityViewDelegate {

    func noCityViewDidTapButton(_ view: TRPNoCityView) {
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

        cell.configure(with: item, order: order, isSelected: isSelected)

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 300, height: 126)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let (_, _, _, item) = mapDisplayItems[indexPath.item]

        let isAlreadySelected = selectedMarkerPoiIds.contains(item.itemId)

        if isAlreadySelected {
            switch item {
            case .poi(let manualPoi, _, let step):
                // Recommendation step uses the step's poi; manual-POI segment has step == nil and its own manualPoi.
                let poi = step?.poi ?? manualPoi

                if step?.stepType == "activity" {
                    let activityId = extractActivityId(from: poi)
                    TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityDetail(activityId: activityId)
                    return
                }

                let detailVM = TimelinePoiDetailViewModel(poi: poi)
                let detailVC = TimelinePoiDetailViewController(viewModel: detailVM)
                navigationController?.pushViewController(detailVC, animated: true)

            case .activity(let segment):
                // Booked → bookingDetail; Reserved → activityDetail. Ids normalized via `cleanedAsActivityId()`.
                if segment.segmentType == .bookedActivity {
                    guard let bookingId = segment.additionalData?.bookingId else { return }
                    TRPCoreKit.shared.delegate?.trpCoreKitDidRequestBookingDetail(bookingId: bookingId.cleanedAsActivityId())
                } else {
                    guard let activityId = segment.additionalData?.activityId else { return }
                    TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityDetail(activityId: activityId.cleanedAsActivityId())
                }
            }
        } else {
            expandCollectionView()

            if viewModel.hasMultipleCities() && !isShowingStepMarkersInMultiCity {
                isShowingStepMarkersInMultiCity = true

                selectedMarkerPoiIds.removeAll()
                selectedMarkerPoiIds.insert(item.itemId)

                clearMapAnnotations()
                let orderedItems = viewModel.getOrderedItemsForMap()
                addAnnotationsForOrderedItems(orderedItems)
            } else {
                updateSelectedMarker(poiId: item.itemId)
            }

            // No-exact-location items use a city-center fallback coordinate; don't recenter the map for them.
            if !item.isNoLocation, let coordinate = item.coordinate, let mapView = map {
                mapView.setCenter(coordinate, zoomLevel: 15)
                isMarkerFocused = true
                updateMainViewButtonVisibility()
            }

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

        let targetX = targetContentOffset.pointee.x + leftInset
        var nearestIndex = round(targetX / itemWidth)

        nearestIndex = max(0, min(nearestIndex, CGFloat(mapDisplayItems.count - 1)))

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

    private func syncMapSelectionWithVisibleCell() {
        let cellWidth: CGFloat = 300
        let spacing: CGFloat = 8
        let itemWidth = cellWidth + spacing
        let leftInset: CGFloat = 16

        let currentIndex = Int(round((poiPreviewCollectionView.contentOffset.x + leftInset) / itemWidth))

        guard currentIndex >= 0, currentIndex < mapDisplayItems.count else { return }

        let (_, _, _, item) = mapDisplayItems[currentIndex]

        updateSelectedMarker(poiId: item.itemId)

        // Skip recentering for no-exact-location items so the map stays put.
        if !item.isNoLocation, let coordinate = item.coordinate {
            map?.setCenter(coordinate, zoomLevel: 15)
        }

        isMarkerFocused = true
        updateMainViewButtonVisibility()

        poiPreviewCollectionView.reloadData()
    }
}
