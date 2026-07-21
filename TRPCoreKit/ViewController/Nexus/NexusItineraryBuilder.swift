//
//  NexusItineraryBuilder.swift
//  TRPCoreKit
//
//  Parses the Nexus `reservations` JSON into a TRPItineraryWithActivities so the
//  SDK can create a timeline via the standard create path. Mirrors Android's
//  ACSplashVM.buildItinerary:
//   - each reservation's detailURL carries startDate/endDate/destinationID/productID;
//   - destinationID → cityId via TripianCommonApi.getCityIdFromDestination, then the
//     city centre coordinate from TRPCityCache;
//   - one destination per unique city + one booked activity per reservation;
//   - the trip range starts at the EARLIEST start across reservations and ends at
//     the LATEST end/service date across reservations PLUS 5 days, so ancillary
//     services can be planned after the last booked reservation.
//
//  Activity coordinates are not resolved here (no single-product lookup), so booked
//  activities are marked `isNoLocation` and anchored to the city. Completion runs
//  on the main queue with nil when nothing resolvable was found.
//

import Foundation
import TRPFoundationKit

enum NexusItineraryBuilder {

    private struct Parsed {
        let destinationId: String?
        let startDate: String?
        let endDate: String?
        let productId: String?
        let reservation: NexusReservationDTO
    }

    static func build(reservationsJson: String?,
                      completion: @escaping (TRPItineraryWithActivities?) -> Void) {
        guard let json = reservationsJson, let data = json.data(using: .utf8) else {
            print("[NexusSDK] builder: no reservations json")
            DispatchQueue.main.async { completion(nil) }
            return
        }
        let reservations: [NexusReservationDTO]
        do {
            reservations = try JSONDecoder().decode([NexusReservationDTO].self, from: data)
        } catch {
            print("[NexusSDK] builder: decode FAILED \(error)")
            DispatchQueue.main.async { completion(nil) }
            return
        }
        print("[NexusSDK] builder: decoded \(reservations.count) reservations")
        if reservations.isEmpty {
            DispatchQueue.main.async { completion(nil) }
            return
        }

        let parsed: [Parsed] = reservations.map { r in
            let comps = URLComponents(string: r.detailURL ?? r.detailUrlRelative ?? "")
            let items = comps?.queryItems ?? []
            func q(_ name: String) -> String? { items.first(where: { $0.name == name })?.value }
            return Parsed(
                destinationId: q("destinationID") ?? q("destinationId"),
                startDate: q("startDate"),
                endDate: q("endDate"),
                productId: q("productID") ?? q("productId"),
                reservation: r
            )
        }

        // Make sure the city cache is warm so getCity(byId:) can resolve centres.
        TRPCityCache.shared.fetchCitiesIfNeeded { _ in
            let uniqueDestinations = Set(parsed.compactMap { $0.destinationId }.filter { !$0.isEmpty })
            print("[NexusSDK] builder: destinationIds=\(uniqueDestinations)")
            var cityIdByDestination: [String: Int] = [:]
            let group = DispatchGroup()

            for dest in uniqueDestinations {
                group.enter()
                TripianCommonApi.shared.getCityIdFromDestination(dest) { result in
                    switch result {
                    case .success(let cityId):
                        if cityId > 0 { cityIdByDestination[dest] = cityId }
                        print("[NexusSDK] builder: dest \(dest) -> cityId \(cityId) cached=\(TRPCityCache.shared.getCity(byId: cityId) != nil)")
                    case .failure(let error):
                        print("[NexusSDK] builder: dest \(dest) cityId FAILED \(error)")
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                let itinerary = assemble(parsed: parsed, cityIdByDestination: cityIdByDestination)
                print("[NexusSDK] builder: assembled itinerary=\(itinerary != nil)")
                completion(itinerary)
            }
        }
    }

    private static func assemble(parsed: [Parsed], cityIdByDestination: [String: Int]) -> TRPItineraryWithActivities? {
        var destinations: [Int: TRPSegmentDestinationItem] = [:]
        var orderedCityIds: [Int] = []
        var activities: [TRPSegmentActivityItem] = []
        var startDates: [String] = []
        var endDates: [String] = []

        for p in parsed {
            let serviceDate = p.reservation.date.flatMap { $0.count >= 10 ? String($0.prefix(10)) : nil }
            if let s = p.startDate ?? serviceDate ?? p.endDate { startDates.append(s) }
            if let e = p.endDate ?? serviceDate ?? p.startDate { endDates.append(e) }

            guard let dest = p.destinationId,
                  let cityId = cityIdByDestination[dest],
                  let city = TRPCityCache.shared.getCity(byId: cityId) else { continue }

            if destinations[cityId] == nil {
                destinations[cityId] = TRPSegmentDestinationItem(
                    title: city.name,
                    coordinate: "\(city.coordinate.lat),\(city.coordinate.lon)",
                    cityId: cityId,
                    dates: nil
                )
                orderedCityIds.append(cityId)
            }

            let start = reservationDatetime(p.reservation.date)
                ?? p.startDate.map { "\($0.prefix(10)) 09:00" }

            let activity = TRPSegmentActivityItem(
                activityId: p.productId,
                bookingId: p.reservation.locator ?? p.reservation.locatorAlias,
                title: p.reservation.title,
                imageUrl: p.reservation.nexusBookingInformation?.coverImageUrl,
                description: p.reservation.nexusBookingInformation?.description,
                startDatetime: start,
                endDatetime: start,
                coordinate: TRPLocation(lat: 0, lon: 0),
                cancellation: p.reservation.nexusBookingInformation?.cancellationPolicyDescription,
                adultCount: p.reservation.paxAdults ?? 1,
                childCount: (p.reservation.paxChildren ?? 0) + (p.reservation.paxBabies ?? 0),
                bookingUrl: p.reservation.detailURL,
                cityId: cityId,
                isNoLocation: true
            )
            activities.append(activity)
        }

        if destinations.isEmpty && activities.isEmpty { return nil }

        let start = startDates.min()
        let latestEnd = endDates.max() ?? start
        let end = addDays(to: latestEnd, days: 5) ?? latestEnd
        return TRPItineraryWithActivities(
            tripName: nil,
            startDatetime: toDatetime(start, "00:00"),
            endDatetime: toDatetime(end, "23:59"),
            uniqueId: "",
            tripianHash: nil,
            destinationItems: orderedCityIds.compactMap { destinations[$0] },
            favouriteItems: nil,
            tripItems: activities
        )
    }

    /// Normalize a "yyyy-MM-dd" date (or nil) into the SDK's "yyyy-MM-dd HH:mm".
    private static func toDatetime(_ date: String?, _ time: String) -> String {
        guard let d = date, !d.isEmpty else {
            return "\(today()) \(time)"
        }
        if d.count >= 16 && d.contains(" ") { return d }
        return "\(d.prefix(10)) \(time)"
    }

    /// Shifts a "yyyy-MM-dd" date string by `days`, preserving the format. Returns the input unchanged when it can't be parsed.
    private static func addDays(to date: String?, days: Int) -> String? {
        guard let d = date, d.count >= 10 else { return date }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        guard let parsed = formatter.date(from: String(d.prefix(10))),
              let shifted = calendar.date(byAdding: .day, value: days, to: parsed) else { return date }
        return formatter.string(from: shifted)
    }

    private static func today() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    /// Converts a reservation date — "2026-07-02T20:30:00" / "2026-07-02 20:30" /
    /// "2026-07-02" — into the SDK's "yyyy-MM-dd HH:mm". Nil when malformed.
    private static func reservationDatetime(_ raw: String?) -> String? {
        guard let s = raw?.trimmingCharacters(in: .whitespacesAndNewlines), s.count >= 10 else { return nil }
        let datePart = String(s.prefix(10))
        let chars = Array(datePart)
        guard chars[4] == "-", chars[7] == "-" else { return nil }
        var timePart = "09:00"
        if s.count >= 16 {
            let sep = Array(s)[10]
            if sep == "T" || sep == " " {
                let startIdx = s.index(s.startIndex, offsetBy: 11)
                let endIdx = s.index(s.startIndex, offsetBy: 16)
                timePart = String(s[startIdx..<endIdx])
            }
        }
        return "\(datePart) \(timePart)"
    }
}
