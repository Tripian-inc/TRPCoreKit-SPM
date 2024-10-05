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
    private let wordRemAdd: String = "Collapse hours \n".toLocalized()
    private var cellHeight = UITableView.automaticDimension 
    private var days: Dictionary<String, [String]> = ["Mon": [],"Tue": [],"Wed": [],"Thu": [],"Fri": [],"Sat": [],"Sun": []]
    
    enum Weekday: String, CaseIterable {
        case Mon, Tue, Wed, Thu, Fri, Sat, Sun
        static var asArray: [Weekday] {return self.allCases}
        
        func asInt() -> Int {
            return Weekday.asArray.firstIndex(of: self)!
        }
    }
    
    
    func configureCell(_ cell: OpeningHoursCell, model: String) {
        self.cell = cell
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
                let latestText = "\(self.wordRemAdd)\(text)"
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
                if let range = latestText.range(of: self.wordRemAdd) {
                    latestText.removeSubrange(range)
                }
                cell.openingHoursLabel.text = latestText
            }
        }
        cell.layoutIfNeeded()
    }
    
}

extension OpenHourCellController {
   
    
    private func getOpeningHoursButtonTitle(_ openingHoursStr: String) -> String{
        let parts = openingHoursStr.components(separatedBy: "|")
        for part in parts{
            let keyVals = part.components(separatedBy: ": ")
            let dayKeys = keyVals[0].components(separatedBy: ",")
            for dayKey in dayKeys{
                days[dayKey.trimmingCharacters(in: .whitespacesAndNewlines)] = [keyVals[1].trimmingCharacters(in: .whitespacesAndNewlines)]
            }
        }
        
        days.forEach({ (key, value) -> Void in
            if days[key]?.count == 0{
                days[key] = ["Closed"]
            }
        })
        
        var todayAsInt: Int = 0
        
        if let today = dayChangedPoi.day.dayOfWeek(){
            if let dayNumb = OpeningHoursCellController.Weekday(rawValue: today)?.asInt(){
                todayAsInt = dayNumb
            }
        }
        
        let sortedArray = days.sorted { (element0, element1) -> Bool in
            guard let day0 = OpeningHoursCellController.Weekday(rawValue: element0.key) , let day1 = OpeningHoursCellController.Weekday(rawValue: element1.key) else {
                return false
            }
            return day0.asInt() < day1.asInt()
        }
        let daysBeforeToday = sortedArray.filter({(element0) -> Bool in
            guard let day0 = OpeningHoursCellController.Weekday(rawValue: element0.key) else {
                return false
            }
            return day0.asInt() < todayAsInt
        })
        let daysAfterToday = sortedArray.filter({(element0) -> Bool in
            guard let day0 = OpeningHoursCellController.Weekday(rawValue: element0.key) else {
                return false
            }
            return day0.asInt() >= todayAsInt
        })
        
        let daysResult = (daysAfterToday.compactMap({ (key, value) -> String in
            return "\(key): \(value.map{"\($0)"}.reduce(" "){$0+$1})"
        }) as Array).joined(separator: "\n") + "\n" + (daysBeforeToday.compactMap({ (key, value) -> String in
            return "\(key): \(value.map{"\($0)"}.reduce(" "){$0+$1})"
        }) as Array).joined(separator: "\n")
        
        
        return daysResult
    }
    
}
