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

    // MARK: - Initialization
    public init(poi: TRPPoi) {
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
        // Standard English day abbreviations (order: Sunday first)
        let standardDayAbbrs = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        // Get localized day names from languages service
        let localizedDays = getLocalizedDayNames()

        // Initialize all days as closed
        let closedText = PoiDetailLocalizationKeys.localized(PoiDetailLocalizationKeys.closed)
        var dayHours: [Int: String] = [:] // Use day index (0=Sun, 1=Mon, etc.)
        for i in 0..<7 {
            dayHours[i] = closedText
        }

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
                // Handle day ranges like "Mon-Fri" or "Lun-Vie"
                if day.contains("-") {
                    let rangeParts = day.components(separatedBy: "-")
                    if rangeParts.count == 2 {
                        let startDay = rangeParts[0].trimmingCharacters(in: .whitespaces)
                        let endDay = rangeParts[1].trimmingCharacters(in: .whitespaces)

                        if let startIndex = getDayIndex(startDay, localizedDays: localizedDays),
                           let endIndex = getDayIndex(endDay, localizedDays: localizedDays) {
                            // Handle wrap-around (e.g., Fri-Mon)
                            if startIndex <= endIndex {
                                for i in startIndex...endIndex {
                                    dayHours[i] = timeString
                                }
                            } else {
                                // Wrap around: startIndex to Saturday, then Sunday to endIndex
                                for i in startIndex..<7 {
                                    dayHours[i] = timeString
                                }
                                for i in 0...endIndex {
                                    dayHours[i] = timeString
                                }
                            }
                        }
                    }
                } else {
                    // Single day
                    if let dayIndex = getDayIndex(day, localizedDays: localizedDays) {
                        dayHours[dayIndex] = timeString
                    }
                }
            }
        }

        // Format output: each day on a new line using standard abbreviations
        var result: [String] = []
        for (index, abbr) in standardDayAbbrs.enumerated() {
            if let hours = dayHours[index] {
                result.append("\(abbr): \(hours)")
            }
        }

        return result.joined(separator: "\n")
    }

    /// Get localized day names from languages service
    private func getLocalizedDayNames() -> [[String]] {
        // Each inner array contains variations of the day name (full, abbreviated, localized)
        // Index 0 = Sunday, 1 = Monday, ..., 6 = Saturday
        var localizedDays: [[String]] = []

        let dayKeys = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        let englishFull = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let englishAbbr = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        for i in 0..<7 {
            var variations: [String] = []

            // Add English variations
            variations.append(englishFull[i])
            variations.append(englishAbbr[i])
            variations.append(englishFull[i].lowercased())
            variations.append(englishAbbr[i].lowercased())

            // Add localized variation from languages service
            let localizedDay = TRPLanguagesController.shared.getLanguageValue(for: dayKeys[i])
            if !localizedDay.isEmpty && localizedDay != dayKeys[i] {
                variations.append(localizedDay)
                variations.append(localizedDay.lowercased())
                variations.append(localizedDay.capitalized)
                // Also add first 3 characters as potential abbreviation
                if localizedDay.count >= 3 {
                    let abbr = String(localizedDay.prefix(3))
                    variations.append(abbr)
                    variations.append(abbr.lowercased())
                    variations.append(abbr.capitalized)
                }
            }

            localizedDays.append(variations)
        }

        return localizedDays
    }

    /// Get day index (0-6) from day string, checking both English and localized names
    private func getDayIndex(_ dayString: String, localizedDays: [[String]]) -> Int? {
        let normalizedDay = dayString.trimmingCharacters(in: .whitespaces)

        for (index, variations) in localizedDays.enumerated() {
            for variation in variations {
                if normalizedDay.caseInsensitiveCompare(variation) == .orderedSame {
                    return index
                }
                // Also check if the day string starts with the variation (for abbreviated forms)
                if normalizedDay.count >= 3 && variation.count >= 3 {
                    let dayPrefix = String(normalizedDay.prefix(3))
                    let varPrefix = String(variation.prefix(3))
                    if dayPrefix.caseInsensitiveCompare(varPrefix) == .orderedSame {
                        return index
                    }
                }
            }
        }

        return nil
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
