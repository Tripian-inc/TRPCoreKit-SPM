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
            self.refreshTimelineAfterSegmentCreation()
        }
    }

    internal func refreshTimelineAfterSegmentCreation() {
        guard let tripHash = viewModel.getTripHash() else { return }

        // Wait for segment generation to complete, then refresh timeline
        viewModel.waitForSegmentGeneration(tripHash: tripHash)
    }

    // MARK: - Smart Recommendations Segment Creation

    internal func createSmartRecommendationSegment(from data: AddPlanData, containerVC: AddPlanContainerVC) {
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

// MARK: - UICollectionViewDataSource & UICollectionViewDelegateFlowLayout

extension TRPTimelineItineraryVC: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mapDisplayItems.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TRPTimelineMapPOIPreviewCell.reuseIdentifier, for: indexPath) as? TRPTimelineMapPOIPreviewCell else {
            return UICollectionViewCell()
        }

        let (order, _, item) = mapDisplayItems[indexPath.item]

        // Configure cell with MapDisplayItem and unified order (city-based)
        cell.configure(with: item, order: order)

        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 300, height: 104)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Expand the collection view when user taps on an item
        expandCollectionView()

        let (_, _, item) = mapDisplayItems[indexPath.item]

        // Center map on selected item's coordinate
        if let coordinate = item.coordinate, let mapView = map {
            mapView.setCenter(coordinate, zoomLevel: 15)
        }
    }
}
