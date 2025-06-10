//
//  CreateTripSelectDateViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 2.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation

class CreateTripSelectDateViewModel {
    public var dateModel: CreateTripDateModel?
    public var isArrival: Bool = true
    
    func getTitle() -> String {
        if isArrival {
            return TRPLanguagesController.shared.getLanguageValue(for: "trips.createNewTrip.destinationTips.arrivalDate.description")
        } else {
            return TRPLanguagesController.shared.getLanguageValue(for: "trips.createNewTrip.destinationTips.departureDate.description")
        }
    }
    
    func getSelectedDate() -> Date? {
        let selectedDate = dateModel?.selectedDate.toDateWithoutUTC() ?? Date().localDate()
        guard !selectedDate.isDatePast(toDate: getMinimumSelectableDate()) else {
            return nil
        }
        return selectedDate
    }
    
    func getMinimumSelectableDate() -> Date {
        return dateModel?.minimumDate.toDateWithoutUTC() ?? Date().localDate()
    }
    
    func getMaximumSelectableDate() -> Date {
        return dateModel?.maximumDate?.toDateWithoutUTC() ?? Date().localDate().addDay(5000)!
    }
    
    func datesRange(from: Date, to: Date) -> [Date] {
        if from > to { return [Date]() }

        var tempDate = from
        var array = [tempDate]

        while tempDate < to {
            tempDate = Calendar.current.date(byAdding: .day, value: 1, to: tempDate)!
            array.append(tempDate)
        }

        return array
    }
}
