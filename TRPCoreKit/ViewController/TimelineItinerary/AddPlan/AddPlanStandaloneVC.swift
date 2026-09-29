//
//  AddPlanStandaloneVC.swift
//  TRPCoreKit
//
//  Copyright © 2026 Tripian Inc. All rights reserved.
//

import UIKit
import TRPRestKit

/// How the standalone add plan flow ended.
enum AddPlanStandaloneOutcome: Equatable {
    /// Nothing was added; the host's screen is back as it was.
    case closed
    /// Something was added, or the trip cannot be planned from the sheet; the timeline should
    /// open, on `day` when there is one.
    case openTimeline(day: Date?)
}

/// Shows only the add plan sheet of a trip over the host's screen. It is a transparent screen,
/// presented over full screen without animation, that fetches the timeline behind the window
/// loader, presents the sheet, creates what the user picks and, once it has removed itself,
/// reports the outcome through `onFinish`.
final class AddPlanStandaloneVC: UIViewController {

    var onFinish: ((AddPlanStandaloneOutcome) -> Void)?

    private let viewModel: TRPTimelineItineraryViewModel
    private var hasPresentedSheet = false
    private var isCreatingSmartRecommendation = false
    private var smartRecommendationDay: Date?
    private var hasAddedFromListing = false
    private var listingAddedDay: Date?
    private var isFinished = false

    /// - Parameter initialDay: Day the sheet starts on when the trip covers it.
    init(tripHash: String, initialDay: Date?) {
        viewModel = TRPTimelineItineraryViewModel(tripHash: tripHash)
        viewModel.preferredInitialDay = initialDay
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        overrideUserInterfaceStyle = .light
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        viewModel.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.loadInitialTimelineIfNeeded()
    }

    /// The sheet's close button and the listings' back buttons dismiss through this screen, so a
    /// dismissal of what it presents ends the flow unless a smart recommendation is being created.
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        guard presentedViewController != nil else {
            super.dismiss(animated: flag, completion: completion)
            return
        }
        super.dismiss(animated: flag) { [weak self] in
            completion?()
            guard let self = self, !self.isCreatingSmartRecommendation else { return }
            self.finishWithoutSmartRecommendation()
        }
    }

    private var outcomeWithoutSmartRecommendation: AddPlanStandaloneOutcome {
        hasAddedFromListing ? .openTimeline(day: listingAddedDay) : .closed
    }

    private func finishWithoutSmartRecommendation() {
        finish(outcomeWithoutSmartRecommendation)
    }

    /// Ends the flow once the sheet's own dismissal has finished, since removing this screen
    /// while that transition runs would be refused and leave it covering the host.
    private func finishAfterSheetCloses() {
        guard let transitionCoordinator = presentedViewController?.transitionCoordinator else {
            finishWithoutSmartRecommendation()
            return
        }
        transitionCoordinator.animate(alongsideTransition: nil) { [weak self] _ in
            self?.finishAfterSheetCloses()
        }
    }

    private func finish(_ outcome: AddPlanStandaloneOutcome) {
        guard !isFinished else { return }
        isFinished = true
        viewModel.delegate = nil
        guard let presenter = presentingViewController else {
            onFinish?(outcome)
            return
        }
        presenter.dismiss(animated: false) { [weak self] in
            self?.onFinish?(outcome)
        }
    }

    private func presentSheet() {
        hasPresentedSheet = true
        let containerVC = AddPlanFlowBuilder.makeContainer(viewModel: viewModel, delegate: self)
        presentVCWithDynamicHeight(containerVC)
        containerVC.presentationController?.delegate = self
    }

    private func recordListingAddition(on day: Date?) {
        hasAddedFromListing = true
        listingAddedDay = day ?? listingAddedDay
    }
}

// MARK: - TRPTimelineItineraryViewModelDelegate

extension AddPlanStandaloneVC: TRPTimelineItineraryViewModelDelegate {

    func timelineItineraryViewModel(didUpdateTimeline: Bool) {
        guard didUpdateTimeline, !isFinished else { return }
        if isCreatingSmartRecommendation {
            finish(.openTimeline(day: smartRecommendationDay))
        } else if !hasPresentedSheet {
            presentSheet()
        }
    }

    func timelineItineraryViewModel(noCitiesAvailable: Bool) {
        guard noCitiesAvailable else { return }
        finish(.openTimeline(day: nil))
    }

    func timelineItineraryViewModel(someCitiesUnavailable cityNames: [String]) {}

    func timelineItineraryViewModel(showLottieLoading: Bool, textMode: LottieLoadingTextMode) {
        if showLottieLoading {
            TRPLottieLoadingVC.shared.showOnWindow(textMode: textMode)
        } else {
            TRPLottieLoadingVC.shared.hideFromWindow()
        }
    }

    func viewModel(error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.finish(after: error)
        }
    }

    private func finish(after error: Error) {
        if let trpError = error as? TRPErrors, case .refreshTokenError = trpError {
            TRPCoreKit.shared.delegate?.trpCoreKitDidFailWithAuthError()
            finish(.closed)
            return
        }
        EvrAlertView.showAlert(contentText: error.localizedDescription, type: .error)
        finishWithoutSmartRecommendation()
    }
}

// MARK: - AddPlanContainerVCDelegate

extension AddPlanStandaloneVC: AddPlanContainerVCDelegate {

    func addPlanContainerDidComplete(_ viewController: AddPlanContainerVC, data: AddPlanData) {
        guard data.selectedMode == .smartRecommendations else {
            viewController.dismiss(animated: true) { [weak self] in
                self?.finishWithoutSmartRecommendation()
            }
            return
        }
        isCreatingSmartRecommendation = true
        smartRecommendationDay = data.selectedDay
        viewController.dismiss(animated: true) { [weak self] in
            self?.viewModel.createSmartRecommendationSegment(from: data)
        }
    }

    func addPlanContainerDidCancel(_ viewController: AddPlanContainerVC) {
        DispatchQueue.main.async { [weak self] in
            self?.finishAfterSheetCloses()
        }
    }

    func addPlanContainerShouldShowActivityListing(_ viewController: AddPlanContainerVC, data: AddPlanData) {
        let navController = AddPlanFlowBuilder.makeActivityListing(data: data, viewModel: viewModel) { [weak self] day in
            self?.recordListingAddition(on: day)
        }
        viewController.present(navController, animated: true)
    }

    func addPlanContainerShouldShowPOIListing(_ viewController: AddPlanContainerVC, data: AddPlanData, categoryType: POIListingCategoryType) {
        let navController = AddPlanFlowBuilder.makePOIListing(data: data, categoryType: categoryType, viewModel: viewModel) { [weak self] day in
            self?.recordListingAddition(on: day)
        }
        viewController.present(navController, animated: true)
    }

    func addPlanContainerSegmentCreated(_ viewController: AddPlanContainerVC, selectedDay: Date?) {
        recordListingAddition(on: selectedDay)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension AddPlanStandaloneVC: UIAdaptivePresentationControllerDelegate {

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        finishWithoutSmartRecommendation()
    }
}
