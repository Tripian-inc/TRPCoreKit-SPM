//
//  CreateTripSelectTimeViewModel.swift
//  TRPCoreKit
//
//  Created by Cem Çaygöz on 4.10.2022.
//  Copyright © 2022 Tripian Inc. All rights reserved.
//

import Foundation

protocol ItineraryChangeTimeViewModelDelegate {
    func itineraryChangeTimeForStep(_ step: TRPStep?)
}

class ItineraryChangeTimeViewModel {
    
    public var step: TRPStep?
    
    public var selectedFromHour: String?
    public var selectedToHour: String?
    public var isArrival: Bool = true
    
    private var times: [String] = []
    
    private var fromHours: [String] = []
    private var toHours: [String] = []
    
    public var delegate: ItineraryChangeTimeViewModelDelegate?
    
    public func start() {
        times = Date.getTimes(by: 5)
        fromHours = Array(times)
        toHours = Array(times)
        
        selectedFromHour = step?.times?.from
        selectedToHour = step?.times?.to
        
        if let selectedFromHour = selectedFromHour, let index = times.firstIndex(of: selectedFromHour) {
            toHours = Array(times.dropFirst(index))
        }
    }
    
    public func setSelectedFromHour(indexPath: IndexPath) {
        selectedFromHour = fromHours[indexPath.row]
        updateToHours()
    }
    
    public func setSelectedToHour(indexPath: IndexPath) {
        selectedToHour = toHours[indexPath.row]
    }
    
    private func updateToHours() {
        
        if let selectedFromHour = selectedFromHour, let index = times.firstIndex(of: selectedFromHour) {
            let duration = step?.poi.duration ?? 30
            toHours = Array(times.dropFirst(index))
            let estimatedToHour = duration / 5
            if estimatedToHour < toHours.count {
                selectedToHour = toHours[estimatedToHour]
            } else if toHours.count > 2 {
                selectedToHour = toHours[1]
            }
        }
        
    }
    
    public func applyChanges() {
        step?.times?.from = selectedFromHour
        step?.times?.to = selectedToHour
        delegate?.itineraryChangeTimeForStep(step)
    }
    
    public func getEstimatedTime() -> String {
        return "\(step?.poi.duration ?? 30)"
    }
    
    public func getFromRowCount() -> Int {
        return fromHours.count
    }
    
    public func getToRowCount() -> Int {
        return toHours.count
    }
    
    public func getFromHour(indexPath: IndexPath) -> String {
        return fromHours[indexPath.row]
    }
    
    public func getToHour(indexPath: IndexPath) -> String {
        return toHours[indexPath.row]
    }
    
    public func isSelectedFromHour(hour: String) -> Bool {
        return selectedFromHour == hour
    }
    
    public func isSelectedToHour(hour: String) -> Bool {
        return selectedToHour == hour
    }
    
    public func getSelectedFromHourIndexPath() -> IndexPath {
        if let selectedHour = selectedFromHour {
            let selectedHourRow = fromHours.firstIndex(of: selectedHour) ?? 0
            let indexPath = IndexPath(row: selectedHourRow, section: 0)
            return indexPath
        }
        return IndexPath()
    }
    
    public func getSelectedToHourIndexPath() -> IndexPath {
        if let selectedHour = selectedToHour {
            let selectedHourRow = toHours.firstIndex(of: selectedHour) ?? 0
            let indexPath = IndexPath(row: selectedHourRow, section: 0)
            return indexPath
        }
        return IndexPath()
    }
}
