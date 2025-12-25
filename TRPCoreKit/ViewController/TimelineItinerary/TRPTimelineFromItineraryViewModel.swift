//
//  TRPTimelineFromItineraryViewModel.swift
//  TRPCoreKit
//
//  Created by AI Assistant on Dec 2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit

public protocol TRPTimelineFromItineraryViewModelDelegate: ViewModelDelegate {
    func timelineGenerated(timeline: TRPTimeline)
}

/// View model responsible for creating a timeline from TRPItineraryWithActivities
/// Similar to CreateTripContainerViewModel but for timeline creation
public class TRPTimelineFromItineraryViewModel {
    
    // MARK: - Properties
    public weak var delegate: TRPTimelineFromItineraryViewModelDelegate?
    
    // Use cases
    public var createTimelineUseCase: CreateTimelineUseCases?
    public var observeTimelineAllPlan: ObserveTimelineCheckAllPlanUseCase?
    public var fetchTimelineAllPlan: FetchTimelineCheckAllPlanUseCase?
    
    private var itineraryModel: TRPItineraryWithActivities
    private var tryCount = 0
    
    // MARK: - Initialization
    public init(itineraryModel: TRPItineraryWithActivities) {
        self.itineraryModel = itineraryModel
    }
    
    // MARK: - Public Methods
    
    /// Creates a timeline from the itinerary model
    /// Similar to createTrip() in CreateTripContainerViewModel
    public func createTimeline() {
        // Convert itinerary to timeline profile
        let timelineProfile = itineraryModel.createTimelineProfileFromBookings()
        
        // Show loader
        delegate?.viewModel(showPreloader: true)
        
        // Execute create timeline
        createTimelineUseCase?.executeCreateTimeline(profile: timelineProfile) { [weak self] result in
            guard let self = self else { return }
            self.timelineGenerationResult(result: result)
        }
    }
    
    // MARK: - Private Methods
    
    /// Handles the result of timeline creation
    /// Similar to tripGenerationResult() in CreateTripContainerViewModel
    private func timelineGenerationResult(result: Result<TRPTimeline, Error>) {
        switch result {
        case .success(let timeline):
            // Get the trip hash from the timeline response
            let tripHash = timeline.tripHash
            
            // Check if timeline is generated (similar to checkTripIsGenerated)
            checkTimelineIsGenerated(tripHash: tripHash, timeline: timeline)
            
        case .failure(let error):
            print("[Error] Timeline creation failed: \(error.localizedDescription)")
            delegate?.viewModel(showPreloader: false)
            delegate?.viewModel(error: error)
        }
    }
    
    /// Checks if timeline is generated and notifies delegate when ready
    /// Similar to checkTripIsGenerated() in CreateTripContainerViewModel
    private func checkTimelineIsGenerated(tripHash: String, timeline: TRPTimeline) {
        
        observeTimelineAllPlan?.firstSegmentGenerated.addObserver(self, observer: { [weak self] status in
            guard let self = self else { return }
            self.tryCount += 1
            
            if !status {
                // If not generated and exceeded retry limit
                if self.tryCount > 8 {
                    self.delegate?.viewModel(showPreloader: false)
                    let error = GeneralError.customMessage(
                        TRPLanguagesController.shared.getLanguageValue(
                            for: "trips.myTrips.localExperiences.tourDetails.bookingStatus.rejected.description"
                        )
                    )
                    self.delegate?.viewModel(error: error)
                }
                return
            }
            
            // Timeline is generated successfully
            // Get the updated timeline from the observer (contains generated plans)
            if let updatedTimeline = self.observeTimelineAllPlan?.timeline.value {
                self.delegate?.viewModel(showPreloader: false)
                self.delegate?.timelineGenerated(timeline: updatedTimeline)
            } else {
                // Fallback to original timeline if observer doesn't have it
                self.delegate?.viewModel(showPreloader: false)
                self.delegate?.timelineGenerated(timeline: timeline)
            }
        })
        
        // Start fetching and checking timeline generation status
        fetchTimelineAllPlan?.executeFetchTimelineCheckAllPlanGenerate(tripHash: tripHash, completion: nil)
    }
}

