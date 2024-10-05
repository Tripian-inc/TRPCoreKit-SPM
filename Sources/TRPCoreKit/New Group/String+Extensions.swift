//
//  String+Extensions.swift
//  TRPCoreKit
//
//  Created by Evren Yaşar on 21.05.2019.
//  Copyright © 2019 Tripian Inc. All rights reserved.
//

import Foundation
extension String {
    
    /// String veriyi Date haline dönüştürür.
    ///
    /// - Parameters:
    ///   - date: String halinde date verisi
    ///   - format: Date in oluşturulduğu format
    /// - Returns: Date
    func toDate(format: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        return dateFormatter.date(from: self)
    }
    
    func toDateWithoutUTC(format: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        
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
