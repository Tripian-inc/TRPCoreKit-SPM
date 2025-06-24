//
//  Date+Extensions.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 9.11.2018.
//  Copyright © 2018 Tripian Inc. All rights reserved.
//

import Foundation
extension Date {
    
    /// Date tipindeki veriyi String tipine dönüştürür.
    ///
    /// - Parameter format: Date formatı
    /// - Returns: Date to String
    func toString(format: String? = nil, timeZone: String? = "UTC", dateStyle: DateFormatter.Style? = nil, timeStyle: DateFormatter.Style? = nil) -> String {
        let formatter = DateFormatter()
        if let timeZone {
            formatter.timeZone = TimeZone(identifier: timeZone)
        } else {
            formatter.timeZone = TimeZone.current
        }
        let appLanguage = TRPClient.shared.language
        if appLanguage == "en" {
            formatter.locale = Locale(identifier: "en_US_POSIX")
        } else {
            formatter.locale = Locale(identifier: appLanguage)
        }
        if let f = format {
            formatter.dateFormat = f
        }
        if let ts = timeStyle {
            formatter.timeStyle = ts
        }
        if let ds = dateStyle   {
            formatter.dateStyle = ds
        }
        return formatter.string(from: self)
    }
    
    func toStringWithoutTimeZone(format: String? = nil, dateStyle: DateFormatter.Style? = nil, timeStyle: DateFormatter.Style? = nil) -> String {
        return toString(format: format, timeZone: nil)
    }

    
    //Tarihin gununu dondurur. -> Mon, Tue, Wed..
    func dayOfWeek() -> String? {
        return toStringWithoutTimeZone(format: "EE").capitalized
        // or use capitalized(with: locale) if you want
    }
    
    //Bugunun gununu sayi olarak dondurur.
    func dayNumberOfWeek() -> Int? {
        return Calendar.currentWithUTC.dateComponents([.weekday], from: self).weekday
    }
    
    func isBetween(_ date1: Date, and date2: Date) -> Bool {
        return (min(date1, date2) ... max(date1, date2)).contains(self)
    }
    
    func addMin(component: Calendar.Component, value: Int) -> Date?{
        let calendar = Calendar.currentWithUTC
        let next = calendar.date(byAdding: component, value: value, to: self)
        return next
    }
    
    func addDay(_ day: Int, withoutUTC: Bool = false) -> Date? {
        var dayComponent = DateComponents()
        dayComponent.day = day
        
        if withoutUTC {
            return Calendar.current.date(byAdding: dayComponent, to: self)
        }
        
        return Calendar.currentWithUTC.date(byAdding: dayComponent, to: self)
    }
    
    func isDatePast(toDate: Date = Date().localDate()) -> Bool {
        return toDate > self
    }
    
    func isToday() -> Bool {
        return Calendar.currentWithUTC.isDateInToday(self)
    }
    
    func isTodayLocal() -> Bool {
        return getDate(forLocal: false) == Date().localDate().getDate()
    }
    
    func addHour(_ hours: Int) -> Date? {
        var dayComponent = DateComponents()
        dayComponent.hour = hours
        return Calendar.currentWithUTC.date(byAdding: dayComponent, to: self)
    }
    
    func addHour(_ hours: Int, minutes: Int) -> Date? {
        var dayComponent = DateComponents()
        dayComponent.hour = hours
        dayComponent.minute = minutes
        return Calendar.currentWithUTC.date(byAdding: dayComponent, to: self)
    }
    

    func setHour(_ hours: Int, minutes: Int) -> Date? {
        Calendar.currentWithUTC.date(bySettingHour: hours, minute: minutes, second: 0, of: self)!
    }
    
    func getHour() -> String {
        return toStringWithoutTimeZone(format: "HH:mm")
    }
    
    func getDate(forLocal: Bool = true) -> String {
        if forLocal {
            return toStringWithoutTimeZone(format: String.defaultDateFormat)
        }
        return toString(format: String.defaultDateFormat)
    }
    
    func setHour(for hour: String?) -> Date? {
        if let hour = hour, hour.contains(":") {
            let splitted = hour.components(separatedBy: ":")
            if splitted.count > 1, let hours = Int(splitted[0]),  let minutes = Int(splitted[1]) {
                return setHour(hours, minutes: minutes)
            }
        }
        return self
    }
    
    func localDate() -> Date {
        let timeZoneOffset = Double(TimeZone.current.secondsFromGMT(for: self))
        guard let localDate = Calendar.current.date(byAdding: .second, value: Int(timeZoneOffset), to: self) else {return Date()}

        return localDate
    }
    
    func getDateWithZeroHour(forLocal: Bool = false) -> Date {
        if forLocal {
            return Calendar.current.startOfDay(for: self)
        }
        return Calendar.currentWithUTC.startOfDay(for: self)
    }
    
    func getHourForTimer() -> String {
        let hour = localDate().addHour(1)?.toString(format: "HH")
        return "\(hour ?? "09"):00"
    }
    
    func numberOfDaysBetween(_ to: Date) -> Int {
        let calendar = Calendar.currentWithUTC
        let fromDate = calendar.startOfDay(for: self) 
        let toDate = calendar.startOfDay(for: to)
        let numberOfDays = calendar.dateComponents([.day], from: fromDate, to: toDate)
        
        return numberOfDays.day! + 1
    }
    
    static func getTimes(by interval: Int = 30) -> [String] {
        var times: [String] = []
        for hour in 0..<24 {
            for minute in stride(from: 0, to: 60, by: interval)  {
                times.append(getHourMinuteText(hour: hour, minute: minute))
            }
        }
        return times
    }
    
    static func getHourMinuteText(hour: Int, minute: Int) -> String {
        var hourString = "\(hour)"
        if hour < 10 {
            hourString = "0\(hour)"
        }
        var minString = "\(minute)"
        if minute < 10 {
            minString = "0\(minute)"
        }
        return "\(hourString):\(minString)"
    }
    
    static func getNearestAvailableDateAndTimeForCreateTrip(maxHour: Int = 16) -> (String, String) {
        var date = Date().localDate()
        var timeString = "09:00"
//        if date.isToday() {
            let time = date.toString(format: "HH:mm")
            if let hour = time.components(separatedBy: ":").first,
               let minute = time.components(separatedBy: ":").last,
               let hourInt = Int(hour),
               let minuteInt = Int(minute),
               hourInt < maxHour {
                if hourInt > 8 {
                    if minuteInt <= 30 {
                        timeString = getHourMinuteText(hour: hourInt + 1, minute: 0)
                    } else {
                        timeString = getHourMinuteText(hour: hourInt + 1, minute: 30)
                    }
                }
            } else {
                if let dateAfter = date.addDay(1, withoutUTC: true) {
                    date = dateAfter
                }
            }
//        }
        return (date.getDate(forLocal: false), timeString)
    }
    
    static func getTomorrowDate() -> String {
        return Date().localDate().addDay(1)?.getDate() ?? Date().localDate().getDate()
    }
    
    static func getNearestDate() -> String {
        return getNearestAvailableDateAndTimeForCreateTrip(maxHour: 20).0
    }
}

