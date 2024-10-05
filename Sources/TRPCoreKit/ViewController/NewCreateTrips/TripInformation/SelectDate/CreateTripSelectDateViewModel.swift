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
        let flightType = isArrival ? "arrival" : "departure"
        return "Select \(flightType) date"
    }
    
    func getSelectedDate() -> Date {
        return dateModel?.selectedDate.localDate() ?? Date()
    }
    
    func getMinimumSelectableDate() -> Date {
        return dateModel?.minimumDate.localDate() ?? Date()
    }
    
    func getMaximumSelectableDate() -> Date {
        return dateModel?.maximumDate?.localDate() ?? Date().addDay(5000)!
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
