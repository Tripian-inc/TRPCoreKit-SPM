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

import CoreLocation

public protocol AddPlanPOISelectionViewModelDelegate: AnyObject {
    func searchResultsDidUpdate()
    func placeDetailDidLoad(accommodation: TRPAccommodation)
    func searchDidFail(error: Error)
    func viewModel(showPreloader: Bool)
    func userLocationStatusDidUpdate(isInCity: Bool)
}

/// Represents a saved item that can be selected as starting point
public enum SavedItem {
    case bookedActivity(TRPTimelineSegment)
    case favouriteActivity(TRPSegmentFavoriteItem)

    var title: String {
        switch self {
        case .bookedActivity(let segment):
            return segment.title ?? segment.additionalData?.title ?? ""
        case .favouriteActivity(let item):
            return item.title
        }
    }

    var cityName: String? {
        switch self {
        case .bookedActivity(let segment):
            return segment.city?.name
        case .favouriteActivity(let item):
            return item.cityName
        }
    }

    var coordinate: TRPLocation? {
        switch self {
        case .bookedActivity(let segment):
            return segment.coordinate
        case .favouriteActivity(let item):
            return item.coordinate
        }
    }
}

public class AddPlanPOISelectionViewModel {

    // MARK: - Properties
    public weak var delegate: AddPlanPOISelectionViewModelDelegate?

    private let cityName: String?
    private let cityId: Int?
    private let cityCenterPOI: TRPPoi?
    private let bookedActivities: [TRPTimelineSegment]
    private let favouriteItems: [TRPSegmentFavoriteItem]
    private let cityCoordinate: TRPLocation?

    // Filtered items for selected city (combined booked + favourites)
    private var filteredSavedItems: [SavedItem] = []

    // User location status
    private(set) var isUserInCity: Bool = false

    // Google Places Search
    private var googleApiKey: String?
    private var boundarySW: TRPLocation?
    private var boundaryNE: TRPLocation?
    private(set) var searchResults: [TRPGooglePlace] = []
    private var searchWorkItem: DispatchWorkItem?

    // MARK: - Initialization
    public init(cityName: String?,
                cityId: Int? = nil,
                cityCenterPOI: TRPPoi?,
                bookedActivities: [TRPTimelineSegment],
                favouriteItems: [TRPSegmentFavoriteItem] = [],
                boundarySW: TRPLocation? = nil,
                boundaryNE: TRPLocation? = nil,
                cityCoordinate: TRPLocation? = nil) {
        self.cityName = cityName
        self.cityId = cityId
        self.cityCenterPOI = cityCenterPOI
        self.bookedActivities = bookedActivities
        self.favouriteItems = favouriteItems
        self.boundarySW = boundarySW
        self.boundaryNE = boundaryNE
        self.cityCoordinate = cityCoordinate ?? cityCenterPOI?.coordinate

        // Get Google API key
        if let key = TRPApiKeyController.getKey(TRPApiKeys.trpGooglePlace) {
            googleApiKey = key
        }

        // Filter activities by selected city
        filterItemsByCity()

        // Check user location
        checkUserLocationInCity()
    }

    private func filterItemsByCity() {
        var items: [SavedItem] = []

        // Filter booked activities by city
        for segment in bookedActivities {
            let matchesCity = matchesCityFilter(cityId: segment.city?.id, cityName: segment.city?.name)
            if matchesCity {
                items.append(.bookedActivity(segment))
            }
        }

        // Filter favourite items by city
        for item in favouriteItems {
            let matchesCity = matchesCityFilter(cityId: item.cityId, cityName: item.cityName)
            if matchesCity {
                items.append(.favouriteActivity(item))
            }
        }

        filteredSavedItems = items
    }

    private func matchesCityFilter(cityId itemCityId: Int?, cityName itemCityName: String?) -> Bool {
        // If no cityId or cityName provided for filter, show all
        guard self.cityId != nil || self.cityName != nil else {
            return true
        }

        // Filter by cityId if available
        if let filterCityId = self.cityId, let itemCityId = itemCityId {
            return filterCityId == itemCityId
        }

        // Fallback to city name matching
        if let filterCityName = self.cityName, let itemCityName = itemCityName {
            return filterCityName.lowercased() == itemCityName.lowercased()
        }

        return false
    }

    // MARK: - User Location Check
    private func checkUserLocationInCity() {
        guard let userLocation = TRPUserLocationController.shared.userLatestLocation else {
            isUserInCity = false
            return
        }

        // Check using city boundaries if available
        if let nw = boundaryNE, let es = boundarySW {
            var inLat = false
            var inLon = false

            if nw.lat > es.lat {
                inLat = nw.lat > userLocation.lat && userLocation.lat > es.lat
            } else {
                inLat = nw.lat < userLocation.lat && userLocation.lat < es.lat
            }

            if nw.lon > es.lon {
                inLon = nw.lon > userLocation.lon && userLocation.lon > es.lon
            } else {
                inLon = nw.lon < userLocation.lon && userLocation.lon < es.lon
            }

            isUserInCity = inLat && inLon
        } else if let cityCenter = cityCoordinate {
            // Fallback: Check distance from city center (50km radius)
            let userCLLocation = CLLocation(latitude: userLocation.lat, longitude: userLocation.lon)
            let cityCLLocation = CLLocation(latitude: cityCenter.lat, longitude: cityCenter.lon)
            let distance = userCLLocation.distance(from: cityCLLocation)
            isUserInCity = distance < 50000 // 50km
        } else {
            isUserInCity = false
        }

        delegate?.userLocationStatusDidUpdate(isInCity: isUserInCity)
    }

    public func refreshUserLocationStatus() {
        checkUserLocationInCity()
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

    // MARK: - Saved Items Methods (Booked Activities + Favourite Items)
    public func getSavedItemsCount() -> Int {
        return filteredSavedItems.count
    }

    public func getSavedItem(at index: Int) -> SavedItem? {
        guard index < filteredSavedItems.count else { return nil }
        return filteredSavedItems[index]
    }

    public func getSavedItems() -> [SavedItem] {
        return filteredSavedItems
    }

    public func hasSavedItems() -> Bool {
        return !filteredSavedItems.isEmpty
    }

    // Keep old methods for backward compatibility
    public func getBookedActivitiesCount() -> Int {
        return filteredSavedItems.count
    }

    public func getBookedActivity(at index: Int) -> TRPTimelineSegment? {
        guard index < filteredSavedItems.count else { return nil }
        if case .bookedActivity(let segment) = filteredSavedItems[index] {
            return segment
        }
        return nil
    }

    public func hasFilteredActivities() -> Bool {
        return !filteredSavedItems.isEmpty
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
