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
    public static let moveDay = "addPlan.label.moveDay"
    public static let city = "addPlan.label.city"
    public static let selectCity = "addPlan.title.selectCity"
    public static let destination = "trips.createNewTrip.destinationTips.destination.title"
    public static let citiesForSelectedDate = "addPlan.section.citiesForSelectedDate"
    public static let otherCities = "addPlan.section.otherCities"
    public static let startTime = "addPlan.label.startTime"
    public static let endTime = "addPlan.label.endTime"
    public static let clearSelection = "addPlan.button.clearSelection"

    // MARK: - Common Keys (use CommonLocalizationKeys)

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

    // MARK: - Sorting Info
    public static let sortingInfoTitle = "addPlan.info.sortingTitle"
    public static let sortingInfoMessage = "addPlan.info.sortingMessage"

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
    public static let noAvailableTimes = "addPlan.emptyState.noAvailableTimes"

    // MARK: - Flexible-time Activity
    public static let flexibleTimeInfo = "addPlan.time.flexibleInfo"
    public static let flexibleTimePinTopHint = "addPlan.time.flexibleTopOfItinerary"

    public static let activityNotAvailableForTrip = "addPlan.time.activityNotAvailableForTrip"

    public static let showMoreTimeSlots = "addPlan.time.showMore"

    public static let soldOutWarning = "addPlan.time.soldOutWarning"

    public static let endTimeBeforeStartWarning = "addPlan.time.endTimeBeforeStart"

    // MARK: - Toast / Success Notifications
    /// Format: activity name as %1$@, day display string as %2$@.
    public static let activityAddedToast = "addPlan.toast.activityAdded"

    // MARK: - Saved Plans Screen
    public static let savedPlans = "addPlan.title.savedPlans"

    public static let savedPlansAllAddedTitle = "addPlan.emptyState.allAddedTitle"
    public static let savedPlansAllAddedDescription = "addPlan.emptyState.allAddedDescription"
    public static let viewItinerary = "addPlan.button.viewItinerary"

    // MARK: - Error Messages
    public static let errorMissingData = "trips.myTrips.timelineitinerary.addPlan.error.missingData"
    public static let errorCreateFailed = "trips.myTrips.timelineitinerary.addPlan.error.createFailed"
    public static let errorTimelineNotFound = "addPlan.error.timelineNotFound"
    public static let errorActivityLocationNotAvailable = "addPlan.error.activityLocationNotAvailable"
    public static let errorSelectDate = "addPlan.error.selectDate"
    public static let errorSelectTimeSlot = "addPlan.error.selectTimeSlot"
    public static let errorCreateReservationFailed = "addPlan.error.createReservationFailed"
    public static let errorSegmentNotFound = "addPlan.error.segmentNotFound"
    public static let errorUpdateTimeFailed = "addPlan.error.updateTimeFailed"
    public static let errorStepNotFound = "addPlan.error.stepNotFound"
    public static let errorInvalidTimeFormat = "addPlan.error.invalidTimeFormat"
    public static let errorNoDateSelected = "addPlan.error.noDateSelected"
    
    // MARK: - Default English Values
    private static let defaultValues: [String: String] = [
        addPlan: "Add Plan",
        addActivity: "Add Activity",
        addToDay: "Add to Day",
        moveDay: "Move day",
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
        selectDateAndTime: "Select time",
        selectTravelers: "Select Travelers",
        travelers: "Travelers",
        selectATime: "Select a time",
        searchPOI: "Search for a place",
        cityCenter: "City Center",
        savedActivities: "Itinerary starting locations",
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
        sortingInfoTitle: "Sorting Criteria",
        sortingInfoMessage: "Activities are sorted by relevance and availability based on your selected date and preferences.",
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
        noAvailableTimes: "No available times",
        savedPlans: "Saved Plans",
        savedPlansAllAddedTitle: "All set!",
        savedPlansAllAddedDescription: "You've added all your favourite activities to the itinerary. Now all that's left is to enjoy them.",
        viewItinerary: "View itinerary",
        errorMissingData: "Missing required information. Please complete all fields.",
        errorCreateFailed: "Failed to create smart recommendation. Please try again.",
        errorTimelineNotFound: "Timeline not found. Please try again.",
        errorActivityLocationNotAvailable: "Activity location not available.",
        errorSelectDate: "Please select a date.",
        errorSelectTimeSlot: "Please select a time slot.",
        errorCreateReservationFailed: "Failed to create reservation. Please try again.",
        errorSegmentNotFound: "Segment not found. Please try again.",
        errorUpdateTimeFailed: "Failed to update time. Please try again.",
        errorStepNotFound: "Step not found. Please try again.",
        errorInvalidTimeFormat: "Invalid time format.",
        errorNoDateSelected: "No date selected.",
        flexibleTimeInfo: "Valid at any time on the chosen day. Check the opening hours.",
        flexibleTimePinTopHint: "This plan will always appear at the top of your itinerary.",
        activityNotAvailableForTrip: "This activity is not available on the days of your trip.",
        showMoreTimeSlots: "More",
        soldOutWarning: "Your selected time is sold out. Choose a new time for accurate availability, or keep this as a placeholder.",
        endTimeBeforeStartWarning: "Choose an end time within today",
        activityAddedToast: "%1$@ has been added to %2$@"
    ]
    
    // MARK: - Helper Methods
    public static func localized(_ key: String) -> String {
        let localizedValue = TRPLanguagesController.shared.getLanguageValue(for: key)

        if localizedValue.isEmpty || localizedValue == key {
            return defaultValues[key] ?? key
        }
        
        return localizedValue
    }
}
