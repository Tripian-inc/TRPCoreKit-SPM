//
//  String+Extensions.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 21.05.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation
import UIKit
extension String {
    
    static let defaultDateFormat: String = "yyyy-MM-dd"
    static let fullDateFormat: String = "yyyy-MM-dd'T'HH:mm:ss"
    
    /// String veriyi Date haline dönüştürür.
    ///
    /// - Parameters:
    ///   - date: String halinde date verisi
    ///   - format: Date in oluşturulduğu format
    /// - Returns: Date
    func toDate(format: String = defaultDateFormat, timeZone: String? = "UTC") -> Date? {
        return toDateFormat(format: format, timeZone: timeZone)
    }
    
    func toDateWithoutUTC(format: String = defaultDateFormat) -> Date? {
        return toDateFormat(format: format, timeZone: nil)
    }
    
    private func toDateFormat(format: String, timeZone: String?) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        if let timeZone {
            dateFormatter.timeZone = TimeZone(identifier: timeZone)
        }
        let appLanguage = TRPClient.shared.language
        if appLanguage == "en" {
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        } else {
            dateFormatter.locale = Locale(identifier: appLanguage)
        }
        return dateFormatter.date(from: self)
    }

    func toLocalized() -> String {
        guard let bundle = Bundle(identifier: "com.tripian.TRPCoreKit") else {return self}
        return NSLocalizedString(self, tableName: nil, bundle: bundle, value: "", comment: "")
    }
    
    func readableLanguage(identifier: String = "eng") -> String {
        let converted = Locale(identifier: identifier).localizedString(forLanguageCode: self)
        return converted != nil ? converted! : self
    }
    
    /// Maybe u can write external function for localization that data came from remote server
    ///
    /// - Returns: 
    func toLocalizedFromServer() -> String {
        return self.toLocalized()
    }
    
    //To Make a call
    enum RegularExpressions: String {
        case phone = "^\\s*(?:\\+?(\\d{1,3}))?([-. (]*(\\d{3})[-. )]*)?((\\d{3})[-. ]*(\\d{2,4})(?:[-.x ]*(\\d+))?)\\s*$"
    }
    
    func isValid(regex: RegularExpressions) -> Bool {
        return isValid(regex: regex.rawValue)
    }
    
    func isValid(regex: String) -> Bool {
        let matches = range(of: regex, options: .regularExpression)
        return matches != nil
    }
    
    func onlyDigits() -> String {
        let filtredUnicodeScalars = unicodeScalars.filter{CharacterSet.decimalDigits.contains($0)}
        return String(String.UnicodeScalarView(filtredUnicodeScalars))
    }
    
     func makeACall() {
        if isValid(regex: .phone) {
            if let url = URL(string: "tel://\(self.onlyDigits())"), UIApplication.shared.canOpenURL(url) {
                if #available(iOS 10, *) {
                    UIApplication.shared.open(url)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }
    }
    
    func removeWhiteSpace() -> String {
        self.replacingOccurrences(of: " ", with: "")
    }
}
extension String{
    func encodeUrl() -> String?{
        return self.addingPercentEncoding( withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
    }
    
    func decodeUrl() -> String?{
        return self.removingPercentEncoding
    }
}

extension String {
    func addStyle(_ style: [NSAttributedString.Key:Any]) -> NSMutableAttributedString {
        return NSMutableAttributedString(string: self, attributes: style)
    }
}

extension NSMutableAttributedString {
    func addString(_ text:String, syle: [NSAttributedString.Key:Any])  {
        let newString = NSMutableAttributedString(string: text, attributes: syle)
        self.append(newString)
    }
}

//Credit Card
extension String {
    
    
    //Source: https://stackoverflow.com/questions/57351929/how-can-i-split-credit-card-number-to-4x4x4x4-from-16without-textfield
    //See: https://gist.github.com/cwagdev/e66d4806c1f63fe9387a
    func readableCreditCart() -> String {
        return self.replacingOccurrences(of: "(\\d{4})(\\d+)", with: "$1 $2", options: .regularExpression, range: nil)
    }

    func readableExpireDate() -> String {
        if self.count > 1 && self.count < 4 {
            return self.removeWhiteSpace().replacingOccurrences(of: "(\\d{2})(\\d+)", with: "$1/$2", options: .regularExpression, range: nil)
        }
        return self
    }
    
}

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}

extension String {
    func valueOfURL(_ queryParameterName: String) -> String? {
        guard let url = URLComponents(string: self) else { return nil }
        return url.queryItems?.first(where: { $0.name == queryParameterName })?.value
    }
}
extension URL {
    func valueOf(_ queryParameterName: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == queryParameterName })?.value
    }
}

extension String {
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return nil }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return nil
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}
enum RegEx: String {
    case email = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}" // Email
    case password = "^.{6,40}$" // Password length 1-40
}

extension String {
    
    var isValidEmail: Bool {
        let validatedStr = NSPredicate(format:"SELF MATCHES %@", RegEx.email.rawValue)
        let result = validatedStr.evaluate(with: self)
        return result
    }
    
    
    
}

extension String {
    func isContainsWithoutCase(to string: String) -> Bool {
        return self
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
            .contains(
                string
                    .folding(options: .diacriticInsensitive, locale: .current)
                    .lowercased()
            )
    }
}

extension String? {
    func isNilOrEmpty() -> Bool {
        return self?.isEmpty ?? true
    }
}
