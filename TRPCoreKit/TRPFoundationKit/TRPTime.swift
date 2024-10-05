//
//  TRPTime.swift
//  TRPFoundationKit
//
//  Created by Evren Yaşar on 5.08.2020.
//  Copyright © 2020 Evren Yaşar. All rights reserved.
//

import Foundation

/// This struct has Date and Time formats.
/// To convert string to Date/Time.
/// Date is `yyyy-mm-dd`
/// Time is `hh:mm`
public struct TRPTime: Codable {
    
    public var timeForServer: String {
        return "\(self.date)T\(self.time)Z"
    }
    
    /// A Date value. Closer uses a `yyyy-MM-dd HH:mm`style to convert.
    public var toDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let timeZone = TimeZone(identifier: "UTC") {
            formatter.timeZone = timeZone
        }
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return  formatter.date(from: "\(date) \(time)")
    }
    
    /// A String value. Readable value of date
    public var date: String = ""
    /// A String value. Readable value of time
    public var time: String = ""
    
    /// Initilizes a new TRPTime with Int values.
    ///
    /// - Parameters:
    ///   - year: years such as 2019
    ///   - month: month such as 12
    ///   - day: day such as 29
    ///   - hours: hours such as 14
    ///   - min: min such as 00
    public init(year: Int, month: Int, day: Int, hours: Int, min: Int) {
        let formatedMonth = String(format: "%02d", month)
        let formatedDay = String(format: "%02d", day)
        date = String(year) + "-" + formatedMonth + "-" + formatedDay
        time = String(format: "%02i:%02i:%02i", hours, min, 00)
    }
    
    /// Initilizes a new TRPTime with string values.
    ///
    /// - Parameters:
    ///   - date: yyyy-mm-dd
    ///   - time: hh:mm
    public init(date: String, time: String) {
        self.date = date
        self.time = time
    }
    //2020-03-14T12:00:00Z
    public init?(dateTime:String) {
        
        let dateSperator = dateTime.split(separator: "T")
        
        if dateSperator.count == 2 {
            let date = dateSperator[0]
            let time = dateSperator[1].replacingOccurrences(of: "Z", with: "")
            
            self.date = "\(date)"
            self.time = "\(time)"
        }else {
            return nil
        }
    }
    
    func dateToString(date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
    
    /// Initilizes a new TRPTime with date
    ///
    /// - Parameter date: Date object will be parsed Date/Time.
    public init(date: Date) {
        var calendar = Calendar.current
        if let timeZone = TimeZone(identifier: "UTC") {
            calendar.timeZone = timeZone
        }
        let year =
            calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let hour = calendar.component(.hour, from: date)
        let min = calendar.component(.minute, from: date)
        
        self.init(year: year, month: month, day: day, hours: hour, min: min)
    }
    
}

extension TRPTime: Equatable{
    //Note: -  saat eklenebilir.
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.toDate == rhs.toDate
    }

}
