//
//  TRPTimelineCoordinator.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 27.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
import TRPFoundationKit

/// Delegate protocol for TRPTimelineCoordinator
public protocol TRPTimelineCoordinatorDelegate: AnyObject {
    /// Called when the timeline coordinator needs to show city selection
    func timelineCoordinatorShowCitySelection(_ coordinator: TRPTimelineCoordinator, from viewController: UIViewController)

    /// Called when the timeline coordinator needs to show date range selection
    func timelineCoordinatorShowDateRangeSelection(_ coordinator: TRPTimelineCoordinator, from viewController: UIViewController, preselected: (Date, Date)?, maxDays: Int)

    /// Called when the timeline coordinator needs to show travelers selection
    func timelineCoordinatorShowTravelersSelection(_ coordinator: TRPTimelineCoordinator, from viewController: UIViewController, preselected: (adults: Int, children: Int, pets: Int))

    /// Called when the user closes the timeline view
    func timelineCoordinatorDidClose(_ coordinator: TRPTimelineCoordinator)
}

/// Coordinator for managing timeline creation and display flows
public class TRPTimelineCoordinator: CoordinatorProtocol {

    // MARK: - CoordinatorProtocol
    public var navigationController: UINavigationController?
    var childCoordinators: [any CoordinatorProtocol] = []

    // MARK: - Properties
    public weak var delegate: TRPTimelineCoordinatorDelegate?

    private var timelineViewController: TRPTimelineItineraryVC?
    private var timelineRepository: TimelineRepository
    private var timelineModelRepository: TimelineModelRepository
    private var currentTripHash: String?
    private var tryCount = 0
    private let maxTryCount = 8

    // Store the original profile to merge segments and favourites
    private var originalProfile: TRPTimelineProfile?

    // Use Cases
    private var createTimelineUseCase: CreateTimelineUseCases?
    private var observeTimelineAllPlan: ObserveTimelineCheckAllPlanUseCase?
    private var fetchTimelineAllPlan: FetchTimelineCheckAllPlanUseCase?

    // MARK: - Initialization

    /// Initialize coordinator with navigation controller
    /// - Parameters:
    ///   - navigationController: Navigation controller for pushing/presenting views
    ///   - timelineRepository: Repository for timeline API operations (optional, defaults to TRPTimelineRepository)
    ///   - timelineModelRepository: Repository for timeline model operations (optional, defaults to TRPTimelineModelRepository)
    public init(navigationController: UINavigationController?,
                timelineRepository: TimelineRepository? = nil,
                timelineModelRepository: TimelineModelRepository? = nil) {
        self.navigationController = navigationController
        self.timelineRepository = timelineRepository ?? TRPTimelineRepository()
        self.timelineModelRepository = timelineModelRepository ?? TRPTimelineModelRepository()

        // Initialize use cases
        self.createTimelineUseCase = TRPCreateTimelineUseCase(repository: self.timelineRepository)

        let checkAllPlanUseCases = TRPTimelineCheckAllPlanUseCases(
            timelineRepository: self.timelineRepository,
            timelineModelRepository: self.timelineModelRepository
        )
        self.observeTimelineAllPlan = checkAllPlanUseCases
        self.fetchTimelineAllPlan = checkAllPlanUseCases
    }

    // MARK: - Public Methods

    /// Start timeline flow with no trip hash (create new timeline)
    /// This will create a timeline and wait for generation to complete
    /// - Parameter profile: Timeline profile with trip details (dates, travelers, city, etc.)
    public func start(with profile: TRPTimelineProfile) {
        // Store the profile to merge segments later
        self.originalProfile = profile

        createTimeline(with: profile)
    }

    /// Start timeline flow with existing trip hash (fetch existing timeline)
    /// This will fetch the timeline and display it immediately
    /// - Parameter tripHash: The trip hash for the existing timeline
    public func start(tripHash: String) {
        self.currentTripHash = tripHash
        fetchTimeline(tripHash: tripHash)
    }

    /// Start with default implementation (for protocol conformance)
    public func start() {
        // Use start(with:) or start(tripHash:) instead
    }

    // MARK: - Private Methods - Timeline Creation Flow

    private func createTimeline(with profile: TRPTimelineProfile) {
        // Show Lottie loading
        showLottieLoading()

        createTimelineUseCase?.executeCreateTimeline(profile: profile) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let timeline):
                    self.currentTripHash = timeline.tripHash
                    self.checkTimelineGenerationStatus(tripHash: timeline.tripHash)

                case .failure(let error):
                    self.hideLottieLoading()
                    self.showError(message: "Failed to create timeline. Please try again.")
                }
            }
        }
    }

    private func checkTimelineGenerationStatus(tripHash: String) {
        // Lottie loading already shown from createTimeline, keep it visible

        // Setup observer for all segments generated
        observeTimelineAllPlan?.allSegmentGenerated.addObserver(self) { [weak self] isGenerated in
            guard let self = self else { return }

            self.tryCount += 1

            if !isGenerated {
                if self.tryCount > self.maxTryCount {
                    DispatchQueue.main.async {
                        self.hideLottieLoading()
                        self.showError(message: TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.localExperiences.tourDetails.bookingStatus.rejected.description"))
                    }
                }
                return
            }

            // All segments generation completed
            DispatchQueue.main.async {
                // Notify delegate about timeline creation
                TRPCoreKit.shared.delegate?.trpCoreKitDidCreateTimeline(tripHash: tripHash)

                // Hide create-phase Lottie, then open the VC. The VC will run its own GetTimeline
                // request and show its own Lottie loader — keeping the loading UI in the VC.
                let profile = self.originalProfile
                self.hideLottieLoading { [weak self] in
                    self?.openTimelineViewController(withTripHash: tripHash, mergeProfile: profile)
                }
            }
        }

        // Start fetching and polling
        fetchTimelineAllPlan?.executeFetchTimelineCheckAllPlanGenerate(tripHash: tripHash, completion: nil)
    }

    // MARK: - Private Methods - Timeline Fetch Flow

    /// Opens the timeline VC immediately with a trip hash. The VC shows its own Lottie loader
    /// while performing the GetTimeline request — coordinator does NOT show a loader here.
    private func fetchTimeline(tripHash: String) {
        openTimelineViewController(withTripHash: tripHash)
    }

    // MARK: - Private Methods - View Controllers

    /// Opens the timeline VC with a trip hash; the VC fetches the timeline itself and shows
    /// its own Lottie loader. Coordinator does not perform a GetTimeline call here.
    /// - Parameter mergeProfile: Optional create-flow profile whose segments/favourites are merged
    ///   into the fetched timeline by the ViewModel.
    private func openTimelineViewController(withTripHash tripHash: String,
                                            mergeProfile: TRPTimelineProfile? = nil) {
        let viewModel = TRPTimelineItineraryViewModel(tripHash: tripHash, mergeProfile: mergeProfile)
        let viewController = TRPTimelineItineraryVC(viewModel: viewModel)
        viewController.delegate = self

        self.timelineViewController = viewController

        let navController = UINavigationController(rootViewController: viewController)
        navController.modalPresentationStyle = .fullScreen

        navigationController?.present(navController, animated: true)
    }

    // MARK: - Private Methods - UI Helpers

    /// Shows Lottie loading screen with the given text mode (animation only / single / rotating).
    /// Default is rotating timeline texts to match the create+generation flow's UX.
    /// Window-attached so it survives modal presentations without conflict.
    private func showLottieLoading(textMode: LottieLoadingTextMode = .defaultRotating) {
        TRPLottieLoadingVC.shared.showOnWindow(textMode: textMode)
    }

    /// Hides Lottie loading screen.
    /// - Parameter completion: Called after the loader is fully dismissed.
    private func hideLottieLoading(completion: (() -> Void)? = nil) {
        TRPLottieLoadingVC.shared.hideFromWindow(completion: completion)
    }

    private func showError(message: String) {
        guard let navigationController = navigationController else {
            // If no navigation controller, just close SDK
            closeSDK()
            return
        }

        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            // Close SDK after user taps OK
            self?.closeSDK()
        })

        navigationController.present(alert, animated: true)
    }

    private func closeSDK() {
        // Dismiss navigation controller and notify delegate
        navigationController?.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.timelineCoordinatorDidClose(self)
        }
    }

    // MARK: - Cleanup

    deinit {
        // Remove observers
        observeTimelineAllPlan?.allSegmentGenerated.removeObserver(self)
    }
}

// MARK: - TRPTimelineItineraryVCDelegate
extension TRPTimelineCoordinator: TRPTimelineItineraryVCDelegate {

    public func timelineItineraryFilterPressed(_ viewController: TRPTimelineItineraryVC) {
        // TODO: Implement filter functionality
    }

    public func timelineItineraryAddPlansPressed(_ viewController: TRPTimelineItineraryVC) {
        // TODO: Implement add plans functionality
        // This will likely open the AddPlanContainer flow
    }

    public func timelineItineraryDidSelectStep(_ viewController: TRPTimelineItineraryVC, step: TRPTimelineStep) {
        guard let poi = step.poi else { return }
        let detailVM = TimelinePoiDetailViewModel(poi: poi)
        let detailVC = TimelinePoiDetailViewController(viewModel: detailVM)
        viewController.navigationController?.pushViewController(detailVC, animated: true)
    }

    public func timelineItineraryDidSelectBookedActivity(_ viewController: TRPTimelineItineraryVC, segment: TRPTimelineSegment) {
        guard let activityId = segment.additionalData?.activityId else {
            return
        }
        TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityDetail(activityId: activityId)
    }

    public func timelineItineraryAddButtonPressed(_ viewController: TRPTimelineItineraryVC, atSectionIndex: Int) {
        // TODO: Open add plans flow for specific section
    }

    public func timelineItineraryChangeTimePressed(_ viewController: TRPTimelineItineraryVC, step: TRPTimelineStep) {
        // TODO: Open change time flow for the step
        // Example: openChangeTimeFlow(step: step)
    }

    public func timelineItineraryRemoveStepPressed(_ viewController: TRPTimelineItineraryVC, step: TRPTimelineStep) {
        // TODO: Remove step from timeline
        // Example: removeStep(step: step)
    }

    public func timelineItineraryDidRequestActivityReservation(_ viewController: TRPTimelineItineraryVC, activityId: String, date: Date) {
        // Delegate to SDK delegate to handle activity reservation
        TRPCoreKit.shared.delegate?.trpCoreKitDidRequestActivityReservation(activityId: activityId, date: date)
    }
}

// MARK: - TRPTimelineCustomNavigationBarDelegate
extension TRPTimelineCoordinator: TRPTimelineCustomNavigationBarDelegate {

    func customNavigationBarDidTapBack(_ navigationBar: TRPTimelineCustomNavigationBar) {
        timelineViewController?.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.timelineCoordinatorDidClose(self)
        }
    }
}
