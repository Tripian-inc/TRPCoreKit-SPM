//
//  OpenHourCellController.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 23.10.2020.
//  Copyright © 2020 Tripian Inc. All rights reserved.
//

import Foundation
class OpenHourCellController {
    
    var cell:  OpeningHoursCell?
    var model: String = ""
    private var isOpeningHoursMinHeight: Bool = true
    private let wordRemAdd: String = TRPLanguagesController.shared.getLanguageValue(for: "collapse_hours")
    private var cellHeight = UITableView.automaticDimension
    private var dayTitles: [String] = []
    private var days: Dictionary<String, [String]> = [:]
    
//    enum Weekday: String, CaseIterable {
//        case Mon, Tue, Wed, Thu, Fri, Sat, Sun
//        static var asArray: [Weekday] {return self.allCases}
//        
//        func asInt() -> Int {
//            return Weekday.asArray.firstIndex(of: self)!
//        }
//    }
    
    
    func configureCell(_ cell: OpeningHoursCell, model: String) {
        self.cell = cell
        dayTitles = [TRPLanguagesController.shared.getLanguageValue(for: "monday"),
                     TRPLanguagesController.shared.getLanguageValue(for: "tuesday"),
                     TRPLanguagesController.shared.getLanguageValue(for: "wednesday"),
                     TRPLanguagesController.shared.getLanguageValue(for: "thursday"),
                     TRPLanguagesController.shared.getLanguageValue(for: "friday"),
                     TRPLanguagesController.shared.getLanguageValue(for: "saturday"),
                     TRPLanguagesController.shared.getLanguageValue(for: "sunday")]
        self.model = getOpeningHoursButtonTitle(model)
        self.cell!.openingHoursLabel.text = self.model
        minifyDate()
    }
    
    func didSelectCell() {
        setOpeningHoursHeight()
    }
}

extension OpenHourCellController {
    
    private func setOpeningHoursHeight(){
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: { [weak self] in
            guard let strongSelf = self else {return}
            if strongSelf.isOpeningHoursMinHeight{
                strongSelf.maxifyDate()
            }else{
                strongSelf.minifyDate()
            }
            strongSelf.isOpeningHoursMinHeight.toggle()
            }, completion: nil)
    }
    
    private func maxifyDate(){
        guard let cell = cell else {return}
        cell.openingHoursLabel.numberOfLines = 10
        
        cell.arrowImage.image = cell.upArrowImage
        if let text = cell.openingHoursLabel.text {
            if text.count > 5{
                let latestText = "\(self.wordRemAdd)\n\(text)"
                cell.openingHoursLabel.text = latestText
            }
        }
        cell.layoutIfNeeded()
    }
    
    private func minifyDate(){
        guard let cell = cell else {return}
        cell.openingHoursLabel.numberOfLines = 1
        cell.arrowImage.image = cell.downArrowImage
        if let text = cell.openingHoursLabel.text {
            if text.count > 5{
                var latestText = text
                if let range = latestText.range(of: "\(self.wordRemAdd)\n") {
                    latestText.removeSubrange(range)
                }
                cell.openingHoursLabel.text = latestText
            }
        }
        cell.layoutIfNeeded()
    }
    
}

extension OpenHourCellController {
   
    private func getWeekDayOf(_ day: String) -> Int {
        return dayTitles.firstIndex(of: day) ?? 0
    }
    
    private func getOpeningHoursButtonTitle(_ openingHoursStr: String) -> String{
        for dayTitle in self.dayTitles {
            days[dayTitle] = []
        }
        let parts = openingHoursStr.components(separatedBy: "|")
        for part in parts {
            let keyVals = part.components(separatedBy: ": ")
            let dayKeys = keyVals[0].components(separatedBy: ",")
            for dayKey in dayKeys{
                days[dayKey.trimmingCharacters(in: .whitespacesAndNewlines)] = [keyVals[1].trimmingCharacters(in: .whitespacesAndNewlines)]
            }
        }
        
        days.forEach({ (key, value) -> Void in
            if days[key]?.count == 0{
                days[key] = [TRPLanguagesController.shared.getLanguageValue(for: "closed")]
            }
        })
        
        var todayAsInt: Int = 0
        
        if let today = dayChangedPoi.day.dayOfWeek(){
            todayAsInt = getWeekDayOf(today)
        }
        
        let sortedArray = days.sorted { (element0, element1) -> Bool in
            let day0 = getWeekDayOf(element0.key)
            let day1 = getWeekDayOf(element1.key)
            return day0 < day1
        }
        let daysBeforeToday = sortedArray.filter({(element0) -> Bool in
            return getWeekDayOf(element0.key) < todayAsInt
        })
        let daysAfterToday = sortedArray.filter({(element0) -> Bool in
            return getWeekDayOf(element0.key) >= todayAsInt
        })
        
        let daysResult = (daysAfterToday.compactMap({ (key, value) -> String in
            return "\(key): \(value.map{"\($0)"}.reduce(" "){$0+$1})"
        }) as Array).joined(separator: "\n") + "\n" + (daysBeforeToday.compactMap({ (key, value) -> String in
            return "\(key): \(value.map{"\($0)"}.reduce(" "){$0+$1})"
        }) as Array).joined(separator: "\n")
        
        
        return daysResult
    }
    
}
