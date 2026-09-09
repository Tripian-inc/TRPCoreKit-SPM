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
    func noCitiesAvailable()
    func someCitiesUnavailable(cityNames: [String])
}

/// Creates a timeline from TRPItineraryWithActivities (analogous to CreateTripContainerViewModel).
public class TRPTimelineFromItineraryViewModel {

    // MARK: - Properties
    public weak var delegate: TRPTimelineFromItineraryViewModelDelegate?

    public var createTimelineUseCase: CreateTimelineUseCases?
    public var observeTimelineAllPlan: ObserveTimelineCheckAllPlanUseCase?
    public var fetchTimelineAllPlan: FetchTimelineCheckAllPlanUseCase?

    private var itineraryModel: TRPItineraryWithActivities
    private var tryCount = 0

    private let cityRemoteApi: TRPCityRemoteApi

    // MARK: - Initialization
    public init(itineraryModel: TRPItineraryWithActivities,
                cityRemoteApi: TRPCityRemoteApi = TRPCityRemoteApi()) {
        self.itineraryModel = itineraryModel
        self.cityRemoteApi = cityRemoteApi
    }
    
    // MARK: - Public Methods

    public func createTimeline() {
        delegate?.viewModel(showPreloader: true)

        Log.i("TRPTimelineFromItineraryViewModel: destinationItems count = \(itineraryModel.destinationItems.count)")
        for (index, item) in itineraryModel.destinationItems.enumerated() {
            Log.i("TRPTimelineFromItineraryViewModel: destinationItems[\(index)] - title: \(item.title), cityId: \(String(describing: item.cityId)), coordinate: \(item.coordinate)")
        }

        let allItems = itineraryModel.destinationItems.enumerated()
            .map { (index: $0.offset, item: $0.element) }

        Log.i("TRPTimelineFromItineraryViewModel: Resolving ALL \(allItems.count) destination items")

        if allItems.isEmpty {
            Log.i("TRPTimelineFromItineraryViewModel: No destination items")
            createTimelineInternal()
        } else {
            resolveAllCities(allItems) { [weak self] in
                guard let self = self else { return }

                Log.i("TRPTimelineFromItineraryViewModel: After city resolution - checking destinationItems:")
                for (index, item) in self.itineraryModel.destinationItems.enumerated() {
                    Log.i("TRPTimelineFromItineraryViewModel: FINAL destinationItems[\(index)] - title: \(item.title), cityId: \(item.cityId ?? -999)")
                }

                let invalidItems = self.itineraryModel.destinationItems.filter { item in
                    guard let cityId = item.cityId else { return true }
                    return cityId <= 0
                }

                let validItems = self.itineraryModel.destinationItems.filter { item in
                    guard let cityId = item.cityId else { return false }
                    return cityId > 0
                }

                Log.i("TRPTimelineFromItineraryViewModel: validItems count = \(validItems.count), invalidItems count = \(invalidItems.count)")

                // All cities invalid → show empty state
                if validItems.isEmpty {
                    Log.w("TRPTimelineFromItineraryViewModel: All destination cities are invalid - showing no city state")
                    DispatchQueue.main.async {
                        self.delegate?.viewModel(showPreloader: false)
                        self.delegate?.noCitiesAvailable()
                    }
                    return
                }

                // Some cities invalid → show alert but continue with valid ones in parallel
                if !invalidItems.isEmpty {
                    let unavailableCityNames = invalidItems.map { $0.title }
                    Log.i("TRPTimelineFromItineraryViewModel: Some cities unavailable: \(unavailableCityNames.joined(separator: ", "))")

                    self.itineraryModel.destinationItems = validItems

                    DispatchQueue.main.async {
                        self.delegate?.someCitiesUnavailable(cityNames: unavailableCityNames)
                    }

                    Log.i("TRPTimelineFromItineraryViewModel: Starting timeline operations while showing alert - \(validItems.count) valid cities")
                    self.createTimelineInternal()
                    return
                }

                Log.i("TRPTimelineFromItineraryViewModel: All cities valid - proceeding with timeline creation")
                self.createTimelineInternal()
            }
        }
    }

    // MARK: - City Resolution

    /// Resolves cityIds for all destination items via API, falling back to local cache on failure.
    private func resolveAllCities(_ items: [(index: Int, item: TRPSegmentDestinationItem)],
                                  completion: @escaping () -> Void) {
        let coordinates = items.map { parseCoordinate(from: $0.item.coordinate) }

        Log.i("TRPTimelineFromItineraryViewModel: Calling resolveCities API with \(coordinates.count) coordinates")
        for (index, coord) in coordinates.enumerated() {
            let item = items[index].item
            Log.i("TRPTimelineFromItineraryViewModel: coordinate[\(index)] = lat: \(coord.lat), lon: \(coord.lon), currentCityId: \(item.cityId ?? -1)")
        }

        cityRemoteApi.resolveCities(coordinates: coordinates) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let cityIds):
                Log.i("TRPTimelineFromItineraryViewModel: resolveCities API success - cityIds: \(cityIds)")
                self.updateAllDestinationItemsCityIds(items: items, cityIds: cityIds)
                completion()

            case .failure(let error):
                Log.e("TRPTimelineFromItineraryViewModel: resolveCities API failed - \(error.localizedDescription)")
                Log.i("TRPTimelineFromItineraryViewModel: Using cache fallback")
                self.resolveCitiesFromCache(items: items)
                completion()
            }
        }
    }

    /// Fallback when API fails: Haversine distance to nearest cached city within 100km.
    private func resolveCitiesFromCache(items: [(index: Int, item: TRPSegmentDestinationItem)]) {
        Log.w("TRPTimelineFromItineraryViewModel: resolveCitiesFromCache - API failed, trying cache")
        for (index, item) in items {
            let coordinate = parseCoordinate(from: item.coordinate)
            Log.i("TRPTimelineFromItineraryViewModel: Cache check for destinationItems[\(index)] - coordinate: \(coordinate.lat), \(coordinate.lon)")

            if let city = TRPCityCache.shared.getCityByCoordinate(coordinate, maxDistanceKm: 100) {
                itineraryModel.destinationItems[index].cityId = city.id
                Log.i("TRPTimelineFromItineraryViewModel: Cache found city for destinationItems[\(index)] - cityId: \(city.id), name: \(city.name)")
            } else {
                itineraryModel.destinationItems[index].cityId = 0
                Log.w("TRPTimelineFromItineraryViewModel: Cache could not find city for destinationItems[\(index)] - setting cityId to 0")
            }
        }
    }

    private func updateAllDestinationItemsCityIds(items: [(index: Int, item: TRPSegmentDestinationItem)],
                                                  cityIds: [Int]) {
        Log.i("TRPTimelineFromItineraryViewModel: updateAllDestinationItemsCityIds - cityIds from API: \(cityIds)")
        Log.i("TRPTimelineFromItineraryViewModel: updateAllDestinationItemsCityIds - items count: \(items.count)")

        for (i, (index, _)) in items.enumerated() {
            let oldCityId = itineraryModel.destinationItems[index].cityId
            if i < cityIds.count && cityIds[i] > 0 {
                itineraryModel.destinationItems[index].cityId = cityIds[i]
                Log.i("TRPTimelineFromItineraryViewModel: Set destinationItems[\(index)].cityId = \(cityIds[i]) (was: \(oldCityId ?? -999))")
            } else {
                itineraryModel.destinationItems[index].cityId = 0
                Log.w("TRPTimelineFromItineraryViewModel: City not supported for destinationItems[\(index)] - API returned \(i < cityIds.count ? cityIds[i] : -999), setting to 0 (was: \(oldCityId ?? -999))")
            }
            let newCityId = itineraryModel.destinationItems[index].cityId
            Log.i("TRPTimelineFromItineraryViewModel: VERIFY destinationItems[\(index)].cityId is now: \(newCityId ?? -999)")
        }
    }

    /// Parses a "lat,lon" string into TRPLocation, or (0,0) if parsing fails.
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

    private func createTimelineInternal() {
        let timelineProfile = itineraryModel.createTimelineProfileFromBookings()

        createTimelineUseCase?.executeCreateTimeline(profile: timelineProfile) { [weak self] result in
            guard let self = self else { return }
            self.timelineGenerationResult(result: result)
        }
    }

    private func timelineGenerationResult(result: Result<TRPTimeline, Error>) {
        switch result {
        case .success(let timeline):
            let tripHash = timeline.tripHash

            checkTimelineIsGenerated(tripHash: tripHash, timeline: timeline)

        case .failure(let error):
            delegate?.viewModel(showPreloader: false)
            delegate?.viewModel(error: error)
        }
    }
    
    private func checkTimelineIsGenerated(tripHash: String, timeline: TRPTimeline) {

        observeTimelineAllPlan?.firstSegmentGenerated.addObserver(self, observer: { [weak self] status in
            guard let self = self else { return }
            self.tryCount += 1

            if !status {
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

            if let updatedTimeline = self.observeTimelineAllPlan?.timeline.value {
                self.delegate?.viewModel(showPreloader: false)
                self.delegate?.timelineGenerated(timeline: updatedTimeline)
            } else {
                self.delegate?.viewModel(showPreloader: false)
                self.delegate?.timelineGenerated(timeline: timeline)
            }
        })

        fetchTimelineAllPlan?.executeFetchTimelineCheckAllPlanGenerate(tripHash: tripHash, completion: nil)
    }
}

