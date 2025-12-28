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
        print("📝 [TRPTimelineCoordinator] Creating new timeline with profile")

        // Store the profile to merge segments later
        self.originalProfile = profile

        createTimeline(with: profile)
    }

    /// Start timeline flow with existing trip hash (fetch existing timeline)
    /// This will fetch the timeline and display it immediately
    /// - Parameter tripHash: The trip hash for the existing timeline
    public func start(tripHash: String) {
        print("🔍 [TRPTimelineCoordinator] Fetching existing timeline with hash: \(tripHash)")

        self.currentTripHash = tripHash
        fetchTimeline(tripHash: tripHash)
    }

    /// Start with default implementation (for protocol conformance)
    public func start() {
        print("⚠️ [TRPTimelineCoordinator] start() called without parameters. Use start(with:) or start(tripHash:) instead.")
    }

    // MARK: - Private Methods - Timeline Creation Flow

    private func createTimeline(with profile: TRPTimelineProfile) {
        // Show loading indicator
        showLoadingIndicator(message: "Creating your itinerary...")

        createTimelineUseCase?.executeCreateTimeline(profile: profile) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let timeline):
                    print("✅ [TRPTimelineCoordinator] Timeline created successfully")
                    self.currentTripHash = timeline.tripHash
                    self.checkTimelineGenerationStatus(tripHash: timeline.tripHash)

                case .failure(let error):
                    print("❌ [TRPTimelineCoordinator] Timeline creation failed: \(error.localizedDescription)")
                    self.hideLoadingIndicator()
                    self.showError(message: "Failed to create timeline. Please try again.")
                }
            }
        }
    }

    private func checkTimelineGenerationStatus(tripHash: String) {
        // Show generating message
        showLoadingIndicator(message: "Generating your itinerary...")

        // Setup observer for all segments generated
        observeTimelineAllPlan?.allSegmentGenerated.addObserver(self) { [weak self] isGenerated in
            guard let self = self else { return }

            self.tryCount += 1

            if !isGenerated {
                if self.tryCount > self.maxTryCount {
                    DispatchQueue.main.async {
                        self.hideLoadingIndicator()
                        self.showError(message: TRPLanguagesController.shared.getLanguageValue(for: "trips.myTrips.localExperiences.tourDetails.bookingStatus.rejected.description"))
                    }
                }
                return
            }

            // All segments generation completed
            DispatchQueue.main.async {
                self.hideLoadingIndicator()

                // Notify delegate about timeline creation
                TRPCoreKit.shared.delegate?.trpCoreKitDidCreateTimeline(tripHash: tripHash)

                self.openTimelineViewControllerWithHash(tripHash: tripHash)
            }
        }

        // Start fetching and polling
        fetchTimelineAllPlan?.executeFetchTimelineCheckAllPlanGenerate(tripHash: tripHash, completion: nil)
    }

    // MARK: - Private Methods - Timeline Fetch Flow

    private func fetchTimeline(tripHash: String) {
        // Show loading indicator
        showLoadingIndicator(message: "Loading your itinerary...")

        timelineRepository.fetchTimeline(tripHash: tripHash) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.hideLoadingIndicator()

                switch result {
                case .success(let timeline):
                    print("✅ [TRPTimelineCoordinator] Timeline fetched successfully")
                    self.openTimelineViewController(with: timeline)

                case .failure(let error):
                    print("❌ [TRPTimelineCoordinator] Timeline fetch failed: \(error.localizedDescription)")
                    self.showError(message: "Failed to load timeline. Please try again.")
                }
            }
        }
    }

    // MARK: - Private Methods - View Controllers

    private func openTimelineViewController(with timeline: TRPTimeline) {
        print("\n🎬 [TRPTimelineCoordinator] openTimelineViewController called")
        print("   - Timeline has \(timeline.segments?.count ?? 0) segments")
        print("   - Timeline has \(timeline.plans?.count ?? 0) plans")
        print("   - Original profile is \(originalProfile == nil ? "nil" : "not nil")")

        // Merge segments and favourites from original profile if available
        var updatedTimeline = timeline

        if let profile = originalProfile {
            print("🔄 [TRPTimelineCoordinator] Merging segments and favourites from original profile")
            print("   - Profile has \(profile.segments.count) segments")

            // Merge segments from profile (segments is non-optional array)
            if !profile.segments.isEmpty {
                updatedTimeline.segments = profile.segments
                print("   ✅ Added \(profile.segments.count) segments from profile")
            } else {
                print("   ⚠️ Profile segments array is empty")
            }

            // Merge favourite items from profile (favouriteItems is optional)
            if let favouriteItems = profile.favouriteItems, !favouriteItems.isEmpty {
                updatedTimeline.favouriteItems = favouriteItems
                print("   ✅ Added \(favouriteItems.count) favourite items from profile")
            }
        } else {
            print("⚠️ [TRPTimelineCoordinator] No original profile to merge - segments will not be added")
        }

        print("   - Updated timeline has \(updatedTimeline.segments?.count ?? 0) segments")

        let viewModel = TRPTimelineItineraryViewModel(timeline: updatedTimeline)
        let viewController = TRPTimelineItineraryVC(viewModel: viewModel)
        viewController.delegate = self

        self.timelineViewController = viewController

        // Present modally with full screen
        let navController = UINavigationController(rootViewController: viewController)
        navController.modalPresentationStyle = .fullScreen

        navigationController?.present(navController, animated: true)
    }

    private func openTimelineViewControllerWithHash(tripHash: String) {
        // Fetch timeline and open view
        timelineRepository.fetchTimeline(tripHash: tripHash) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let timeline):
                    print("✅ [TRPTimelineCoordinator] Timeline fetched for display")
                    self.openTimelineViewController(with: timeline)

                case .failure(let error):
                    print("❌ [TRPTimelineCoordinator] Failed to fetch timeline for display: \(error.localizedDescription)")
                    self.showError(message: "Failed to load timeline. Please try again.")
                }
            }
        }
    }

    // MARK: - Private Methods - UI Helpers

    private var loadingViewController: UIViewController?

    private func showLoadingIndicator(message: String) {
        guard let navigationController = navigationController else { return }

        let loadingVC = UIViewController()
        loadingVC.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 12
        loadingVC.view.addSubview(containerView)

        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()
        containerView.addSubview(activityIndicator)

        let messageLabel = UILabel()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.text = message
        messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        messageLabel.textColor = .darkGray
        messageLabel.textAlignment = .center
        containerView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: loadingVC.view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: loadingVC.view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 250),
            containerView.heightAnchor.constraint(equalToConstant: 120),

            activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),

            messageLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])

        loadingVC.modalPresentationStyle = .overFullScreen
        loadingVC.modalTransitionStyle = .crossDissolve

        navigationController.present(loadingVC, animated: true)
        loadingViewController = loadingVC
    }

    private func hideLoadingIndicator() {
        loadingViewController?.dismiss(animated: true)
        loadingViewController = nil
    }

    private func showError(message: String) {
        guard let navigationController = navigationController else { return }

        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default))

        navigationController.present(alert, animated: true)
    }

    // MARK: - Cleanup

    deinit {
        // Remove observers
        observeTimelineAllPlan?.allSegmentGenerated.removeObserver(self)
        print("🧹 [TRPTimelineCoordinator] Deallocated")
    }
}

// MARK: - TRPTimelineItineraryVCDelegate
extension TRPTimelineCoordinator: TRPTimelineItineraryVCDelegate {

    public func timelineItineraryFilterPressed(_ viewController: TRPTimelineItineraryVC) {
        print("🔍 [TRPTimelineCoordinator] Filter pressed")
        // TODO: Implement filter functionality
    }

    public func timelineItineraryAddPlansPressed(_ viewController: TRPTimelineItineraryVC) {
        print("➕ [TRPTimelineCoordinator] Add plans pressed")
        // TODO: Implement add plans functionality
        // This will likely open the AddPlanContainer flow
    }

    public func timelineItineraryDidSelectStep(_ viewController: TRPTimelineItineraryVC, step: TRPTimelineStep) {
        guard let poi = step.poi else { return }
        print("📍 [TRPTimelineCoordinator] Selected POI: \(poi.name)")

        // TODO: Open POI detail view
        // Example: openPoiDetail(poi: poi, step: step)
    }

    public func timelineItineraryDidSelectBookedActivity(_ viewController: TRPTimelineItineraryVC, segment: TRPTimelineSegment) {
        print("🎫 [TRPTimelineCoordinator] Selected booked activity: \(segment.title ?? "Unknown")")

        // TODO: Open booked activity detail view
    }

    public func timelineItineraryAddButtonPressed(_ viewController: TRPTimelineItineraryVC, atSectionIndex: Int) {
        print("➕ [TRPTimelineCoordinator] Add button pressed at section: \(atSectionIndex)")

        // TODO: Open add plans flow for specific section
    }

    public func timelineItineraryThumbsUpPressed(_ viewController: TRPTimelineItineraryVC, step: TRPTimelineStep) {
        guard let poi = step.poi else { return }
        print("👍 [TRPTimelineCoordinator] Thumbs up for: \(poi.name)")

        // TODO: Send thumbs up reaction to API
        // Example: sendReaction(step: step, type: .thumbsUp)
    }

    public func timelineItineraryThumbsDownPressed(_ viewController: TRPTimelineItineraryVC, step: TRPTimelineStep) {
        guard let poi = step.poi else { return }
        print("👎 [TRPTimelineCoordinator] Thumbs down for: \(poi.name)")

        // TODO: Send thumbs down reaction to API and possibly show alternatives
        // Example: sendReaction(step: step, type: .thumbsDown)
    }
}

// MARK: - TRPTimelineCustomNavigationBarDelegate
extension TRPTimelineCoordinator: TRPTimelineCustomNavigationBarDelegate {

    func customNavigationBarDidTapBack(_ navigationBar: TRPTimelineCustomNavigationBar) {
        print("⬅️ [TRPTimelineCoordinator] Back button tapped")

        timelineViewController?.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.timelineCoordinatorDidClose(self)
        }
    }
}
