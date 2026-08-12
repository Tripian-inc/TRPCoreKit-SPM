//
//  NexusMyPlansViewModel.swift
//  TRPCoreKit
//
//  Drives the Nexus "My Plans" list — the user's existing not-past timelines,
//  shown when the SDK opens with no reservations. Uses the existing
//  TRPUserTimelineUseCases.executeUpcomingTimeline (from-today timelines,
//  sorted by oldest start).
//

import Foundation

final class NexusMyPlansViewModel {

    weak var delegate: ViewModelDelegate?

    private let useCase = TRPUserTimelineUseCases()
    private(set) var trips: [TRPTimeline] = []

    var numberOfTrips: Int { trips.count }
    func trip(at index: Int) -> TRPTimeline { trips[index] }

    /// Deletes the trip and drops it from the list without a refetch, so the row
    /// disappears immediately.
    func deleteTrip(at index: Int) {
        guard index < trips.count else { return }
        let tripHash = trips[index].tripHash
        delegate?.viewModel(showLottie: .fullScreen, textMode: .defaultRotating)
        useCase.executeDeleteTimeline(tripHash: tripHash) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.delegate?.viewModel(hideLottie: .fullScreen)
                switch result {
                case .success:
                    self.trips.removeAll { $0.tripHash == tripHash }
                    self.delegate?.viewModel(dataLoaded: true)
                case .failure(let error):
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }

    func loadTrips() {
        delegate?.viewModel(showLottie: .fullScreen, textMode: .defaultRotating)
        useCase.executeUpcomingTimeline { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.delegate?.viewModel(hideLottie: .fullScreen)
                switch result {
                case .success(let trips):
                    // Already filtered (from today) and sorted by oldest start.
                    self.trips = trips
                    self.delegate?.viewModel(dataLoaded: true)
                case .failure(let error):
                    self.delegate?.viewModel(error: error)
                }
            }
        }
    }
}
