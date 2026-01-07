//
//  AddPlanLocalizationKeys.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 23.12.2024.
//  Copyright © 2024 Tripian Inc. All rights reserved.
//

import Foundation

public struct AddPlanLocalizationKeys {
    // MARK: - Main Screen
    public static let addPlan = "addPlan.title.addPlan"
    public static let addActivity = "addPlan.title.addActivity"
    public static let addToDay = "addPlan.label.addToDay"
    public static let city = "addPlan.label.city"
    public static let selectCity = "addPlan.title.selectCity"
    public static let citiesForSelectedDate = "addPlan.section.citiesForSelectedDate"
    public static let otherCities = "addPlan.section.otherCities"
    public static let startTime = "addPlan.label.startTime"
    public static let endTime = "addPlan.label.endTime"
    public static let clearSelection = "addPlan.button.clearSelection"

    // MARK: - Common Keys (use CommonLocalizationKeys)
    // cancel, confirm, continueButton, select, from, freeCancellation
    // are now in CommonLocalizationKeys

    // MARK: - Time Range Selection
    public static let timeTitle = "addPlan.title.time"
    
    // MARK: - Selection Mode
    public static let howToAddPlans = "addPlan.label.howToAddPlans"
    public static let smartRecommendations = "addPlan.mode.smartRecommendations"
    public static let smartRecommendationsDescription = "addPlan.description.smartRecommendations"
    public static let addManually = "addPlan.mode.addManually"
    public static let addManuallyDescription = "addPlan.description.addManually"
    
    // MARK: - Time & Travelers
    public static let selectStartingPoint = "addPlan.label.selectStartingPoint"
    public static let selectDateAndTime = "addPlan.label.selectDateAndTime"
    public static let selectTravelers = "addPlan.label.selectTravelers"
    public static let travelers = "addPlan.label.travelers"
    public static let selectATime = "addPlan.label.selectATime"
    
    // MARK: - POI Selection
    public static let searchPOI = "addPlan.placeholder.searchPOI"
    public static let nearMe = "addPlan.option.nearMe"
    public static let cityCenter = "addPlan.label.cityCenter"
    public static let savedActivities = "addPlan.section.savedActivities"
    
    // MARK: - Categories
    public static let selectCategories = "addPlan.label.selectCategories"
    public static let categoryGuidedTours = "addPlan.category.guidedTours"
    public static let categoryTickets = "addPlan.category.tickets"
    public static let categoryExcursions = "addPlan.category.excursions"
    public static let categoryPOI = "addPlan.category.poi"
    public static let categoryFood = "addPlan.category.food"
    public static let categoryShows = "addPlan.category.shows"
    public static let categoryTransport = "addPlan.category.transport"
    
    // MARK: - Manual Mode Categories
    public static let categoryActivities = "addPlan.category.manual.activities"
    public static let categoryPlacesOfInterest = "addPlan.category.manual.placesOfInterest"
    public static let categoryEatAndDrink = "addPlan.category.manual.eatAndDrink"
    
    // MARK: - Activity Listing
    public static let categoryAll = "addPlan.category.all"
    public static let searchActivity = "addPlan.search.activity"
    public static let filters = "addPlan.button.filters"
    public static let sortBy = "addPlan.button.sortBy"
    public static let opinions = "addPlan.label.opinions"
    public static let activity = "addPlan.label.activity"
    public static let activities = "addPlan.label.activities"

    // MARK: - Sort Options
    public static let sortPopularity = "addPlan.sort.popularity"
    public static let sortRating = "addPlan.sort.rating"
    public static let sortPriceLowToHigh = "addPlan.sort.priceLowToHigh"
    public static let sortNewest = "addPlan.sort.newest"
    public static let sortDurationShortToLong = "addPlan.sort.durationShortToLong"
    public static let sortDurationLongToShort = "addPlan.sort.durationLongToShort"

    // MARK: - Filter Options
    public static let filterPrice = "addPlan.filter.price"
    public static let filterDuration = "addPlan.filter.duration"
    public static let filterFree = "addPlan.filter.free"
    public static let filterDays = "addPlan.filter.days"

    // MARK: - POI Listing
    public static let searchPOIPlace = "addPlan.search.poiPlace"
    public static let placesOfInterest = "addPlan.title.placesOfInterest"
    public static let place = "addPlan.label.place"
    public static let places = "addPlan.label.places"
    
    // MARK: - Empty State
    public static let addSavedPlansToItinerary = "addPlan.emptyState.addSavedPlansToItinerary"

    // MARK: - Saved Plans Screen
    public static let savedPlans = "addPlan.title.savedPlans"

    // MARK: - Error Messages
    public static let errorMissingData = "trips.myTrips.timelineitinerary.addPlan.error.missingData"
    public static let errorCreateFailed = "trips.myTrips.timelineitinerary.addPlan.error.createFailed"
    
    // MARK: - Default English Values
    private static let defaultValues: [String: String] = [
        addPlan: "Add Plan",
        addActivity: "Add Activity",
        addToDay: "Add to Day",
        city: "City",
        selectCity: "Select City",
        citiesForSelectedDate: "Cities for this date",
        otherCities: "Other cities",
        startTime: "Start Time",
        endTime: "End Time",
        clearSelection: "Clear Selection",
        timeTitle: "Time",
        howToAddPlans: "How do you want to add plans?",
        smartRecommendations: "Smart Recommendations",
        smartRecommendationsDescription: "Enhance your trip with smart recommendations based on your planning.",
        addManually: "Add Manually",
        addManuallyDescription: "Select a single activity directly from the catalog.",
        selectStartingPoint: "Select a Starting Point",
        selectDateAndTime: "Select Date and Time",
        selectTravelers: "Select Travelers",
        travelers: "Travelers",
        selectATime: "Select a time",
        searchPOI: "Search for a place",
        nearMe: "Near me",
        cityCenter: "City Center",
        savedActivities: "Reserved and Saved Activities",
        selectCategories: "Select the Categories You Want",
        categoryGuidedTours: "Guided Tours\n& Free Tours",
        categoryTickets: "Tickets",
        categoryExcursions: "Multi-day\nExcursions",
        categoryPOI: "Point of\nInterest",
        categoryFood: "Food &\nDrinks",
        categoryShows: "Shows",
        categoryTransport: "Transport &\nTransfers",
        categoryActivities: "Activities",
        categoryPlacesOfInterest: "Places of\nInterest",
        categoryEatAndDrink: "Eat &\nDrink",
        categoryAll: "All",
        searchActivity: "Search for an activity",
        filters: "Filters",
        sortBy: "Sort by",
        sortPopularity: "Popularity",
        sortRating: "Rating",
        sortPriceLowToHigh: "Price (lowest first)",
        sortNewest: "Newest",
        sortDurationShortToLong: "Duration (shortest to longest)",
        sortDurationLongToShort: "Duration (longest to shortest)",
        filterPrice: "Price",
        filterDuration: "Duration",
        filterFree: "Free",
        filterDays: "days",
        opinions: "opinions",
        activity: "activity",
        activities: "activities",
        searchPOIPlace: "Search for a place or address",
        placesOfInterest: "Places of Interest",
        place: "place",
        places: "places",
        addSavedPlansToItinerary: "Add your saved plans to the itinerary",
        savedPlans: "Saved Plans",
        errorMissingData: "Missing required information. Please complete all fields.",
        errorCreateFailed: "Failed to create smart recommendation. Please try again."
    ]
    
    // MARK: - Helper Methods
    public static func localized(_ key: String) -> String {
        let localizedValue = TRPLanguagesController.shared.getLanguageValue(for: key)
        
        // If the localization returns the key itself or is empty, use default English value
        if localizedValue.isEmpty || localizedValue == key {
            return defaultValues[key] ?? key
        }
        
        return localizedValue
    }
}
