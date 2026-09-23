//
//  NexusCitySelectionViewModel.swift
//  TRPCoreKit
//
//  Step 1 of the Nexus create-trip flow: pick ONE destination city. Loads the
//  cached city list (prefetching if cold), exposes the popular subset for the
//  "Top Destinations" row, supports name search and single selection.
//

import Foundation

final class NexusCitySelectionViewModel {

    weak var delegate: ViewModelDelegate?

    private var allCities: [TRPCity] = []
    private(set) var filteredCities: [TRPCity] = []
    private(set) var popularCities: [TRPCity] = []
    private(set) var selectedCity: TRPCity?

    var numberOfCities: Int { filteredCities.count }
    func city(at index: Int) -> TRPCity { filteredCities[index] }

    func loadCities() {
        if TRPCityCache.shared.isCacheReady() {
            apply(TRPCityCache.shared.getAllCities())
        } else {
            delegate?.viewModel(showLottie: .fullScreen, textMode: .defaultRotating)
            TRPCityCache.shared.fetchCitiesIfNeeded { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.delegate?.viewModel(hideLottie: .fullScreen)
                    self.apply(TRPCityCache.shared.getAllCities())
                }
            }
        }
    }

    private func apply(_ cities: [TRPCity]) {
        allCities = cities.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        filteredCities = allCities
        popularCities = allCities.filter { $0.isPopular }
        delegate?.viewModel(dataLoaded: true)
    }

    func search(_ query: String) {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        filteredCities = q.isEmpty ? allCities : allCities.filter { $0.name.lowercased().contains(q) }
        delegate?.viewModel(dataLoaded: true)
    }

    /// Single selection — replaces any previous one.
    func select(_ city: TRPCity) {
        selectedCity = city
    }

    func isSelected(_ city: TRPCity) -> Bool {
        selectedCity?.id == city.id
    }
}
