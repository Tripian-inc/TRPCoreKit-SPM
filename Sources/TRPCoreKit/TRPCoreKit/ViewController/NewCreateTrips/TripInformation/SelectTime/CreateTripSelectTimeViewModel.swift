//
//  CreateTripSelectTimeViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 4.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation

class CreateTripSelectTimeViewModel {   
    
    public var selectedHour: String?
    public var minimumHour: String?
    public var isArrival: Bool = true
    
    private final let times: [String] = ["00:00", "00:30", "01:00", "01:30", "02:00", "02:30", "03:00", "03:30", "04:00", "04:30", "05:00", "05:30", "06:00", "06:30", "07:00", "07:30", "08:00", "08:30", "09:00", "09:30", "10:00", "10:30", "11:00", "11:30", "12:00", "12:30", "13:00", "13:30", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30", "17:00", "17:30", "18:00", "18:30", "19:00", "19:30", "20:00", "20:30", "21:00", "21:30", "22:00", "22:30", "23:00", "23:30"]
    
    private var hours: [String] = []
    
    public func start() {
        
        if let minimumHour = minimumHour, let index = times.firstIndex(of: minimumHour) {
            hours = Array(times.dropFirst(index))
        } else {
            hours = times
        }
    }
    
    public func getTitle() -> String {
        let flightType = isArrival ? "arrival" : "departure"
        return "Select \(flightType) hour"
    }
    
    public func getRowCount() -> Int {
        return hours.count
    }
    
    public func getHour(indexPath: IndexPath) -> String {
        return hours[indexPath.row]
    }
    
    public func isSelectedHour(hour: String) -> Bool {
        return selectedHour == hour
    }
    
    public func getSelectedHourIndexPath() -> IndexPath {
        if let selectedHour = selectedHour {
            let selectedHourRow = hours.firstIndex(of: selectedHour) ?? 0
            let indexPath = IndexPath(row: selectedHourRow, section: 0)
            return indexPath
        }
        return IndexPath()
    }
}
