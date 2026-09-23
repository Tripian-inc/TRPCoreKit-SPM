//
//  NexusDateSelectionViewModel.swift
//  TRPCoreKit
//
//  Step 2 of the Nexus create-trip flow: holds the city chosen on the city
//  step and builds the TRPItineraryWithActivities (one destination + the picked
//  date range, no activities) that drives timeline creation via startWithItinerary.
//

import Foundation

final class NexusDateSelectionViewModel {

    let city: TRPCity
    var uniqueId: String?

    init(city: TRPCity, uniqueId: String?) {
        self.city = city
        self.uniqueId = uniqueId
    }

    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// Build the itinerary from the chosen city + range. `end` may equal `start`
    /// for a single-day trip.
    func buildItinerary(start: Date, end: Date) -> TRPItineraryWithActivities {
        let startStr = dayFormatter.string(from: start)
        let endStr = dayFormatter.string(from: end >= start ? end : start)
        let coordinate = "\(city.coordinate.lat),\(city.coordinate.lon)"

        let destination = TRPSegmentDestinationItem(
            title: city.name,
            coordinate: coordinate,
            cityId: city.id,
            dates: nil
        )

        return TRPItineraryWithActivities(
            tripName: nil,
            startDatetime: "\(startStr) 00:00",
            endDatetime: "\(endStr) 23:59",
            uniqueId: uniqueId ?? "",
            tripianHash: nil,
            destinationItems: [destination],
            favouriteItems: nil,
            tripItems: []
        )
    }
}
