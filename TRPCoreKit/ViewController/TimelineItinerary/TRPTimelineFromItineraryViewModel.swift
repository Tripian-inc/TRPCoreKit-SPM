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

    // City resolution
    private let cityRemoteApi: TRPCityRemoteApi

    // MARK: - Initialization
    public init(itineraryModel: TRPItineraryWithActivities,
                cityRemoteApi: TRPCityRemoteApi = TRPCityRemoteApi()) {
        self.itineraryModel = itineraryModel
        self.cityRemoteApi = cityRemoteApi
    }
    
    // MARK: - Public Methods

    /// Creates a timeline from the itinerary model
    /// Similar to createTrip() in CreateTripContainerViewModel
    public func createTimeline() {
        // Show loader
        delegate?.viewModel(showPreloader: true)

        // Debug: Log destination items
        Log.i("TRPTimelineFromItineraryViewModel: destinationItems count = \(itineraryModel.destinationItems.count)")
        for (index, item) in itineraryModel.destinationItems.enumerated() {
            Log.i("TRPTimelineFromItineraryViewModel: destinationItems[\(index)] - title: \(item.title), cityId: \(String(describing: item.cityId)), coordinate: \(item.coordinate)")
        }

        // Check for missing or invalid cityIds in destination items
        // cityId is invalid if it's nil, <= 0, or -1 (common placeholder value)
        let itemsWithoutCityId = itineraryModel.destinationItems.enumerated()
            .filter { $0.element.cityId == nil || ($0.element.cityId ?? 0) <= 0 }
            .map { (index: $0.offset, item: $0.element) }

        Log.i("TRPTimelineFromItineraryViewModel: itemsWithoutCityId count = \(itemsWithoutCityId.count)")

        if itemsWithoutCityId.isEmpty {
            // All have cityId, proceed directly
            Log.i("TRPTimelineFromItineraryViewModel: All items have cityId, proceeding directly")
            createTimelineInternal()
        } else {
            // Resolve cities first
            Log.i("TRPTimelineFromItineraryViewModel: Resolving \(itemsWithoutCityId.count) missing cityIds")
            resolveMissingCities(itemsWithoutCityId) { [weak self] in
                self?.createTimelineInternal()
            }
        }
    }

    // MARK: - City Resolution

    /// Resolves missing cityIds for destination items
    /// Uses API first, then falls back to local cache if API fails
    private func resolveMissingCities(_ items: [(index: Int, item: TRPSegmentDestinationItem)],
                                      completion: @escaping () -> Void) {
        let coordinates = items.map { parseCoordinate(from: $0.item.coordinate) }

        Log.i("TRPTimelineFromItineraryViewModel: Calling resolveCities API with \(coordinates.count) coordinates")
        for (index, coord) in coordinates.enumerated() {
            Log.i("TRPTimelineFromItineraryViewModel: coordinate[\(index)] = lat: \(coord.lat), lon: \(coord.lon)")
        }

        // Try API first (more accurate)
        cityRemoteApi.resolveCities(coordinates: coordinates) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let cityIds):
                Log.i("TRPTimelineFromItineraryViewModel: resolveCities API success - cityIds: \(cityIds)")
                // Update destination items with resolved cityIds
                self.updateDestinationItemsCityIds(items: items, cityIds: cityIds)
                completion()

            case .failure(let error):
                Log.e("TRPTimelineFromItineraryViewModel: resolveCities API failed - \(error.localizedDescription)")
                // Fallback: Use TRPCityCache (local Haversine distance calculation)
                Log.i("TRPTimelineFromItineraryViewModel: Using cache fallback")
                self.resolveCitiesFromCache(items: items)
                completion()
            }
        }
    }

    /// Fallback method to resolve cities from local cache using coordinate proximity
    private func resolveCitiesFromCache(items: [(index: Int, item: TRPSegmentDestinationItem)]) {
        for (index, item) in items {
            let coordinate = parseCoordinate(from: item.coordinate)
            if let city = TRPCityCache.shared.getCityByCoordinate(coordinate, maxDistanceKm: 100) {
                itineraryModel.destinationItems[index].cityId = city.id
            }
        }
    }

    /// Updates destination items with resolved cityIds from API response
    private func updateDestinationItemsCityIds(items: [(index: Int, item: TRPSegmentDestinationItem)],
                                               cityIds: [Int]) {
        for (i, (index, _)) in items.enumerated() {
            if i < cityIds.count {
                itineraryModel.destinationItems[index].cityId = cityIds[i]
            }
        }
    }

    /// Parses a coordinate string into TRPLocation
    /// - Parameter coordinateString: String in format "lat,lon" (e.g., "41.3851,2.1734")
    /// - Returns: TRPLocation with parsed coordinates, or (0,0) if parsing fails
    private func parseCoordinate(from coordinateString: String) -> TRPLocation {
        let parts = coordinateString.components(separatedBy: ",")
        guard parts.count >= 2,
              let lat = Double(parts[0].trimmingCharacters(in: .whitespaces)),
              let lon = Double(parts[1].trimmingCharacters(in: .whitespaces)) else {
            return TRPLocation(lat: 0, lon: 0)
        }
        return TRPLocation(lat: lat, lon: lon)
    }

    // MARK: - Timeline Creation

    /// Internal method to create timeline after city resolution
    private func createTimelineInternal() {
        // Convert itinerary to timeline profile
        let timelineProfile = itineraryModel.createTimelineProfileFromBookings()

        // Execute create timeline
        createTimelineUseCase?.executeCreateTimeline(profile: timelineProfile) { [weak self] result in
            guard let self = self else { return }
            self.timelineGenerationResult(result: result)
        }
    }

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
            
            TRPCoreKit.shared.delegate?.trpCoreKitDidCreateTimeline(tripHash: tripHash)
            
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

