//
//  NexusLocalizationKeys.swift
//  TRPCoreKit
//
//  Localized strings for the Nexus create-trip flow (My Plans list, city
//  selection, date selection). Mirrors the Android LanguageConst keys so both
//  platforms resolve the same backend translations, with English fallbacks.
//

import Foundation

public struct NexusLocalizationKeys {

    // MARK: - Keys (shared with Android)
    public static let myPlans = "my_plans"
    public static let whereYouGo = "trips.createNewTrip.form.destination.city.label"
    public static let selectDates = "trips.createNewTrip.form.destination.dates"
    public static let search = "search"
    public static let next = "trips.myTrips.localExperiences.tourDetails.next"
    public static let edit = "trips.myTrips.localExperiences.tourDetails.edit"
    public static let popularCities = "cityInfo.popularCities"
    public static let destinations = "trips.myTrips.localExperiences.tourDetails.experience.destinations"
    public static let noResults = "destination.search.noResults"
    public static let noTripsYet = "trips.myPlans.empty"
    /// Suffix for the "X days until your trip" pill. The count is prefixed in code.
    public static let daysUntilTrip = "trips.myPlans.daysUntilTrip"
    public static let deleteTrip = "trips.deleteTrip.title"
    public static let deleteTripQuestion = "trips.deleteTrip.question"
    public static let deleteTripSubmit = "trips.deleteTrip.submit"

    // MARK: - English fallbacks
    private static let defaultValues: [String: String] = [
        myPlans: "My Trips",
        whereYouGo: "Where are you travelling?",
        selectDates: "Select a date",
        search: "Search",
        next: "Next",
        edit: "Edit",
        popularCities: "Top Destinations",
        destinations: "Destinations",
        noResults: "No destinations found",
        noTripsYet: "No trips yet",
        daysUntilTrip: "days until your trip",
        deleteTrip: "Delete trip",
        deleteTripQuestion: "Are you sure you want to delete this trip?",
        deleteTripSubmit: "Delete"
    ]

    public static func localized(_ key: String) -> String {
        let value = TRPLanguagesController.shared.getLanguageValue(for: key)
        if value.isEmpty || value == key {
            return defaultValues[key] ?? key
        }
        return value
    }
}
