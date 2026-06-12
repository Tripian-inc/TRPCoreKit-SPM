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
            return [""]
        }

        let imageUrls = gallery.compactMap { image -> String? in
            guard let urlString = image?.url, !urlString.isEmpty else { return nil }
            return urlString
        }

        return imageUrls.isEmpty ? [""] : imageUrls
    }

    public func getCityName() -> String {
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

        let parsedHours = parseOpeningHours(hours)
        return parsedHours
    }

    public func getOpeningHoursList() -> [(day: String, hours: String)]? {
        guard let hours = poi.hours, !hours.isEmpty else { return nil }
        return parseOpeningHoursToList(hours)
    }

    private func parseOpeningHoursToList(_ hoursString: String) -> [(day: String, hours: String)] {
        let localizedDays = getLocalizedDayNames()
        let localizedDayAbbrs = getLocalizedDayAbbreviations()

        let closedText = PoiDetailLocalizationKeys.localized(PoiDetailLocalizationKeys.closed)
        var dayHours: [Int: String] = [:]
        for i in 0..<7 {
            dayHours[i] = closedText
        }

        let groups = hoursString.components(separatedBy: "|")

        for group in groups {
            let trimmedGroup = group.trimmingCharacters(in: .whitespaces)

            guard let colonIndex = trimmedGroup.firstIndex(of: ":") else { continue }
            let daysString = String(trimmedGroup[..<colonIndex]).trimmingCharacters(in: .whitespaces)
            let timeString = String(trimmedGroup[trimmedGroup.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)

            let convertedTimeString = convertTo24HourFormat(timeString)

            let days = daysString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }

            for day in days {
                if day.contains("-") {
                    let rangeParts = day.components(separatedBy: "-")
                    if rangeParts.count == 2 {
                        let startDay = rangeParts[0].trimmingCharacters(in: .whitespaces)
                        let endDay = rangeParts[1].trimmingCharacters(in: .whitespaces)

                        if let startIndex = getDayIndex(startDay, localizedDays: localizedDays),
                           let endIndex = getDayIndex(endDay, localizedDays: localizedDays) {
                            if startIndex <= endIndex {
                                for i in startIndex...endIndex {
                                    dayHours[i] = convertedTimeString
                                }
                            } else {
                                for i in startIndex..<7 {
                                    dayHours[i] = convertedTimeString
                                }
                                for i in 0...endIndex {
                                    dayHours[i] = convertedTimeString
                                }
                            }
                        }
                    }
                } else {
                    if let dayIndex = getDayIndex(day, localizedDays: localizedDays) {
                        dayHours[dayIndex] = convertedTimeString
                    }
                }
            }
        }

        var result: [(day: String, hours: String)] = []
        for (index, abbr) in localizedDayAbbrs.enumerated() {
            if let hours = dayHours[index] {
                result.append((day: abbr, hours: hours))
            }
        }

        return result
    }

    private func parseOpeningHours(_ hoursString: String) -> String {
        let localizedDays = getLocalizedDayNames()
        let localizedDayAbbrs = getLocalizedDayAbbreviations()

        let closedText = PoiDetailLocalizationKeys.localized(PoiDetailLocalizationKeys.closed)
        var dayHours: [Int: String] = [:] // Use day index (0=Sun, 1=Mon, etc.)
        for i in 0..<7 {
            dayHours[i] = closedText
        }

        let groups = hoursString.components(separatedBy: "|")

        for group in groups {
            let trimmedGroup = group.trimmingCharacters(in: .whitespaces)

            guard let colonIndex = trimmedGroup.firstIndex(of: ":") else { continue }
            let daysString = String(trimmedGroup[..<colonIndex]).trimmingCharacters(in: .whitespaces)
            let timeString = String(trimmedGroup[trimmedGroup.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)

            let convertedTimeString = convertTo24HourFormat(timeString)

            let days = daysString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }

            for day in days {
                if day.contains("-") {
                    let rangeParts = day.components(separatedBy: "-")
                    if rangeParts.count == 2 {
                        let startDay = rangeParts[0].trimmingCharacters(in: .whitespaces)
                        let endDay = rangeParts[1].trimmingCharacters(in: .whitespaces)

                        if let startIndex = getDayIndex(startDay, localizedDays: localizedDays),
                           let endIndex = getDayIndex(endDay, localizedDays: localizedDays) {
                            if startIndex <= endIndex {
                                for i in startIndex...endIndex {
                                    dayHours[i] = convertedTimeString
                                }
                            } else {
                                for i in startIndex..<7 {
                                    dayHours[i] = convertedTimeString
                                }
                                for i in 0...endIndex {
                                    dayHours[i] = convertedTimeString
                                }
                            }
                        }
                    }
                } else {
                    if let dayIndex = getDayIndex(day, localizedDays: localizedDays) {
                        dayHours[dayIndex] = convertedTimeString
                    }
                }
            }
        }

        let maxDayLength = localizedDayAbbrs.map { $0.count }.max() ?? 3

        var result: [String] = []
        for (index, abbr) in localizedDayAbbrs.enumerated() {
            if let hours = dayHours[index] {
                let paddedDay = abbr.padding(toLength: maxDayLength + 2, withPad: " ", startingAt: 0)
                result.append("\(paddedDay)\(hours)")
            }
        }

        return result.joined(separator: "\n")
    }

    private func getLocalizedDayAbbreviations() -> [String] {
        let dayKeys = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        let englishAbbr = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        var abbreviations: [String] = []
        for i in 0..<7 {
            let localizedDay = TRPLanguagesController.shared.getLanguageValue(for: dayKeys[i])
            if !localizedDay.isEmpty && localizedDay != dayKeys[i] {
                let abbr = localizedDay.count >= 3 ? String(localizedDay.prefix(3)) : localizedDay
                abbreviations.append(abbr.capitalized)
            } else {
                abbreviations.append(englishAbbr[i])
            }
        }
        return abbreviations
    }

    private func convertTo24HourFormat(_ timeString: String) -> String {
        let upperTime = timeString.uppercased()
        if !upperTime.contains("AM") && !upperTime.contains("PM") {
            return timeString // Already in 24h format or not a time
        }

        let timeRanges = timeString.components(separatedBy: ",")
        var convertedRanges: [String] = []

        for range in timeRanges {
            let trimmedRange = range.trimmingCharacters(in: .whitespaces)
            let rangeParts = trimmedRange.components(separatedBy: " - ")
            var convertedParts: [String] = []

            for part in rangeParts {
                let converted = convertSingleTimeTo24Hour(part.trimmingCharacters(in: .whitespaces))
                convertedParts.append(converted)
            }

            convertedRanges.append(convertedParts.joined(separator: " - "))
        }

        return convertedRanges.joined(separator: ", ")
    }

    /// Convert a single time like "8:30 AM" to "08:30".
    private func convertSingleTimeTo24Hour(_ time: String) -> String {
        let upperTime = time.uppercased()
        let isPM = upperTime.contains("PM")
        let isAM = upperTime.contains("AM")

        guard isPM || isAM else { return time }

        let cleanTime = upperTime
            .replacingOccurrences(of: "AM", with: "")
            .replacingOccurrences(of: "PM", with: "")
            .trimmingCharacters(in: .whitespaces)

        let timeParts = cleanTime.components(separatedBy: ":")
        guard timeParts.count >= 1 else { return time }

        var hour = Int(timeParts[0]) ?? 0
        let minute = timeParts.count > 1 ? (Int(timeParts[1]) ?? 0) : 0

        if isPM && hour != 12 {
            hour += 12
        } else if isAM && hour == 12 {
            hour = 0
        }

        return String(format: "%02d:%02d", hour, minute)
    }

    /// Each inner array holds variations of a day name (full, abbreviated, localized). Index 0 = Sunday.
    private func getLocalizedDayNames() -> [[String]] {
        var localizedDays: [[String]] = []

        let dayKeys = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
        let englishFull = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let englishAbbr = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        for i in 0..<7 {
            var variations: [String] = []

            variations.append(englishFull[i])
            variations.append(englishAbbr[i])
            variations.append(englishFull[i].lowercased())
            variations.append(englishAbbr[i].lowercased())

            let localizedDay = TRPLanguagesController.shared.getLanguageValue(for: dayKeys[i])
            if !localizedDay.isEmpty && localizedDay != dayKeys[i] {
                variations.append(localizedDay)
                variations.append(localizedDay.lowercased())
                variations.append(localizedDay.capitalized)
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

    private func getDayIndex(_ dayString: String, localizedDays: [[String]]) -> Int? {
        let normalizedDay = dayString.trimmingCharacters(in: .whitespaces)

        for (index, variations) in localizedDays.enumerated() {
            for variation in variations {
                if normalizedDay.caseInsensitiveCompare(variation) == .orderedSame {
                    return index
                }
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

    public func isRestaurantCafeOrNightlife() -> Bool {
        for category in poi.categories {
            if TRPPoiUseCases.isEatAndDrinkCategory(category.id) {
                return true
            }
        }

        return false
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

    public func hasCuisines() -> Bool {
        guard let cuisines = poi.cuisines, !cuisines.isEmpty else { return false }
        return true
    }

    public func getCuisines() -> [String] {
        guard let cuisines = poi.cuisines, !cuisines.isEmpty else { return [] }
        return cuisines
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    public func hasProducts() -> Bool {
        guard let bookings = poi.bookings else { return false }

        // provider ID 15 = Civitatis
        return bookings.contains { booking in
            guard booking.providerId == 15,
                  let products = booking.products,
                  !products.isEmpty else { return false }
            return true
        }
    }

    public func getProducts() -> [TRPBookingProduct] {
        guard let bookings = poi.bookings else { return [] }

        // provider ID 15 = Civitatis
        var civittatisProducts: [TRPBookingProduct] = []
        bookings.forEach { booking in
            if booking.providerId == 15, let products = booking.products {
//            if let products = booking.products {
                civittatisProducts.append(contentsOf: products)
            }
        }

        return civittatisProducts
    }
}
