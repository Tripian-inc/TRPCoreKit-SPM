//
//  AddPlanPOISelectionViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 22.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit
import TRPRestKit

public protocol AddPlanPOISelectionViewModelDelegate: AnyObject {
    func searchResultsDidUpdate()
    func placeDetailDidLoad(accommodation: TRPAccommodation)
    func searchDidFail(error: Error)
    func viewModel(showPreloader: Bool)
}

public class AddPlanPOISelectionViewModel {

    // MARK: - Properties
    public weak var delegate: AddPlanPOISelectionViewModelDelegate?

    private let cityName: String?
    private let cityCenterPOI: TRPPoi?
    private let bookedActivities: [TRPTimelineSegment]

    // Google Places Search
    private var googleApiKey: String?
    private var boundarySW: TRPLocation?
    private var boundaryNE: TRPLocation?
    private(set) var searchResults: [TRPGooglePlace] = []
    private var searchWorkItem: DispatchWorkItem?

    // MARK: - Initialization
    public init(cityName: String?,
                cityCenterPOI: TRPPoi?,
                bookedActivities: [TRPTimelineSegment],
                boundarySW: TRPLocation? = nil,
                boundaryNE: TRPLocation? = nil) {
        self.cityName = cityName
        self.cityCenterPOI = cityCenterPOI
        self.bookedActivities = bookedActivities
        self.boundarySW = boundarySW
        self.boundaryNE = boundaryNE

        // Get Google API key
        if let key = TRPApiKeyController.getKey(TRPApiKeys.trpGooglePlace) {
            googleApiKey = key
        }
    }

    // MARK: - City Center Methods
    public func getCityName() -> String? {
        return cityName
    }

    public func getCityCenterPOI() -> TRPPoi? {
        return cityCenterPOI
    }

    public func getCityCenterLocation() -> TRPLocation? {
        return cityCenterPOI?.coordinate
    }

    public func getCityCenterDisplayName() -> String? {
        guard let city = cityName else { return nil }
        return "\(city) | \(AddPlanLocalizationKeys.localized(AddPlanLocalizationKeys.cityCenter))"
    }

    // MARK: - Booked Activities Methods
    public func getBookedActivitiesCount() -> Int {
        return bookedActivities.count
    }

    public func getBookedActivity(at index: Int) -> TRPTimelineSegment? {
        guard index < bookedActivities.count else { return nil }
        return bookedActivities[index]
    }

    public func getBookedActivities() -> [TRPTimelineSegment] {
        return bookedActivities
    }

    // MARK: - Google Places Search
    public func searchAddress(text: String) {
        // Cancel previous search
        searchWorkItem?.cancel()

        let searchText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !searchText.isEmpty else {
            clearSearchResults()
            return
        }

        guard let apiKey = googleApiKey else {
            return
        }

        // Debounce search by 650ms
        let workItem = DispatchWorkItem { [weak self] in
            self?.performSearch(text: searchText, apiKey: apiKey)
        }

        searchWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(650), execute: workItem)
    }

    private func performSearch(text: String, apiKey: String) {
        delegate?.viewModel(showPreloader: true)

        TRPRestKit().googleAutoComplete(key: apiKey,
                                        text: text,
                                        boundarySW: boundarySW,
                                        boundaryNE: boundaryNE) { [weak self] (data, error) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.delegate?.viewModel(showPreloader: false)

                if let error = error {
                    self.delegate?.searchDidFail(error: error)
                    return
                }

                if let places = data as? [TRPGooglePlace] {
                    self.searchResults = places
                    self.delegate?.searchResultsDidUpdate()
                }
            }
        }
    }

    public func searchPlace(withId id: String) {
        guard let apiKey = googleApiKey else { return }

        delegate?.viewModel(showPreloader: true)

        TRPRestKit().googlePlace(key: apiKey, id: id) { [weak self] (data, error) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.delegate?.viewModel(showPreloader: false)

                if let error = error {
                    self.delegate?.searchDidFail(error: error)
                    return
                }

                if let placeLocation = data as? TRPGooglePlaceLocation {
                    let accommodation = TRPAccommodation(
                        name: placeLocation.name ?? placeLocation.hotelAddress,
                        referanceId: placeLocation.id,
                        address: placeLocation.hotelAddress,
                        coordinate: placeLocation.location
                    )
                    self.delegate?.placeDetailDidLoad(accommodation: accommodation)
                }
            }
        }
    }

    public func clearSearchResults() {
        searchResults = []
        delegate?.searchResultsDidUpdate()
    }

    public func getSearchResultsCount() -> Int {
        return searchResults.count
    }

    public func getSearchResult(at index: Int) -> TRPGooglePlace? {
        guard index < searchResults.count else { return nil }
        return searchResults[index]
    }
}
