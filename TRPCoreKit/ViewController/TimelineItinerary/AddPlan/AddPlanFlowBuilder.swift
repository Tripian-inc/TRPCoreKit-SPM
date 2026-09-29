//
//  AddPlanFlowBuilder.swift
//  TRPCoreKit
//
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import UIKit

/// Assembles the add plan sheet and the listings it opens from a timeline view model, so the
/// timeline screen and the standalone add plan flow build exactly the same screens.
enum AddPlanFlowBuilder {

    /// The add plan sheet with its day, time and category steps, reading days, cities, booked
    /// activities and favourites from `viewModel`. The caller presents it.
    static func makeContainer(viewModel: TRPTimelineItineraryViewModel,
                              delegate: AddPlanContainerVCDelegate) -> AddPlanContainerVC {
        let containerViewModel = AddPlanContainerViewModel(days: viewModel.getDayDates(),
                                                           cities: viewModel.getCities(),
                                                           selectedDayIndex: viewModel.selectedDayIndex,
                                                           bookedActivities: viewModel.getAllBookedActivities(),
                                                           destinationItems: viewModel.getDestinationItems(),
                                                           favouriteItems: viewModel.getFavoriteItems(),
                                                           defaultTravelers: viewModel.defaultTravelerCount())
        containerViewModel.planData.tripHash = viewModel.getTripHash()

        let containerVC = AddPlanContainerVC()
        containerVC.viewModel = containerViewModel
        containerVC.delegate = delegate

        let selectDayVC = AddPlanSelectDayVC()
        selectDayVC.viewModel = AddPlanSelectDayViewModel(containerViewModel: containerViewModel)
        selectDayVC.containerVC = containerVC

        let timeAndTravelersVC = AddPlanTimeAndTravelersVC()
        timeAndTravelersVC.viewModel = AddPlanTimeAndTravelersViewModel(containerViewModel: containerViewModel)
        timeAndTravelersVC.containerVC = containerVC

        let categoryVC = AddPlanCategorySelectionVC()
        categoryVC.viewModel = AddPlanCategorySelectionViewModel(containerViewModel: containerViewModel)
        categoryVC.containerVC = containerVC

        containerVC.addViewController(selectDayVC)
        containerVC.addViewController(timeAndTravelersVC)
        containerVC.addViewController(categoryVC)
        return containerVC
    }

    /// The activity listing in a full screen navigation controller, meant to be presented over
    /// the sheet. `onSegmentCreated` receives the day each added activity went to.
    static func makeActivityListing(data: AddPlanData,
                                    viewModel: TRPTimelineItineraryViewModel,
                                    onSegmentCreated: @escaping (Date?) -> Void) -> UINavigationController {
        let listingVC = AddPlanActivityListingVC()
        listingVC.viewModel = AddPlanActivityListingViewModel(planData: data,
                                                              activityIdsByDay: viewModel.plannedActivityIdsByDay())
        listingVC.onSegmentCreatedSilent = onSegmentCreated
        return fullScreenNavigationController(root: listingVC)
    }

    /// The place listing for `categoryType` in a full screen navigation controller, meant to be
    /// presented over the sheet. `onSegmentCreated` receives the day each added place went to.
    static func makePOIListing(data: AddPlanData,
                               categoryType: POIListingCategoryType,
                               viewModel: TRPTimelineItineraryViewModel,
                               onSegmentCreated: @escaping (Date?) -> Void) -> UINavigationController {
        let listingViewModel = AddPlanPOIListingViewModel(planData: data, categoryType: categoryType)
        listingViewModel.poiIdsByDay = viewModel.plannedPoiIdsByDay()
        let listingVC = AddPlanPOIListingVC()
        listingVC.viewModel = listingViewModel
        listingVC.onSegmentCreatedSilent = onSegmentCreated
        return fullScreenNavigationController(root: listingVC)
    }

    private static func fullScreenNavigationController(root: UIViewController) -> UINavigationController {
        let navController = UINavigationController(rootViewController: root)
        navController.modalPresentationStyle = .fullScreen
        return navController
    }
}
