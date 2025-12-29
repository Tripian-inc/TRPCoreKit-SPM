//
//  TimelinePoiDetailViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 29.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation
import TRPFoundationKit
import TRPRestKit

public class TimelinePoiDetailViewModel {

    // MARK: - Properties
    public let poi: TRPPoi
    public let step: TRPTimelineStep

    // MARK: - Initialization
    public init(step: TRPTimelineStep) {
        self.step = step
        guard let poi = step.poi else {
            fatalError("TRPTimelineStep must have a POI")
        }
        self.poi = poi
    }

    // MARK: - Public Methods
    public func getImageUrls() -> [String] {
        guard let gallery = poi.gallery, !gallery.isEmpty else {
            // Return empty placeholder to show at least one image cell
            return [""]
        }

        let imageUrls = gallery.compactMap { image -> String? in
            guard let urlString = image?.url, !urlString.isEmpty else { return nil }
            // Resize image for better performance
            return urlString
        }

        // If no valid images, return empty placeholder
        return imageUrls.isEmpty ? [""] : imageUrls
    }

    public func getCityName() -> String {
        // Try to get city name from poi locations
        if let cityName = poi.locations.first?.name {
            return cityName
        }
        return ""
    }

    public func getRating() -> Float? {
        return poi.rating
    }

    public func getReviewCount() -> Int {
        return poi.ratingCount ?? 0
    }

    public func getDescription() -> String? {
        return poi.description
    }

    public func getPhone() -> String? {
        return poi.phone
    }

    public func getOpeningHours() -> String? {
        return poi.hours
    }

    public func getFormattedOpeningHours() -> String? {
        guard let hours = poi.hours, !hours.isEmpty else { return nil }

        // Parse complex opening hours format
        // Example: "Sun, Sat: 9:00 AM - 1:00 AM | Mon, Tue, Wed, Thu, Fri: 8:30 AM - 1:00 AM"
        let parsedHours = parseOpeningHours(hours)
        return parsedHours
    }

    private func parseOpeningHours(_ hoursString: String) -> String {
        // Day order
        let allDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let dayNames = [
            "Sun": "Sunday",
            "Mon": "Monday",
            "Tue": "Tuesday",
            "Wed": "Wednesday",
            "Thu": "Thursday",
            "Fri": "Friday",
            "Sat": "Saturday"
        ]

        // Initialize all days as closed
        let closedText = PoiDetailLocalizationKeys.localized(PoiDetailLocalizationKeys.closed)
        var dayHours: [String: String] = [:]
        allDays.forEach { dayHours[$0] = closedText }

        // Split by pipe (|) to get different day groups
        let groups = hoursString.components(separatedBy: "|")

        for group in groups {
            let trimmedGroup = group.trimmingCharacters(in: .whitespaces)

            // Split by colon to separate days from hours
            let parts = trimmedGroup.components(separatedBy: ":")
            guard parts.count >= 2 else { continue }

            let daysString = parts[0].trimmingCharacters(in: .whitespaces)
            let timeString = parts[1...].joined(separator: ":").trimmingCharacters(in: .whitespaces)

            // Parse days (can be comma-separated)
            let days = daysString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }

            // Assign time to each day
            for day in days {
                // Handle day ranges like "Mon-Fri"
                if day.contains("-") {
                    let rangeParts = day.components(separatedBy: "-")
                    if rangeParts.count == 2 {
                        let startDay = rangeParts[0].trimmingCharacters(in: .whitespaces)
                        let endDay = rangeParts[1].trimmingCharacters(in: .whitespaces)

                        if let startIndex = allDays.firstIndex(of: startDay),
                           let endIndex = allDays.firstIndex(of: endDay) {
                            for i in startIndex...endIndex {
                                dayHours[allDays[i]] = timeString
                            }
                        }
                    }
                } else {
                    // Single day
                    let normalizedDay = normalizeDay(day)
                    if allDays.contains(normalizedDay) {
                        dayHours[normalizedDay] = timeString
                    }
                }
            }
        }

        // Format output: each day on a new line
        var result: [String] = []
        for day in allDays {
            if let hours = dayHours[day] {
                // Use abbreviated day name
                result.append("\(day): \(hours)")
            }
        }

        return result.joined(separator: "\n")
    }

    private func normalizeDay(_ day: String) -> String {
        let normalized = day.trimmingCharacters(in: .whitespaces).capitalized

        // Map full day names to abbreviations
        let dayMap: [String: String] = [
            "Sunday": "Sun",
            "Monday": "Mon",
            "Tuesday": "Tue",
            "Wednesday": "Wed",
            "Thursday": "Thu",
            "Friday": "Fri",
            "Saturday": "Sat"
        ]

        return dayMap[normalized] ?? normalized
    }

    public func hasKeyData() -> Bool {
        return poi.phone != nil || poi.hours != nil
    }

    public func getAddress() -> String? {
        return poi.address
    }

    public func getCoordinate() -> TRPLocation? {
        return poi.coordinate
    }

    public func getPoiIcon() -> String? {
        return poi.icon
    }

    public func hasMeetingPoint() -> Bool {
        return poi.address != nil
    }

    public func hasFeatures() -> Bool {
        return !poi.tags.isEmpty
    }

    public func getFeatures() -> [String] {
        return poi.tags
    }

    public func hasProducts() -> Bool {
        guard let bookings = poi.bookings else { return false }

        // Check if any booking with provider ID 15 (Civitatis) has products
        return bookings.contains { booking in
//            guard booking.providerId == 15,
                  guard let products = booking.products,
                  !products.isEmpty else { return false }
            return true
        }
    }

    public func getProducts() -> [TRPBookingProduct] {
        guard let bookings = poi.bookings else { return [] }

        // Get products only from provider ID 15 (Civitatis)
        var civittatisProducts: [TRPBookingProduct] = []
        bookings.forEach { booking in
//            if booking.providerId == 15, let products = booking.products {
            if let products = booking.products {
                civittatisProducts.append(contentsOf: products)
            }
        }

        return civittatisProducts
    }
}
